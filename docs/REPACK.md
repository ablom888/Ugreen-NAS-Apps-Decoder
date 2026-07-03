# Обратная упаковка в формат UGREEN `.upk`

**🌐 Язык:** [English](en/REPACK.md) · [中文](zh/REPACK.md) · [हिन्दी](hi/REPACK.md) · [Español](es/REPACK.md) · [Français](fr/REPACK.md) · **Русский**

`tools/upk_pack.py` собирает пакет `.upk` (UGREEN-PKG-V2-FORMAT) обратно из папки,
которую создал `upk_extract.py`.

## Использование

```bash
python3 tools/upk_pack.py <папка-пакета> [выход.upk]
```

- `<папка-пакета>` — папка вида `<appId>-<version>/` с подпапкой `contents/` внутри
  (и, желательно, `icon.png` + `_package_meta/`).
- `[выход.upk]` — путь результата (по умолчанию `<папка>.repacked.upk` рядом).

Пример:

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## Как собирается контейнер

Слои строятся в порядке, обратном распаковке (см. [FORMAT.md](FORMAT.md)):

```
inner  = xz( tar(GNU)  [ contents/ без install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + поля key:len:value
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- Внутренний архив — GNU tar, сжатый xz (CHECK_CRC64, preset 9|EXTREME).
- Внешний payload — tar, сжатый gzip (уровень 9).
- Поля контейнера пишутся в фиксированном порядке; `ico` берётся из `icon.png`,
  подписи/ключи/`obj2` — из `_package_meta/`.

## Проверка round-trip

Упаковка → распаковка полностью сохраняет дерево приложения:

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # различий нет
```

Проверено: `config.json`, список файлов и **побайтовое содержимое всех файлов**
дерева совпадают с оригиналом.

## Ограничение: подписи

Поля `filesig` / `usersig` / `midsig` — это RSA-подписи вендора, созданные его
**приватными** ключами, которых в пакете нет. Поэтому валидную подпись пересобрать
невозможно. `upk_pack.py` **переиспользует** сохранённые подписи, публичные ключи и
`obj2` из `_package_meta/`.

Следствие: при пересжатии payload его хеш и подпись перестают соответствовать
содержимому, поэтому такой пакет **не гарантированно проходит проверку целостности
UGOS при установке**. Инструмент предназначен для исследования формата, модификации
и повторной сборки дерева, а не для обхода проверки подписи.
