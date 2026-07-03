# Reverse packing into the UGREEN `.upk` format

**🌐 Language:** **English** · [中文](../zh/REPACK.md) · [हिन्दी](../hi/REPACK.md) · [Español](../es/REPACK.md) · [Français](../fr/REPACK.md) · [Русский](../REPACK.md)

`tools/upk_pack.py` builds a `.upk` package (UGREEN-PKG-V2-FORMAT) back from a folder
created by `upk_extract.py`.

## Usage

```bash
python3 tools/upk_pack.py <package-folder> [output.upk]
```

- `<package-folder>` — a folder of the form `<appId>-<version>/` with a `contents/` subfolder inside
  (and, preferably, `icon.png` + `_package_meta/`).
- `[output.upk]` — the result path (default `<folder>.repacked.upk` alongside).

Example:

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## How the container is assembled

The layers are built in the reverse order of unpacking (see [FORMAT.md](FORMAT.md)):

```
inner  = xz( tar(GNU)  [ contents/ without install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + key:len:value fields
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- The inner archive is GNU tar, compressed with xz (CHECK_CRC64, preset 9|EXTREME).
- The outer payload is tar, compressed with gzip (level 9).
- The container fields are written in a fixed order; `ico` is taken from `icon.png`,
  and the signatures/keys/`obj2` from `_package_meta/`.

## Round-trip verification

Packing → unpacking fully preserves the application tree:

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # no differences
```

Verified: `config.json`, the file list, and the **byte-for-byte content of all files**
in the tree match the original.

## Limitation: signatures

The `filesig` / `usersig` / `midsig` fields are RSA signatures by the vendor, created with its
**private** keys, which are not in the package. Therefore it is impossible to regenerate a
valid signature. `upk_pack.py` **reuses** the saved signatures, public keys, and
`obj2` from `_package_meta/`.

Consequence: upon recompressing the payload, its hash and signature no longer match the
content, so such a package **is not guaranteed to pass the UGOS integrity check
during installation**. The tool is intended for researching the format, modifying,
and reassembling the tree, not for bypassing the signature check.
