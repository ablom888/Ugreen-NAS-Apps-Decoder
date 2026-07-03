# UGREEN NAS Apps Decoder

**🌐 Язык:** [English](README.en.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [Français](README.fr.md) · **Русский**

Инструмент и документация для распаковки установочных пакетов приложений
**UGREEN NAS (UGOS Pro)** — файлов формата `.upk` (`UGREEN-PKG-V2-FORMAT`).

📦 **Оригинальные пакеты `.upk` — в разделе [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).**

Репозиторий содержит:

- **`tools/upk_extract.py`** — распаковщик пакетов `.upk` без внешних зависимостей
  (только стандартная библиотека Python 3).
- **`tools/upk_pack.py`** — обратный упаковщик: собирает `.upk` из распакованной папки
  (round-trip проверен побайтово; см. [`docs/REPACK.md`](docs/REPACK.md)).
- **`tools/localization/`** — скрипты для своей локализации приложений на NAS без
  переподписи (`ug_localize.py`, `ug_checkapp.py`; см. [`docs/LOCALIZATION.md`](docs/LOCALIZATION.md)).
- **`docs/`** — формат контейнера, распаковка/упаковка, разбор проверки подписи, локализация.
- **`apps/`** — распакованные приложения UGOS (файлы в пределах лимита GitHub 100 МБ;
  крупные бинарники исключены — их список в [`apps/EXCLUDED.md`](apps/EXCLUDED.md)).
- **`catalog/`** — метаданные 19 официальных приложений UGOS: манифест `config.json`,
  иконка и полный список файлов каждого пакета.

> ⚠️ Всё содержимое приложений — проприетарное ПО UGREEN, опубликовано для целей
> совместимости и анализа. Оригинальные `.upk` (1.2 ГБ) приложены к
> [релизу `packages-v1`](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).
> Отдельные бинарники свыше лимита GitHub в 100 МБ
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

## Русская локализация на NAS в одну команду

Готовые русские переводы всех 19 приложений — в [`localization/ru-RU/`](localization/ru-RU)
(≈7300 строк). Установщик [`install/ugreen-localize-installer.sh`](install/ugreen-localize-installer.sh)
спрашивает адрес и логин/пароль SSH, копирует переводы на NAS, локализует все
установленные приложения и ставит systemd-таймер, который возвращает локализацию
после обновлений. Переподписи пакетов не требуется.

```bash
# из корня репозитория
./install/ugreen-localize-installer.sh -H 192.168.1.50 -u admin
```

Подробнее — [`install/README.md`](install/README.md). Как это устроено и почему
безопасно — [`docs/SIGNING.md`](docs/SIGNING.md), [`docs/LOCALIZATION.md`](docs/LOCALIZATION.md).

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

## Releases (загрузки)

Оригинальные установочные пакеты приложений выложены как ассеты релиза:

- **Страница релизов:** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **Релиз `packages-v1`** (19 файлов `.upk`, ~1.2 ГБ): <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

Скачать все пакеты через GitHub CLI:

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## Документация

- [`docs/FORMAT.md`](docs/FORMAT.md) — структура контейнера `.upk` побайтово.
- [`docs/EXTRACTION.md`](docs/EXTRACTION.md) — как работает распаковщик и как им пользоваться.
- [`docs/REPACK.md`](docs/REPACK.md) — обратная упаковка в формат `.upk`.
- [`docs/SIGNING.md`](docs/SIGNING.md) — как UGOS проверяет подпись и можно ли подписывать самим.
- [`docs/LOCALIZATION.md`](docs/LOCALIZATION.md) — своя локализация приложений на NAS без переподписи.

## Лицензия

Код инструмента и документация — [MIT](LICENSE).
Товарные знаки, приложения и их бинарники принадлежат UGREEN. Репозиторий
предназначен для образовательных целей и совместимости (interoperability).
