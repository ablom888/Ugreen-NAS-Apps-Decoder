#!/usr/bin/env python3
"""
UGREEN NAS Apps Decoder
Распаковщик пакетов UGREEN NAS (.upk, формат UGREEN-PKG-V2).

Структура .upk:
  [magic "UGREEN-PKG-V2-FORMAT"]  затем поля вида  key:len:value  подряд:
    filesig / usersig / midsig  — подписи (base64)
    userpub  / midpub           — публичные ключи RSA (base64, PEM-тело)
    ico                         — иконка PNG (сырые байты)
    ugb                         — полезная нагрузка: gzip -> tar -> <appId>.ugb
                                  где <appId>.ugb = xz -> tar -> дерево приложения
    obj2                        — манифест хешей файлов (hex)

Скрипт снимает все слои сжатия рекурсивно и раскладывает дерево приложения
в отдельную папку, имя которой = <appId>-<version> из config.json.
"""
import os, re, sys, io, json, gzip, lzma, bz2, tarfile, shutil

MAGIC = b"UGREEN-PKG-V2-FORMAT"

def sniff(data: bytes):
    if data[:2] == b"\x1f\x8b": return "gzip"
    if data[:6] == b"\xfd7zXZ\x00": return "xz"
    if data[:3] == b"BZh": return "bzip2"
    if len(data) > 262 and data[257:262] == b"ustar": return "tar"
    return None

def decompress_layers(data: bytes) -> bytes:
    """Снимает подряд идущие слои gzip/xz/bzip2, пока не упрёмся в tar/сырьё."""
    while True:
        t = sniff(data)
        if t == "gzip":   data = gzip.decompress(data)
        elif t == "xz":   data = lzma.decompress(data)
        elif t == "bzip2":data = bz2.decompress(data)
        else:             return data

def looks_like_archive(data: bytes) -> bool:
    return sniff(data) in ("gzip", "xz", "bzip2", "tar")

def expand_nested_ugb(dest: str):
    """Разворачивает вложенные бандлы UGREEN (*.ugb) внутри дерева на месте.
    Затрагивает только *.ugb — обычные ассеты (index.html.gz и т.п.) не трогаем."""
    changed = True
    while changed:
        changed = False
        for root, _, fns in os.walk(dest):
            for fn in fns:
                if not fn.endswith(".ugb"):
                    continue
                p = os.path.join(root, fn)
                with open(p, "rb") as f:
                    d = decompress_layers(f.read())
                if sniff(d) == "tar":
                    tarfile.open(fileobj=io.BytesIO(d)).extractall(root, filter="data")
                    os.remove(p)
                    changed = True

def deep_extract(data: bytes, dest: str) -> str:
    """Рекурсивно распаковывает архив в dest. Возвращает dest.
    Если tar содержит единственный вложенный архив — рекурсивно уходит внутрь."""
    data = decompress_layers(data)
    if sniff(data) != "tar":
        # не архив — записываем как файл payload.bin
        os.makedirs(dest, exist_ok=True)
        with open(os.path.join(dest, "payload.bin"), "wb") as f:
            f.write(data)
        return dest
    tf = tarfile.open(fileobj=io.BytesIO(data))
    files = [m for m in tf.getmembers() if m.isfile()]
    if len(files) == 1:
        inner = tf.extractfile(files[0]).read()
        if looks_like_archive(inner):
            return deep_extract(inner, dest)
    os.makedirs(dest, exist_ok=True)
    tf.extractall(dest, filter="data")
    expand_nested_ugb(dest)  # многофайловый tar: install.sh + <appId>.ugb
    return dest

def parse_upk(path: str):
    """Разбирает внешний контейнер UPK -> dict{field: bytes}."""
    data = open(path, "rb").read()
    if not data.startswith(MAGIC):
        raise ValueError(f"не UGREEN-PKG-V2: {path}")
    pos = len(MAGIC)
    fields = {}
    while pos < len(data):
        m = re.match(rb"([a-z0-9]+):(\d+):", data[pos:pos+40])
        if not m:
            break
        key = m.group(1).decode()
        ln = int(m.group(2))
        start = pos + m.end()
        fields[key] = data[start:start+ln]
        pos = start + ln
    return fields

