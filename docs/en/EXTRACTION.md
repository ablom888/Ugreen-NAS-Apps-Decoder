# Unpacking UGREEN `.upk` packages

**🌐 Language:** **English** · [中文](../zh/EXTRACTION.md) · [हिन्दी](../hi/EXTRACTION.md) · [Español](../es/EXTRACTION.md) · [Français](../fr/EXTRACTION.md) · [Русский](../EXTRACTION.md)

## Requirements

- Python 3.8+ (standard library only: `gzip`, `lzma`, `bz2`, `tarfile`).
- No external utilities needed.

## Usage

```bash
python3 tools/upk_extract.py <upk-folder> [output-folder]
```

- `<upk-folder>` — the directory where the `*.upk` files reside.
- `[output-folder]` — where to unpack (default `<upk-folder>/packages`).

Example:

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## What the script does

For each `*.upk`:

1. **Parses the outer container** `UGREEN-PKG-V2-FORMAT` into `key:length:value` fields
   (see [FORMAT.md](FORMAT.md)).
2. Takes the `ugb` payload and **recursively strips the compression layers** (gzip → xz),
   unpacking the tar archives.
3. Handles both packaging variants:
   - a single nested `<appId>.ugb`;
   - a multi-file tar with `install.sh`/`uninstall.sh` scripts + `<appId>.ugb`
     (nested `*.ugb` are expanded in place by the `expand_nested_ugb` function).
4. Reads `config.json`, takes `appId` and `version.version`.
5. Lays out the result:

   ```
   packages/<appId>-<version>/
   ├── contents/          # application tree
   ├── icon.png           # icon (ico field)
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. **Renames** the source `*.upk` to `<appId>-<version>.upk`.
7. Writes a consolidated `packages/catalog.json` with all metadata.

## Key functions of `upk_extract.py`

| Function | Purpose |
|---|---|
| `parse_upk(path)` | Parse the outer container into a dictionary of fields |
| `sniff(data)` | Detect the format by magic bytes |
| `decompress_layers(data)` | Strip consecutive gzip/xz/bzip2 layers |
| `deep_extract(data, dest)` | Recursively unpack down to the application tree |
| `expand_nested_ugb(dest)` | Expand nested `*.ugb` inside the tree |
| `find_config(root)` | Find the `config.json` manifest |
| `process(upk, out)` | Full cycle for a single package |

## Notes

- Only nested `*.ugb` are expanded; ordinary assets such as `index.html.gz`
  and `version.json.gz` inside `www/` are **not** touched.
- The script uses `tarfile.extractall(..., filter="data")` — a safe extraction
  mode (Python 3.12+) that blocks paths outside the target folder.
- Signatures from `_package_meta/` are not verified — they are saved as-is for analysis.
  Integrity checking is performed by UGOS itself during installation.

## Verifying the result

```bash
# list of applications with versions
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# tree of a single package
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
