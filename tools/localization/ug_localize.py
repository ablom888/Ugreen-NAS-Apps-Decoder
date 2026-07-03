#!/usr/bin/env python3
"""
ug_localize.py — добавление/замена локализации в установленном приложении UGOS
БЕЗ переупаковки и переподписи пакета.

Работает прямо на NAS (нужен root/admin). Правит файлы уже установленного
приложения и обновляет манифест целостности `.check-app`, поэтому проверка
подписи (которая выполняется только при установке) не задействуется.

Локализация приложения UGOS хранится в:
  www/locale/<lang>.json        тексты веб-интерфейса (+ .gz — сжатая копия для nginx)
  i18n/msg.csv                  серверные строки (опционально)
  config.json -> languageList   список поддерживаемых языков

Подкоманды:
  find    <appId>                        найти папку установленного приложения
  list    <app_dir|appId>                показать доступные локали и languageList
  scaffold <app_dir|appId> <lang> [--from <base>]
                                         создать www/locale/<lang>.json из базовой
                                         локали (по умолчанию en-US) как заготовку
  apply   <app_dir|appId> <lang> <file.json> [--restart]
                                         установить перевод <file.json> как
                                         www/locale/<lang>.json (+ .gz), добавить
                                         <lang> в languageList, обновить .check-app

<lang> — полный код локали в стиле UGOS, напр. ru-RU, en-US, de-DE.

Зависимостей нет (только стандартная библиотека Python 3).
Рядом должен лежать ug_checkapp.py.
"""
import sys, os, json, gzip, shutil, subprocess, glob

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ug_checkapp  # noqa: E402

# где UGOS обычно держит установленные приложения (best-effort автопоиск)
SEARCH_ROOTS = ["/volume*/", "/volume*/.*/", "/mnt/*/", "/var/lib/ugreen/*/",
                "/usr/ugreen/*/", "/opt/ugreen/*/"]

def resolve_app_dir(arg):
    """Принимает путь или appId; возвращает папку с config.json."""
    if os.path.isdir(arg) and os.path.isfile(os.path.join(arg, "config.json")):
        return os.path.abspath(arg)
    if os.path.isdir(arg) and os.path.isfile(os.path.join(arg, "contents", "config.json")):
        return os.path.abspath(os.path.join(arg, "contents"))
    # трактуем как appId — ищем
    hits = find_app_dirs(arg)
    if not hits:
        sys.exit(f"[ошибка] не удалось найти установленное приложение '{arg}'.\n"
                 f"Укажите путь к папке с config.json явно.")
    if len(hits) > 1:
        print("[!] найдено несколько; берём первое:")
        for h in hits: print("   ", h)
    return hits[0]

def find_app_dirs(app_id):
    hits = []
    seen = set()
    for pat in SEARCH_ROOTS:
        for base in glob.glob(pat):
            for cfg in glob.glob(os.path.join(base, "**", "config.json"), recursive=True):
                d = os.path.dirname(cfg)
                if d in seen:
                    continue
                seen.add(d)
                try:
                    j = json.load(open(cfg, encoding="utf-8"))
                except Exception:
                    continue
                if j.get("appId") == app_id:
                    hits.append(d)
    return hits

def load_cfg(app_dir):
    return json.load(open(os.path.join(app_dir, "config.json"), encoding="utf-8"))

def write_gz(src_json, dst_gz):
    with open(src_json, "rb") as f:
        data = f.read()
    with gzip.open(dst_gz, "wb", compresslevel=9) as g:
        g.write(data)

def cmd_find(app_id):
    hits = find_app_dirs(app_id)
    if not hits:
        print("не найдено"); return 1
    for h in hits:
        print(h)
    return 0

def cmd_list(arg):
    app_dir = resolve_app_dir(arg)
    cfg = load_cfg(app_dir)
    print(f"appId:        {cfg.get('appId')}")
    print(f"languageList: {cfg.get('languageList')}")
    loc = os.path.join(app_dir, "www", "locale")
    if os.path.isdir(loc):
        jsons = sorted(f for f in os.listdir(loc) if f.endswith(".json"))
        print(f"www/locale:   {[f[:-5] for f in jsons]}")
    print(f"app_dir:      {app_dir}")
    return 0

