#!/usr/bin/env python3
"""
ug_checkapp.py — работа с манифестом целостности UGOS `.check-app`.

`.check-app` — плоский JSON `относительный/путь -> md5-hex` для файлов
установленного приложения. UGOS использует его в режиме `reconcile`
(проверка пропавших/повреждённых файлов). Изменяемые конфиги (папка `config/`)
в манифест НЕ входят — это учитывается: при обновлении мы не добавляем новые
ключи вне папок локализации и не трогаем то, чего в манифесте не было.

Подкоманды:
  verify  <app_dir>              проверить md5 всех записей манифеста
  refresh <app_dir> [пути...]    пересчитать md5 для уже существующих ключей;
                                 указанные пути (новые файлы локализации)
                                 добавляются в манифест

app_dir — корень установленного приложения (там, где лежит config.json и .check-app).

Зависимостей нет (только стандартная библиотека Python 3).
"""
import sys, os, json, hashlib

MANIFEST = ".check-app"
# папки, файлы из которых допустимо ДОБАВЛЯТЬ в манифест (локализация)
LOCALE_DIRS = ("www/locale", "i18n")

def md5_file(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()

def load_manifest(app_dir):
    p = os.path.join(app_dir, MANIFEST)
    if not os.path.isfile(p):
        sys.exit(f"[ошибка] не найден {MANIFEST} в {app_dir}")
    return p, json.load(open(p, encoding="utf-8"))

def cmd_verify(app_dir):
    _, chk = load_manifest(app_dir)
    missing = mismatch = ok = 0
    for rel, want in chk.items():
        fp = os.path.join(app_dir, rel)
        if not os.path.isfile(fp):
            print(f"  ПРОПАЛ:      {rel}"); missing += 1; continue
        if md5_file(fp) != want:
            print(f"  РАСХОЖДЕНИЕ: {rel}"); mismatch += 1; continue
        ok += 1
    print(f"\nИтог: ok={ok}  пропало={missing}  расхождений={mismatch}  всего={len(chk)}")
    return 0 if (missing == 0 and mismatch == 0) else 1

def _norm(app_dir, path):
    """Приводит путь к относительному ключу манифеста (без ведущего ./)."""
    ap = os.path.abspath(path)
    rel = os.path.relpath(ap, os.path.abspath(app_dir))
    return rel.replace(os.sep, "/")

def cmd_refresh(app_dir, add_paths):
    mpath, chk = load_manifest(app_dir)
    updated = 0
    # 1) пересчитать md5 для уже существующих ключей (изменённые файлы)
    for rel in list(chk.keys()):
        fp = os.path.join(app_dir, rel)
        if os.path.isfile(fp):
            new = md5_file(fp)
            if new != chk[rel]:
                chk[rel] = new; updated += 1
    # 2) добавить новые файлы локализации
    added = 0
    for path in add_paths:
        rel = _norm(app_dir, path)
        if not os.path.isfile(os.path.join(app_dir, rel)):
            print(f"  [!] пропущен (нет файла): {rel}"); continue
        if not rel.startswith(LOCALE_DIRS):
            print(f"  [!] пропущен (вне папок локализации {LOCALE_DIRS}): {rel}"); continue
        chk[rel] = md5_file(os.path.join(app_dir, rel))
        added += 1
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(chk, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Манифест обновлён: изменено={updated} добавлено={added} записей={len(chk)}")
    return 0

def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    cmd, app_dir = sys.argv[1], sys.argv[2]
    if cmd == "verify":
        sys.exit(cmd_verify(app_dir))
    elif cmd == "refresh":
        sys.exit(cmd_refresh(app_dir, sys.argv[3:]))
    else:
        sys.exit(f"неизвестная подкоманда: {cmd}")

if __name__ == "__main__":
    main()
