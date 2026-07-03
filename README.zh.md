# UGREEN NAS Apps Decoder

**🌐 语言:** [English](README.en.md) · **中文** · [हिन्दी](README.hi.md) · [Español](README.es.md) · [Français](README.fr.md) · [Русский](README.md)

用于解包 **UGREEN NAS (UGOS Pro)** 应用安装包的工具和文档
——即 `.upk` 格式文件（`UGREEN-PKG-V2-FORMAT`）。

📦 **原始 `.upk` 安装包见 [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1) 页面。**

本仓库包含：

- **`tools/upk_extract.py`** —— 无外部依赖的 `.upk` 包解包器
  （仅使用 Python 3 标准库）。
- **`tools/upk_pack.py`** —— 反向打包器：从解包后的文件夹重新构建 `.upk`
  （已逐字节验证 round-trip；参见 [`docs/zh/REPACK.md`](docs/zh/REPACK.md)）。
- **`docs/`** —— 容器格式解析以及解包/打包的分步说明。
- **`apps/`** —— 解包后的 UGOS 应用（文件在 GitHub 100 MB 限制之内；
  大型二进制文件已排除——其列表见 [`apps/EXCLUDED.md`](apps/EXCLUDED.md)）。
- **`catalog/`** —— 19 个官方 UGOS 应用的元数据：`config.json` 清单、
  图标以及每个包的完整文件列表。

> ⚠️ 应用的全部内容均为 UGREEN 的专有软件，发布仅用于
> 兼容性和分析目的。原始 `.upk`（1.2 GB）已附于
> [`packages-v1` 发行版](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1)。
> 超过 GitHub 100 MB 限制的单个二进制文件
> 不包含在 `apps/` 中——其清单见 [`apps/EXCLUDED.md`](apps/EXCLUDED.md)；
> 可用 `tools/` 工具解包发行版中的 `.upk` 来获得完整集合。

## 快速开始

```bash
# 将文件夹中的所有 .upk 解包到 ./packages，文件夹按 <appId>-<version> 命名
python3 tools/upk_extract.py /路径/到/含upk的文件夹 ./packages

# 从解包后的文件夹重新打包为 .upk
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

每个包会生成：

```
packages/<appId>-<version>/
├── contents/          # 应用目录树（config.json, sbin, www, init.d, ...）
├── icon.png           # 应用图标
└── _package_meta/     # 容器中的签名和公钥
```

`.upk` 文件本身会被重命名为 `<appId>-<version>.upk`。

## 应用目录

19 个官方 UGOS 应用（全部为 `amd64`，原生）。带版本、
类别和描述的完整表格见 [`catalog/catalog.md`](catalog/catalog.md)。
机器可读版本见 [`catalog/catalog.json`](catalog/catalog.json)。

| App ID | 应用 | 版本 |
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

## `.upk` 格式

简述：这是一个文本容器 `UGREEN-PKG-V2-FORMAT`，字段格式为 `键:长度:值`，
内部包含图标、加密签名以及 `ugb` 负载
（**gzip → tar → `<appId>.ugb` → xz → tar →** 应用目录树）。
详细解析见 [`docs/zh/FORMAT.md`](docs/zh/FORMAT.md)。

## Releases（下载）

原始应用安装包已作为发行版资产上传：

- **发行版页面：** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **`packages-v1` 发行版**（19 个 `.upk` 文件，约 1.2 GB）：<https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

通过 GitHub CLI 下载所有包：

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## 文档

- [`docs/zh/FORMAT.md`](docs/zh/FORMAT.md) —— `.upk` 容器的逐字节结构。
- [`docs/zh/EXTRACTION.md`](docs/zh/EXTRACTION.md) —— 解包器的工作原理及使用方法。
- [`docs/zh/REPACK.md`](docs/zh/REPACK.md) —— 反向打包为 `.upk` 格式。
- [`docs/zh/SIGNING.md`](docs/zh/SIGNING.md) —— UGOS Pro 中的签名验证：工作原理以及能否自行签名。
- [`docs/zh/LOCALIZATION.md`](docs/zh/LOCALIZATION.md) —— 无需重新签名，为 UGOS 应用自行本地化。

## 许可证

工具代码和文档采用 [MIT](LICENSE) 许可证。
商标、应用及其二进制文件归 UGREEN 所有。本仓库
仅用于教育目的和兼容性（interoperability）。
