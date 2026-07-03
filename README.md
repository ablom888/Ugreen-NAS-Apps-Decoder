# UGREEN NAS Apps Decoder

Инструмент и документация для распаковки установочных пакетов приложений
**UGREEN NAS (UGOS Pro)** — файлов формата `.upk` (`UGREEN-PKG-V2-FORMAT`).

Репозиторий содержит:

- **`tools/upk_extract.py`** — распаковщик пакетов `.upk` без внешних зависимостей
  (только стандартная библиотека Python 3).
- **`tools/upk_pack.py`** — обратный упаковщик: собирает `.upk` из распакованной папки
  (round-trip проверен побайтово; см. [`docs/REPACK.md`](docs/REPACK.md)).
- **`docs/`** — разбор формата контейнера и пошаговое описание распаковки/упаковки.
- **`apps/`** — распакованные приложения UGOS (файлы в пределах лимита GitHub 100 МБ;
  крупные бинарники исключены — их список в [`apps/EXCLUDED.md`](apps/EXCLUDED.md)).
- **`catalog/`** — метаданные 19 официальных приложений UGOS: манифест `config.json`,
  иконка и полный список файлов каждого пакета.

> ⚠️ Всё содержимое приложений — проприетарное ПО UGREEN, опубликовано для целей
> совместимости и анализа. Оригинальные `.upk` (1.2 ГБ) приложены к
> [релизу](../../releases). Отдельные бинарники свыше лимита GitHub в 100 МБ
> в `apps/` не входят — их перечень в [`apps/EXCLUDED.md`](apps/EXCLUDED.md);
> собрать полный набор можно, распаковав `.upk` из релиза инструментом `tools/`.

## Быстрый старт

```bash
# распаковать все .upk из папки в ./packages, назвав папки по <appId>-<version>
python3 tools/upk_extract.py /путь/к/папке/с/upk ./packages

# собрать .upk обратно из распакованной папки
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

Для каждого пакета создаётся:

```
packages/<appId>-<version>/
├── contents/          # дерево приложения (config.json, sbin, www, init.d, ...)
├── icon.png           # иконка приложения
└── _package_meta/     # подписи и публичные ключи из контейнера
```

Сами файлы `.upk` переименовываются в `<appId>-<version>.upk`.

## Каталог приложений

19 официальных приложений UGOS (все — `amd64`, нативные). Полная таблица с версиями,
категориями и описаниями — в [`catalog/catalog.md`](catalog/catalog.md).
Машиночитаемый вариант — [`catalog/catalog.json`](catalog/catalog.json).

| App ID | Приложение | Версия |
|---|---|---|
| `com.ugreen.antivirus` | Security (ClamAV) | 1.16.0.0027 |
| `com.ugreen.cameramgr` | Surveillance Center | 1.0.0.0677 |
| `com.ugreen.comic` | Comics | 1.3.0.0015 |
| `com.ugreen.dlna` | DLNA | 1.14.0.0013 |
| `com.ugreen.docker` | Docker | 1.16.0.0022 |
| `com.ugreen.downloadmgr` | Downloads (qBittorrent/Transmission) | 1.16.0.0024 |
| `com.ugreen.editor` | TextEdit | 1.16.0.0017 |
| `com.ugreen.iscsi` | SAN Manager (iSCSI) | 1.9.0.0025 |
| `com.ugreen.kvm` | Virtual Machine (KVM) | 1.16.0.0020 |
| `com.ugreen.music` | Music | 1.16.0.0007 |
| `com.ugreen.netdisk` | Cloud Drives | 1.16.0.0030 |
| `com.ugreen.note` | Notes | 1.0.0.0070 |
| `com.ugreen.office` | Online Office (ONLYOFFICE) | 1.16.0.0004 |
| `com.ugreen.photo` | Photos (ONNX AI) | 2.1.0.0106 |
| `com.ugreen.snapshot` | Snapshot | 1.10.0.0022 |
| `com.ugreen.syncbackup` | Sync & Backup | 1.16.0.0047 |
| `com.ugreen.vault` | Vault | 1.16.0.0032 |
| `com.ugreen.versionmgr` | File Version Explorer | 1.16.0.0019 |
| `com.ugreen.videomgr` | Theater | 1.16.0.0027 |

## Формат `.upk`

Кратко: текстовый контейнер `UGREEN-PKG-V2-FORMAT` с полями `ключ:длина:значение`,
внутри — иконка, криптоподписи и полезная нагрузка `ugb`
(**gzip → tar → `<appId>.ugb` → xz → tar →** дерево приложения).
Подробный разбор — в [`docs/FORMAT.md`](docs/FORMAT.md).

## Документация

- [`docs/FORMAT.md`](docs/FORMAT.md) — структура контейнера `.upk` побайтово.
- [`docs/EXTRACTION.md`](docs/EXTRACTION.md) — как работает распаковщик и как им пользоваться.

## Лицензия

Код инструмента и документация — [MIT](LICENSE).
Товарные знаки, приложения и их бинарники принадлежат UGREEN. Репозиторий
предназначен для образовательных целей и совместимости (interoperability).