def find_config(root: str):
    """Ищет config.json (манифест) в распакованном дереве."""
    # приоритет — корень
    cand = os.path.join(root, "config.json")
    if os.path.isfile(cand):
        return cand
    for dp, _, fns in os.walk(root):
        if "config.json" in fns:
            return os.path.join(dp, "config.json")
    return None

def safe(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]", "_", s)

def process(upk_path: str, out_base: str):
    fields = parse_upk(upk_path)
    payload = fields.get("ugb") or fields.get("payload")
    if payload is None:
        raise ValueError(f"нет поля полезной нагрузки в {upk_path}")

    tmp = os.path.join(out_base, "_tmp_" + os.path.basename(upk_path))
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    deep_extract(payload, tmp)

    cfg_path = find_config(tmp)
    app_id = ver = None
    meta = {}
    if cfg_path:
        try:
            cfg = json.load(open(cfg_path, encoding="utf-8"))
            app_id = cfg.get("appId")
            v = cfg.get("version") or {}
            ver = v.get("version") if isinstance(v, dict) else str(v)
            meta = cfg
        except Exception as e:
            print(f"  [!] config.json не разобран: {e}")

    if not app_id:
        app_id = os.path.splitext(os.path.basename(upk_path))[0]
    if not ver:
        ver = "unknown"
    name = safe(f"{app_id}-{ver}")

    final = os.path.join(out_base, name)
    if os.path.exists(final):
        shutil.rmtree(tmp)
        return name, meta, True  # дубликат
    # содержимое дерева -> в папку contents/, иконку и подписи рядом
    contents = os.path.join(final, "contents")
    shutil.move(tmp, contents)
    if "ico" in fields:
        with open(os.path.join(final, "icon.png"), "wb") as f:
            f.write(fields["ico"])
    # метаданные контейнера (подписи/ключи) — в _package_meta/
    pm = os.path.join(final, "_package_meta")
    os.makedirs(pm, exist_ok=True)
    for k in ("filesig", "usersig", "midsig", "userpub", "midpub", "obj2"):
        if k in fields:
            with open(os.path.join(pm, k + ".txt"), "wb") as f:
                f.write(fields[k])
    return name, meta, False

def main():
    src_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    out_base = sys.argv[2] if len(sys.argv) > 2 else os.path.join(src_dir, "packages")
    os.makedirs(out_base, exist_ok=True)
    catalog = []
    upks = sorted(p for p in os.listdir(src_dir) if p.lower().endswith(".upk"))
    for i, fn in enumerate(upks, 1):
        path = os.path.join(src_dir, fn)
        print(f"[{i}/{len(upks)}] {fn}")
        try:
            name, meta, dup = process(path, out_base)
            print(f"    -> {name}" + ("  (дубликат, пропущен)" if dup else ""))
            # переименовать сам .upk
            new_upk = os.path.join(src_dir, name + ".upk")
            if os.path.abspath(new_upk) != os.path.abspath(path):
                if os.path.exists(new_upk):
                    os.remove(path)
                else:
                    os.rename(path, new_upk)
            catalog.append({"source": fn, "name": name, "duplicate": dup,
                            "appId": meta.get("appId"),
                            "version": (meta.get("version") or {}).get("version") if isinstance(meta.get("version"), dict) else None,
                            "meta": meta})
        except Exception as e:
            print(f"    [ОШИБКА] {e}")
            catalog.append({"source": fn, "error": str(e)})
    with open(os.path.join(out_base, "catalog.json"), "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    print(f"\nКаталог: {os.path.join(out_base, 'catalog.json')}")

if __name__ == "__main__":
    main()
