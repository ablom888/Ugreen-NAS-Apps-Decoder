# UGREEN NAS `.upk` 包格式（UGREEN-PKG-V2-FORMAT）

**🌐 语言:** [English](../en/FORMAT.md) · **中文** · [हिन्दी](../hi/FORMAT.md) · [Español](../es/FORMAT.md) · [Français](../fr/FORMAT.md) · [Русский](../FORMAT.md)

UGOS Pro 应用安装包**不是**普通的 zip/tar。它是一个自定义的
文本-二进制混合容器，带有加密签名和多层负载。

## 1. 外层容器

文件以 20 字节的签名开头：

```
UGREEN-PKG-V2-FORMAT
```

随后是一系列变长字段，格式为 `键:长度:值`，其中
`长度` 是值的字节数（ASCII 十进制数），`值` 为原始字节：

```
<键>:<len>:<len 字节的值><键>:<len>:<value>...
```

观察到的字段（按出现顺序）：

| 键 | 内容 | 编码 |
|---|---|---|
| `filesig` | 负载签名 | base64 |
| `userpub` | 用户公钥 (RSA) | base64，DER 主体 (SubjectPublicKeyInfo) |
| `usersig` | 用户签名 | base64 |
| `midpub`  | 发行方/渠道公钥 (RSA) | base64 |
| `midsig`  | 发行方签名 | base64 |
| `ico`     | 应用图标 | 原始 PNG |
| `ugb`     | **负载**（见 §2） | gzip |
| `obj2`    | 文件哈希清单 | hex 字符串 |

签名和密钥采用双层方案（用户 + 发行方 `mid`），UGOS 借此
在安装前验证包的完整性和来源。

### 解析伪代码

```python
assert data[:20] == b"UGREEN-PKG-V2-FORMAT"
pos = 20
fields = {}
while pos < len(data):
    m = re.match(rb"([a-z0-9]+):(\d+):", data[pos:pos+40])
    if not m: break
    key, ln = m.group(1).decode(), int(m.group(2))
    start = pos + m.end()
    fields[key] = data[start:start+ln]
    pos = start + ln
```

## 2. `ugb` 负载

`ugb` 字段由多个嵌套层组成。存在两种打包方式。

### 方式 A —— 单个嵌套 bundle

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (唯一文件)
                    =  xz
                        └── tar (GNU)
                             └── 应用目录树（config.json, sbin/, www/, ...）
```

示例：`com.ugreen.cameramgr`。

### 方式 B —— 带安装脚本的多文件 bundle

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → 应用目录树)
```

示例：`com.ugreen.netdisk`、`com.ugreen.photo` 以及大多数 UGOS 1.16.x 应用。

两种情况下，内部的 `<appId>.ugb` 都是 **xz 压缩的 tar**（GNU format，
CRC64 校验和），其根为应用目录树。

### 各层签名

| 格式 | 魔术字节 |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | 偏移 257 处的 `ustar` |

## 3. 应用目录树

内部归档的根是 UGOS 应用的文件系统：

```
contents/
├── config.json        # 清单：appId, version, arch, service, i18n, 权限
├── .check-app         # 应用校验数据
├── sbin/              # 服务的主要二进制文件（如 cameramgr_serv）
├── bin/               # 辅助二进制文件
├── config/            # 配置文件（yaml/toml）
├── init.d/            # systemd 单元（*.service）以及 install/uninstall/pre/stop 脚本
├── www/              # Web 界面（SPA: index.html, assets/, locale/）
├── nginx/, syslog/, logrotate/   # 服务配置
├── i18n/              # 翻译（msg.csv）
└── target/, img/      # 资源
```

### 清单 `config.json`

关键字段：

```jsonc
{
  "appId": "com.ugreen.cameramgr",
  "version": {
    "version": "1.0.0.0677",     // 包版本
    "versionNum": 100000677,
    "lowVersion": "1.16.0.0065", // 最低 UGOS 版本
    "buildTime": 1779875672
  },
  "arch": "amd64",
  "appType": 1,
  "daemon": true,
  "serviceName": "cameramgr_serv.service",
  "route": "/cameramgr",
  "pkgType": "ugb",              // 包类型：ugb（原生）或 docker
  "category": "category.system.tools",
  "isDockerApp": false,
  "languageList": ["zh-CN","en-US","de-DE", ...],
  "i18n": [ { "langName":"en-US","name":"Surveillance Center","description":"..." } ]
}
```

解包时文件夹名按 **`<appId>-<version.version>`** 生成，例如
`com.ugreen.cameramgr-1.0.0.0677`。
