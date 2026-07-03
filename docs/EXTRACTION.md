# Распаковка пакетов UGREEN `.upk`

## Требования

- Python 3.8+ (только стандартная библиотека: `gzip`, `lzma`, `bz2`, `tarfile`).
- Внешние утилиты не нужны.

## Использование

```bash
python3 tools/upk_extract.py <папка-с-upk> [папка-вывода]
```

- `<папка-с-upk>` — каталог, где лежат файлы `*.upk`.
- `[папка-вывода]` — куда распаковывать (по умолчанию `<папка-с-upk>/packages`).

Пример:

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## Что делает скрипт

Для каждого `*.upk`:

1. **Разбирает внешний контейнер** `UGREEN-PKG-V2-FORMAT` на поля `ключ:длина:значение`
   (см. [FORMAT.md](FORMAT.md)).
2. Берёт полезную нагрузку `ugb` и **рекурсивно снимает слои сжатия** (gzip → xz),
   распаковывая tar-архивы.
3. Обрабатывает оба варианта упаковки:
   - одиночный вложенный `<appId>.ugb`;
   - многофайловый tar со скриптами `install.sh`/`uninstall.sh` + `<appId>.ugb`
     (вложенные `*.ugb` разворачиваются на месте функцией `expand_nested_ugb`).
4. Читает `config.json`, берёт `appId` и `version.version`.
5. Раскладывает результат:

   ```
   packages/<appId>-<version>/
   ├── contents/          # дерево приложения
   ├── icon.png           # иконка (поле ico)
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. **Переименовывает** исходный `*.upk` в `<appId>-<version>.upk`.
7. Пишет сводный `packages/catalog.json` со всеми метаданными.

## Ключевые функции `upk_extract.py`

| Функция | Назначение |
|---|---|
| `parse_upk(path)` | Разбор внешнего контейнера в словарь полей |
| `sniff(data)` | Определение формата по магическим байтам |
| `decompress_layers(data)` | Снятие подряд идущих слоёв gzip/xz/bzip2 |
| `deep_extract(data, dest)` | Рекурсивная распаковка до дерева приложения |
| `expand_nested_ugb(dest)` | Разворот вложенных `*.ugb` внутри дерева |
| `find_config(root)` | Поиск манифеста `config.json` |
| `process(upk, out)` | Полный цикл для одного пакета |

## Замечания

- Разворачиваются только вложенные `*.ugb`; обычные ассеты вроде `index.html.gz`
  и `version.json.gz` внутри `www/` **не** трогаются.
- Скрипт использует `tarfile.extractall(..., filter="data")` — безопасный режим
  извлечения (Python 3.12+), блокирующий пути вне целевой папки.
- Подписи из `_package_meta/` не проверяются — они сохраняются как есть для анализа.
  Проверку целостности выполняет сам UGOS при установке.

## Проверка результата

```bash
# список приложений с версиями
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# дерево одного пакета
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
