# UGREEN NAS Apps Decoder

**🌐 Language:** **English** · [中文](README.zh.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [Français](README.fr.md) · [Русский](README.md)

Tool and documentation for unpacking application installation packages for
**UGREEN NAS (UGOS Pro)** — files in the `.upk` format (`UGREEN-PKG-V2-FORMAT`).

📦 **Original `.upk` packages are in the [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1) section.**

The repository contains:

- **`tools/upk_extract.py`** — an unpacker for `.upk` packages with no external dependencies
  (only the Python 3 standard library).
- **`tools/upk_pack.py`** — the reverse packer: builds a `.upk` from an unpacked folder
  (round-trip verified byte-for-byte; see [`docs/en/REPACK.md`](docs/en/REPACK.md)).
- **`docs/`** — analysis of the container format and a step-by-step description of unpacking/packing.
- **`apps/`** — unpacked UGOS applications (files within the GitHub 100 MB limit;
  large binaries are excluded — the list is in [`apps/EXCLUDED.md`](apps/EXCLUDED.md)).
- **`catalog/`** — metadata for 19 official UGOS applications: the `config.json` manifest,
  the icon, and the full file list of each package.

> ⚠️ All application content is proprietary UGREEN software, published for the purposes of
> interoperability and analysis. The original `.upk` files (1.2 GB) are attached to the
> [`packages-v1` release](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).
> Individual binaries exceeding the GitHub 100 MB limit
> are not included in `apps/` — their list is in [`apps/EXCLUDED.md`](apps/EXCLUDED.md);
> you can build the complete set by unpacking the `.upk` files from the release with the `tools/` tool.

## Quick start

```bash
# unpack all .upk from a folder into ./packages, naming folders by <appId>-<version>
python3 tools/upk_extract.py /path/to/folder/with/upk ./packages

# build a .upk back from an unpacked folder
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

For each package the following is created:

```
packages/<appId>-<version>/
├── contents/          # application tree (config.json, sbin, www, init.d, ...)
├── icon.png           # application icon
└── _package_meta/     # signatures and public keys from the container
```

The `.upk` files themselves are renamed to `<appId>-<version>.upk`.

## Application catalog

19 official UGOS applications (all `amd64`, native). The full table with versions,
categories, and descriptions is in [`catalog/catalog.md`](catalog/catalog.md).
A machine-readable variant is [`catalog/catalog.json`](catalog/catalog.json).

| App ID | Application | Version |
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

## The `.upk` format

In brief: a text container `UGREEN-PKG-V2-FORMAT` with `key:length:value` fields,
containing an icon, cryptographic signatures, and the `ugb` payload
(**gzip → tar → `<appId>.ugb` → xz → tar →** the application tree).
A detailed analysis is in [`docs/en/FORMAT.md`](docs/en/FORMAT.md).

## Releases (downloads)

The original application installation packages are published as release assets:

- **Releases page:** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **`packages-v1` release** (19 `.upk` files, ~1.2 GB): <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

Download all packages via the GitHub CLI:

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## Documentation

- [`docs/en/FORMAT.md`](docs/en/FORMAT.md) — the structure of the `.upk` container byte-for-byte.
- [`docs/en/EXTRACTION.md`](docs/en/EXTRACTION.md) — how the unpacker works and how to use it.
- [`docs/en/REPACK.md`](docs/en/REPACK.md) — reverse packing into the `.upk` format.
- [`docs/en/SIGNING.md`](docs/en/SIGNING.md) — how UGOS verifies signatures and whether you can sign yourself.
- [`docs/en/LOCALIZATION.md`](docs/en/LOCALIZATION.md) — add your own app localization on the NAS without re-signing.

## License

The tool code and documentation are [MIT](LICENSE).
Trademarks, applications, and their binaries belong to UGREEN. The repository
is intended for educational purposes and interoperability.
