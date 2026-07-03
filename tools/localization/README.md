# Инструменты локализации UGOS

Скрипты для добавления своего языка в приложения UGREEN NAS **без переупаковки и
переподписи** — правкой уже установленного приложения (см.
[`../../docs/LOCALIZATION.md`](../../docs/LOCALIZATION.md) и
[`../../docs/SIGNING.md`](../../docs/SIGNING.md)).

Только Python 3, без зависимостей. Оба файла должны лежать рядом.

| Скрипт | Назначение |
|---|---|
| `ug_localize.py` | `find` / `list` / `scaffold` / `apply` — весь цикл локализации |
| `ug_checkapp.py` | `verify` / `refresh` — проверка и пересчёт манифеста `.check-app` |

```bash
python3 ug_localize.py find     com.ugreen.cameramgr
python3 ug_localize.py scaffold com.ugreen.cameramgr ru-RU --from en-US
# ... отредактировать www/locale/ru-RU.json ...
python3 ug_localize.py apply    com.ugreen.cameramgr ru-RU <app_dir>/www/locale/ru-RU.json --restart
python3 ug_checkapp.py verify   <app_dir>
```