def cmd_scaffold(arg, lang, base):
    app_dir = resolve_app_dir(arg)
    loc = os.path.join(app_dir, "www", "locale")
    src = os.path.join(loc, f"{base}.json")
    if not os.path.isfile(src):
        sys.exit(f"[ошибка] базовая локаль не найдена: {src}")
    dst = os.path.join(loc, f"{lang}.json")
    if os.path.exists(dst):
        sys.exit(f"[ошибка] уже существует: {dst} (удалите или выберите другой код)")
    shutil.copy(src, dst)
    print(f"Создана заготовка: {dst}")
    print(f"Отредактируйте значения (ключи оставьте), затем примените:")
    print(f"  python3 ug_localize.py apply {app_dir} {lang} {dst} --restart")
    return 0

def cmd_apply(arg, lang, src_file, restart):
    app_dir = resolve_app_dir(arg)
    if not os.path.isfile(src_file):
        sys.exit(f"[ошибка] нет файла перевода: {src_file}")
    # валидируем JSON
    try:
        json.load(open(src_file, encoding="utf-8"))
    except Exception as e:
        sys.exit(f"[ошибка] {src_file} — не валидный JSON: {e}")

    loc = os.path.join(app_dir, "www", "locale")
    os.makedirs(loc, exist_ok=True)
    dst_json = os.path.join(loc, f"{lang}.json")
    dst_gz = dst_json + ".gz"

    in_place = os.path.abspath(src_file) == os.path.abspath(dst_json)
    if in_place:
        # пользователь редактировал заготовку прямо в www/locale/<lang>.json —
        # копировать не нужно, просто финализируем (.gz, config, .check-app)
        print(f"финализация уже отредактированного: {dst_json}")
    else:
        if os.path.exists(dst_json):
            shutil.copy(dst_json, dst_json + ".bak")
            print(f"бэкап: {dst_json}.bak")
        shutil.copy(src_file, dst_json)
    write_gz(dst_json, dst_gz)
    print(f"записано: {dst_json}")
    print(f"записано: {dst_gz}")

    # config.json -> languageList
    cfg_path = os.path.join(app_dir, "config.json")
    cfg = json.load(open(cfg_path, encoding="utf-8"))
    langs = cfg.get("languageList") or []
    changed = False
    if lang not in langs:
        langs.append(lang)
        cfg["languageList"] = langs
        json.dump(cfg, open(cfg_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        changed = True
        print(f"languageList += {lang}")

    # обновить манифест целостности .check-app:
    # refresh пересчитывает md5 всех существующих ключей (в т.ч. изменённого
    # config.json) и добавляет новые файлы локали.
    ug_checkapp.cmd_refresh(app_dir, [dst_json, dst_gz])
    print("[+] .check-app обновлён")

    svc = cfg.get("serviceName")
    if restart and svc:
        print(f"перезапуск сервиса: {svc}")
        r = subprocess.run(["systemctl", "restart", svc])
        print("ok" if r.returncode == 0 else f"[!] systemctl вернул {r.returncode}")
    elif svc:
        print(f"Чтобы применить: sudo systemctl restart {svc}")
    return 0

def main():
    a = sys.argv
    if len(a) < 2:
        print(__doc__); sys.exit(1)
    cmd = a[1]
    if cmd == "find" and len(a) >= 3:
        sys.exit(cmd_find(a[2]))
    if cmd == "list" and len(a) >= 3:
        sys.exit(cmd_list(a[2]))
    if cmd == "scaffold" and len(a) >= 4:
        base = "en-US"
        if "--from" in a:
            base = a[a.index("--from") + 1]
        sys.exit(cmd_scaffold(a[2], a[3], base))
    if cmd == "apply" and len(a) >= 5:
        sys.exit(cmd_apply(a[2], a[3], a[4], "--restart" in a))
    print(__doc__); sys.exit(1)

if __name__ == "__main__":
    main()
