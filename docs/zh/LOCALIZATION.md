# 无需重新签名，为 UGOS 应用自行本地化

**🌐 语言:** [English](../en/LOCALIZATION.md) · **中文** · [हिन्दी](../hi/LOCALIZATION.md) · [Español](../es/LOCALIZATION.md) · [Français](../fr/LOCALIZATION.md) · [Русский](../LOCALIZATION.md)

UGOS 中的签名验证**只在** `.upk` 包安装时执行
（详见 [SIGNING.md](SIGNING.md)）。安装后应用从磁盘上的
文件夹运行，因此自己的语言是通过**修改已安装应用的文件**来添加的
—— 无需重新打包和重新签名。只需更新完整性清单
`.check-app`，以通过运行时的 `reconcile` 检查。

工具（Python 3，无依赖）—— 见 [`tools/localization/`](../tools/localization)：

- **`ug_localize.py`** —— 查找应用、创建本地化模板、应用翻译。
- **`ug_checkapp.py`** —— 校验/重新计算 `.check-app`。

## 本地化存放在哪里

```
<app_dir>/
├── config.json            → 字段 languageList（语言代码列表）
├── www/locale/<lang>.json     Web 界面文本
├── www/locale/<lang>.json.gz  压缩副本（由 nginx 提供）—— 由脚本重新生成
└── i18n/msg.csv               服务端字符串（可选）
```

`<lang>` —— UGOS 风格的代码：`en-US`、`de-DE`、`ru-RU`、`zh-CN` 等。

## 快速开始（在 NAS 本机上，以 root/admin 身份）

```bash
# 0) 将 tools/localization/ 复制到 NAS（两个 .py 放在一起）

# 1) 按 appId 查找已安装应用的文件夹
python3 ug_localize.py find com.ugreen.cameramgr

# 2) 查看当前的本地化和语言
python3 ug_localize.py list com.ugreen.cameramgr

# 3) 从英文本地化创建新语言的模板
python3 ug_localize.py scaffold com.ugreen.cameramgr ru-RU --from en-US

# 4) 在 www/locale/ru-RU.json 中编辑值（不要改键！）
#    直接在 NAS 上用任意编辑器

# 5) 应用：生成 .gz，将 ru-RU 加入 languageList，
#    更新 .check-app 并（可选）重启服务
python3 ug_localize.py apply com.ugreen.cameramgr ru-RU \
        <app_dir>/www/locale/ru-RU.json --restart
```

在任意命令中都可以用应用文件夹的路径直接代替 `appId`
（如果自动查找找不到 —— 例如非标准卷）。

## 校验与回滚

```bash
# 校验完整性（.check-app 中的所有 md5）
python3 ug_checkapp.py verify <app_dir>

# apply 会在旁边备份上一个本地化文件：<lang>.json.bak
# 回滚：把 .bak 放回原位并再次更新清单
mv <app_dir>/www/locale/ru-RU.json.bak <app_dir>/www/locale/ru-RU.json
python3 ug_checkapp.py refresh <app_dir> <app_dir>/www/locale/ru-RU.json
```

## `apply` 具体做了什么

1. 检查翻译文件是否为有效的 JSON。
2. 将其放到 `www/locale/<lang>.json`（或将已编辑好的文件定稿），
   如果文件已存在则做 `.bak` 备份。
3. 生成 `www/locale/<lang>.json.gz`（供 nginx `gzip_static` 使用）。
4. 将 `<lang>` 加入 `config.json → languageList`。
5. 重新计算 `.check-app`：更新已改动文件（包括
   `config.json`）的 md5，并登记新的本地化文件。不触碰 `config/` 中的文件 ——
   它们在原始清单中本就被排除。
6. 带 `--restart` 标志时重启应用服务（来自 config.json 的 `serviceName`）。

## 重要提示

- **只改翻译值，不要改键**（在 `<lang>.json` 中）—— 键必须
  与基础本地化一致，否则界面会显示空字符串。
- 改动能在重启后保留，但**可能在应用更新时被覆盖**
  （重装会放回原始文件）。更新后请重新
  应用本地化。
- 这一切都是在**你自己的**设备上的操作。安装时既不伪造也不
  绕过厂商签名；我们只是补充已安装的应用，并
  以一致的方式维护其本地完整性清单。
- 需要对 NAS 文件系统的 root/admin 访问权限（通常通过 SSH）。
