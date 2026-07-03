# 反向打包为 UGREEN `.upk` 格式

**🌐 语言:** [English](../en/REPACK.md) · **中文** · [हिन्दी](../hi/REPACK.md) · [Español](../es/REPACK.md) · [Français](../fr/REPACK.md) · [Русский](../REPACK.md)

`tools/upk_pack.py` 从 `upk_extract.py` 创建的文件夹重新
构建 `.upk` 包（UGREEN-PKG-V2-FORMAT）。

## 用法

```bash
python3 tools/upk_pack.py <包文件夹> [输出.upk]
```

- `<包文件夹>` —— 形如 `<appId>-<version>/` 的文件夹，内部含 `contents/` 子文件夹
  （最好还有 `icon.png` + `_package_meta/`）。
- `[输出.upk]` —— 结果路径（默认在旁边生成 `<文件夹>.repacked.upk`）。

示例：

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## 容器如何构建

各层按解包的相反顺序构建（见 [FORMAT.md](FORMAT.md)）：

```
inner  = xz( tar(GNU)  [ contents/ 不含 install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + key:len:value 字段
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- 内部归档为 GNU tar，使用 xz 压缩（CHECK_CRC64，preset 9|EXTREME）。
- 外层 payload 为 tar，使用 gzip 压缩（级别 9）。
- 容器字段按固定顺序写入；`ico` 取自 `icon.png`，
  签名/密钥/`obj2` 取自 `_package_meta/`。

## Round-trip 验证

打包 → 解包能完整保留应用目录树：

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # 无差异
```

已验证：`config.json`、文件列表以及目录树中**所有文件的逐字节内容**
均与原始文件一致。

## 限制：签名

`filesig` / `usersig` / `midsig` 字段是厂商的 RSA 签名，由其
**私钥**生成，而包中并不包含这些私钥。因此无法重建有效签名。
`upk_pack.py` **复用** `_package_meta/` 中保存的签名、公钥和
`obj2`。

结果：重新压缩 payload 后，其哈希和签名不再与内容匹配，
因此这样的包**不保证能通过 UGOS 安装时的完整性校验**。
本工具用于研究格式、修改并重新构建目录树，而非
绕过签名校验。
