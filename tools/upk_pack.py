#!/usr/bin/env python3
"""
UGREEN NAS Apps Decoder — обратная упаковка (repacker)
Собирает пакет .upk (UGREEN-PKG-V2-FORMAT) из распакованной папки,
созданной upk_extract.py.

Ожидаемая структура входа:
  <pkg>/
  ├── contents/          дерево приложения (config.json, sbin, www, ...)
  ├── icon.png           иконка (поле ico); опционально
  └── _package_meta/     filesig, usersig, midsig, userpub, midpub, obj2 (опц.)

Слои сборки (обратные распаковке):
  inner  = xz( tar(GNU) [ contents без install.sh/uninstall.sh ] )  -> <appId>.ugb
  ugb    = gzip( tar [ install.sh?, uninstall.sh?, <appId>.ugb ] )
  .upk   = "UGREEN-PKG-V2-FORMAT" + поля key:len:value
           (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)

ВАЖНО про подписи:
  filesig/usersig/midsig — RSA-подписи вендора. Приватных ключей у нас нет,
  поэтому валидную подпись заново создать НЕЛЬЗЯ. Скрипт переиспользует
  подписи/ключи/obj2 из _package_meta/ (если есть), сохраняя структуру и
  байтовую форму контейнера. Такой пакет пригоден для анализа и повторной
  распаковки, но НЕ обязан пройти проверку целостности при установке в UGOS
  (payload пересжат — его хеш/подпись изменятся).
"""
import os, sys, io, json, gzip, lzma, tarfile

MAGIC = b"UGREEN-PKG-V2-FORMAT"
# порядок полей во внешнем контейнере
FIELD_ORDER = ["filesig", "userpub", "usersig", "midpub", "midsig", "ico", "ugb", "obj2"]
# скрипты, которые лежат во ВНЕШНЕМ tar рядом с <appId>.ugb (вариант B)
OUTER_SCRIPTS = ("install.sh", "uninstall.sh")

def read_config(contents_dir):
    cfg_path = os.path.join(contents_dir, "config.json")
    if not os.path.isfile(cfg_path):
        raise FileNotFoundError("не найден contents/config.json")
    cfg = json.load(open(cfg_path, encoding="utf-8"))
    app_id = cfg.get("appId") or "unknown.app"
    return app_id

def add_dir_to_tar(tf, src_dir, skip_top=()):
    """Кладёт содержимое src_dir в tar с путями относительно src_dir.
    skip_top — имена файлов верхнего уровня, которые не включать."""
    for name in sorted(os.listdir(src_dir)):
        if name in skip_top:
            continue
        full = os.path.join(src_dir, name)
        tf.add(full, arcname=name, recursive=True)

def build_inner_ugb(contents_dir):
    """xz( tar(GNU) contents кроме install/uninstall )."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.GNU_FORMAT) as tf:
        add_dir_to_tar(tf, contents_dir, skip_top=OUTER_SCRIPTS)
    tar_bytes = buf.getvalue()
    return lzma.compress(tar_bytes, format=lzma.FORMAT_XZ,
                         check=lzma.CHECK_CRC64, preset=9 | lzma.PRESET_EXTREME)

def build_ugb_payload(contents_dir, app_id):
    """gzip( tar [ install.sh?, uninstall.sh?, <appId>.ugb ] )."""
    inner = build_inner_ugb(contents_dir)
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w") as tf:
        for s in OUTER_SCRIPTS:
            p = os.path.join(contents_dir, s)
            if os.path.isfile(p):
                tf.add(p, arcname=s)
        info = tarfile.TarInfo(name=f"{app_id}.ugb")
        info.size = len(inner)
        info.mode = 0o644
        tf.addfile(info, io.BytesIO(inner))
    return gzip.compress(buf.getvalue(), compresslevel=9)

def load_meta(pkg_dir):
    """Читает переиспользуемые поля из _package_meta/ и icon.png."""
    fields = {}
    meta = os.path.join(pkg_dir, "_package_meta")
    for k in ("filesig", "userpub", "usersig", "midpub", "midsig", "obj2"):
        p = os.path.join(meta, k + ".txt")
        if os.path.isfile(p):
            fields[k] = open(p, "rb").read()
    ico = os.path.join(pkg_dir, "icon.png")
    if os.path.isfile(ico):
        fields["ico"] = open(ico, "rb").read()
    return fields

def write_upk(fields, out_path):
    """Сериализует контейнер: MAGIC + key:len:value в фиксированном порядке."""
    out = bytearray(MAGIC)
    for k in FIELD_ORDER:
        v = fields.get(k)
        if v is None:
            continue
        out += f"{k}:{len(v)}:".encode()
        out += v
    with open(out_path, "wb") as f:
        f.write(out)
    return len(out)

def pack(pkg_dir, out_path=None):
    contents = os.path.join(pkg_dir, "contents")
    if not os.path.isdir(contents):
        raise NotADirectoryError(f"нет папки contents/ в {pkg_dir}")
    app_id = read_config(contents)
    fields = load_meta(pkg_dir)
    fields["ugb"] = build_ugb_payload(contents, app_id)
    missing = [k for k in ("filesig", "userpub", "usersig", "midpub", "midsig")
               if k not in fields]
    if missing:
        print(f"  [!] нет полей {missing} (_package_meta отсутствует) — "
              f"контейнер без подписей")
    if out_path is None:
        out_path = os.path.join(os.path.dirname(pkg_dir.rstrip("/")) or ".",
                                os.path.basename(pkg_dir.rstrip("/")) + ".repacked.upk")
    size = write_upk(fields, out_path)
    return out_path, size

def main():
    if len(sys.argv) < 2:
        print("использование: upk_pack.py <папка-пакета> [выход.upk]")
        print("  <папка-пакета> — папка вида <appId>-<version>/ с contents/ внутри")
        sys.exit(1)
    pkg_dir = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else None
    out_path, size = pack(pkg_dir, out)
    print(f"собрано: {out_path}  ({size/1048576:.1f} МБ)")

if __name__ == "__main__":
    main()
