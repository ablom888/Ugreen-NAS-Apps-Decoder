# 解包 UGREEN `.upk` 包

**🌐 语言:** [English](../en/EXTRACTION.md) · **中文** · [हिन्दी](../hi/EXTRACTION.md) · [Español](../es/EXTRACTION.md) · [Français](../fr/EXTRACTION.md) · [Русский](../EXTRACTION.md)

## 要求

- Python 3.8+（仅标准库：`gzip`、`lzma`、`bz2`、`tarfile`）。
- 无需外部工具。

## 用法

```bash
python3 tools/upk_extract.py <含upk的文件夹> [输出文件夹]
```

- `<含upk的文件夹>` —— 存放 `*.upk` 文件的目录。
- `[输出文件夹]` —— 解包到何处（默认 `<含upk的文件夹>/packages`）。

示例：

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## 脚本做了什么

对每个 `*.upk`：

1. **解析外层容器** `UGREEN-PKG-V2-FORMAT`，拆分为 `键:长度:值` 字段
   （见 [FORMAT.md](FORMAT.md)）。
2. 取出 `ugb` 负载并**递归剥离压缩层**（gzip → xz），
   解开 tar 归档。
3. 处理两种打包方式：
   - 单个嵌套的 `<appId>.ugb`；
   - 带 `install.sh`/`uninstall.sh` 脚本 + `<appId>.ugb` 的多文件 tar
     （嵌套的 `*.ugb` 由 `expand_nested_ugb` 函数就地展开）。
4. 读取 `config.json`，取出 `appId` 和 `version.version`。
5. 组织结果：

   ```
   packages/<appId>-<version>/
   ├── contents/          # 应用目录树
   ├── icon.png           # 图标（ico 字段）
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. 将源 `*.upk` **重命名**为 `<appId>-<version>.upk`。
7. 写入汇总的 `packages/catalog.json`，包含所有元数据。

## `upk_extract.py` 的关键函数

| 函数 | 用途 |
|---|---|
| `parse_upk(path)` | 将外层容器解析为字段字典 |
| `sniff(data)` | 通过魔术字节判断格式 |
| `decompress_layers(data)` | 剥离连续的 gzip/xz/bzip2 层 |
| `deep_extract(data, dest)` | 递归解包直至应用目录树 |
| `expand_nested_ugb(dest)` | 展开目录树内嵌套的 `*.ugb` |
| `find_config(root)` | 查找 `config.json` 清单 |
| `process(upk, out)` | 单个包的完整流程 |

## 说明

- 只展开嵌套的 `*.ugb`；`www/` 内诸如 `index.html.gz`
  和 `version.json.gz` 之类的普通资源**不会**被触碰。
- 脚本使用 `tarfile.extractall(..., filter="data")` —— 安全的
  提取模式（Python 3.12+），会阻止指向目标文件夹之外的路径。
- `_package_meta/` 中的签名不会被校验——它们按原样保存以供分析。
  完整性校验由 UGOS 在安装时自行执行。

## 验证结果

```bash
# 列出应用及其版本
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# 某个包的目录树
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
