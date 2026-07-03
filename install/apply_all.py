#!/usr/bin/env python3
"""
apply_all.py — применяет русскую (или любую) локализацию ко ВСЕМ установленным
приложениям UGOS, для которых есть перевод в папке ru-RU/.

Запускается НА NAS. Идемпотентен: приложения, которых нет на устройстве,
пропускаются; повторный запуск просто пересчитывает .check-app.

Структура рядом со скриптом (кладётся установщиком):
  <base>/
  ├── ug_localize.py
  ├── ug_checkapp.py
  ├── apply_all.py            (этот файл)
  └── ru-RU/<appId>/ru-RU.json

Использование:
  python3 apply_all.py [--lang ru-RU] [--no-restart]
"""
import os, sys, json, subprocess

BASE = os.path.dirname(os.path.abspath(__file__))
# ug_localize.py лежит рядом (так кладёт установщик на NAS) либо в
# ../tools/localization (раскладка репозитория)
for _p in (BASE, os.path.join(BASE, "..", "tools", "localization")):
    if os.path.isfile(os.path.join(_p, "ug_localize.py")):
        sys.path.insert(0, os.path.abspath(_p))
        break
import ug_localize  # noqa: E402

def main():
    lang = "ru-RU"
    restart = True
    if "--lang" in sys.argv:
        lang = sys.argv[sys.argv.index("--lang") + 1]
    if "--no-restart" in sys.argv:
        restart = False

    # переводы лежат рядом (BASE/<lang> — так кладёт установщик на NAS) либо
    # в ../localization/<lang> (раскладка репозитория)
    langdir = None
    for cand in (os.path.join(BASE, lang),
                 os.path.join(BASE, "..", "localization", lang)):
        if os.path.isdir(cand):
            langdir = os.path.abspath(cand); break
    if not langdir:
        sys.exit(f"[ошибка] нет папки переводов '{lang}' (искал в {BASE} и ../localization)")

    app_ids = sorted(d for d in os.listdir(langdir)
                     if os.path.isdir(os.path.join(langdir, d)))
    print(f"Локализация '{lang}': найдено переводов — {len(app_ids)}")
    applied = skipped = failed = 0
    for app_id in app_ids:
        src = os.path.join(langdir, app_id, f"{lang}.json")
        if not os.path.isfile(src):
            print(f"  · {app_id}: нет {lang}.json — пропуск"); skipped += 1; continue
        hits = ug_localize.find_app_dirs(app_id)
        if not hits:
            print(f"  · {app_id}: не установлено — пропуск"); skipped += 1; continue
        app_dir = hits[0]
        try:
            ug_localize.cmd_apply(app_dir, lang, src, restart)
            print(f"  ✓ {app_id}: локализовано ({app_dir})")
            applied += 1
        except SystemExit as e:
            print(f"  ✗ {app_id}: ошибка — {e}"); failed += 1
        except Exception as e:
            print(f"  ✗ {app_id}: ошибка — {e}"); failed += 1
    print(f"\nИтог: применено={applied} пропущено={skipped} ошибок={failed}")
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
