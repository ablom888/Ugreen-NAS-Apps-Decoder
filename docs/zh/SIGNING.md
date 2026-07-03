# UGOS Pro 中的签名验证：工作原理以及能否自行签名

**🌐 语言:** [English](../en/SIGNING.md) · **中文** · [हिन्दी](../hi/SIGNING.md) · [Español](../es/SIGNING.md) · [Français](../fr/SIGNING.md) · [Русский](../SIGNING.md)

本分析基于固件 `firmware_image-1.16.0.89`（UGOS Pro，Debian 12，amd64）。

## 谁来验证包

- **`/usr/sbin/uginstall`** —— `.upk` 包的安装器（Go 二进制文件）。正是它
  解析 `UGREEN-PKG-V2-FORMAT` 容器、验证签名并展开
  应用目录树。二进制文件中的字符串：`systemVerify`、`GetVerifyKey`、
  `verifyData`、`un_support_sign_ver`、`parse_package_error`。
- 加密：**RSA + SHA-256**（二进制文件中为 `crypto/rsa`、`crypto/sha256`，
  带有 RSA-PSS 特征）。`upk_pack.py` 也印证了这一点：签名 `filesig/usersig/midsig`。

## 信任根（「内嵌」到固件中的内容）

受信任的**公**钥位于固件的只读分区中：

```
/rom/usr/ugreen/etc/rsa/ugreenRoot.pub         # 根密钥
/rom/usr/ugreen/etc/rsa/ugreenRootImport.pub   # 用于导入的根密钥
/rom/usr/ugreen/etc/rsa/ugreen.pub             # 应用级密钥
```

`uginstall` 将 `ugreenRoot.pub` 读取为信任锚。`/rom` 分区就是
`fw.squashfs`（xz 压缩的只读 squashfs），它是已签名固件的一部分。

## 签名链

对 19 个包进行密钥比对，显示出三级签名链：

```
ugreenRoot（内嵌于 /rom，私钥在 UGREEN 手中）
      └── 签发渠道中间密钥  (midpub —— 在所有包中都相同)
                └── 签发构建密钥       (userpub —— 每个包各不相同)
                          └── 签发 payload  (filesig/usersig)
```

- `midpub` 在所有包中都相同 → 这是发布者的中间密钥。
- `userpub` 对每个包都唯一 → 具体构建的密钥。
- 包中只保存公开部分（`midpub`、`userpub`）和签名。

## 关于「自行签名」的核心结论

**固件中只有公钥。里面没有 UGREEN 的私钥** —— 也不
应该有（否则就意味着厂商自身被攻破）。因此：

| 问题 | 答案 |
|---|---|
| 能否从 NAS 中提取签名私钥？ | **不能** —— 那里没有私钥，只有 `.pub`。 |
| 能否为「原厂」NAS 签名一个修改过的包？ | **不能** —— 需要 `ugreenRoot`/`mid` 的私钥。伪造 = 破解 RSA。 |
| 能否在自己的设备上用自己的密钥签名？ | 技术上可以，但只能通过替换信任锚（见下文）。脆弱，不推荐。 |

### 为什么「自己签名」是条糟糕的路

要让 NAS 接受你用自己的密钥签名的包，就需要把
`ugreenRoot.pub`（及相关密钥）替换成你的公钥。但是：

- `/rom` 是来自**已签名**固件的只读 squashfs；固件由
  独立的更新器 `ugupdate` 验证，因此单纯重新打包固件是行不通的；
- 运行时替换密钥（在 `/rom` 上做 bind-mount）无法在系统更新后
  幸存，并且会触及系统组件；
- 这会破坏设备上所有应用的正规真实性验证。

## 验证究竟在何时执行

- **签名只在包的安装时被验证**（`uginstall`）。
- 安装后，文件系统中只剩下应用目录树
  （`contents/`），`.upk` 本身和签名都已不在其中。
- **运行期间** UGOS 使用 `reconcile` 模式：检查文件是否丢失
  （`reason=files-missing`）以及完整性清单 **`.check-app`**（JSON
  `路径 → md5`）。此时并不会重新验证签名。

## 对本地化的实际结论

既然签名只在安装时验证，而应用之后从磁盘上的文件夹运行
—— **可以在已安装应用之上叠加自己的本地化，无需重新签名**。
只需编辑本地化文件并更新 `.check-app`
（以通过运行时 `reconcile`）。现成的脚本和说明
见 [LOCALIZATION.md](LOCALIZATION.md)。
