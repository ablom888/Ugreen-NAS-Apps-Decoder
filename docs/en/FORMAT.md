# The UGREEN NAS `.upk` package format (UGREEN-PKG-V2-FORMAT)

**🌐 Language:** **English** · [中文](../zh/FORMAT.md) · [हिन्दी](../hi/FORMAT.md) · [Español](../es/FORMAT.md) · [Français](../fr/FORMAT.md) · [Русский](../FORMAT.md)

A UGOS Pro application installation package is **not** an ordinary zip/tar. It is a custom
text-binary container with cryptographic signatures and a multi-layered payload.

## 1. Outer container

The file begins with a 20-byte signature:

```
UGREEN-PKG-V2-FORMAT
```

It is followed by consecutive variable-length fields in the `key:length:value` format, where
`length` is the decimal number of value bytes (ASCII), and `value` is raw bytes:

```
<key>:<len>:<len value bytes><key>:<len>:<value>...
```

Observed fields (in order of appearance):

| Key | Content | Encoding |
|---|---|---|
| `filesig` | Payload signature | base64 |
| `userpub` | User public key (RSA) | base64, DER body (SubjectPublicKeyInfo) |
| `usersig` | User signature | base64 |
| `midpub`  | Publisher/channel public key (RSA) | base64 |
| `midsig`  | Publisher signature | base64 |
| `ico`     | Application icon | raw PNG |
| `ugb`     | **Payload** (see §2) | gzip |
| `obj2`    | File hash manifest | hex string |

The signatures and keys form a two-level scheme (user + publisher `mid`), with which UGOS
verifies the integrity and origin of the package before installation.

### Parsing pseudocode

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

## 2. The `ugb` payload

The `ugb` field is several nested layers. Two packaging variants occur.

### Variant A — single nested bundle

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (single file)
                    =  xz
                        └── tar (GNU)
                             └── application tree (config.json, sbin/, www/, ...)
```

Example: `com.ugreen.cameramgr`.

### Variant B — multi-file bundle with install scripts

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → application tree)
```

Example: `com.ugreen.netdisk`, `com.ugreen.photo`, and most UGOS 1.16.x applications.

In both cases the inner `<appId>.ugb` is an **xz-compressed tar** (GNU format,
CRC64 checksum) with the root of the application tree.

### Layer signatures

| Format | Magic bytes |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | `ustar` at offset 257 |

## 3. Application tree

The root of the inner archive is the file system of the UGOS application:

```
contents/
├── config.json        # manifest: appId, version, arch, service, i18n, permissions
├── .check-app         # application check data
├── sbin/              # main service binaries (e.g. cameramgr_serv)
├── bin/               # helper binaries
├── config/            # configs (yaml/toml)
├── init.d/            # systemd units (*.service) and install/uninstall/pre/stop scripts
├── www/               # web interface (SPA: index.html, assets/, locale/)
├── nginx/, syslog/, logrotate/   # service configs
├── i18n/              # translations (msg.csv)
└── target/, img/      # resources
```

### The `config.json` manifest

Key fields:

```jsonc
{
  "appId": "com.ugreen.cameramgr",
  "version": {
    "version": "1.0.0.0677",     // package version
    "versionNum": 100000677,
    "lowVersion": "1.16.0.0065", // minimum UGOS version
    "buildTime": 1779875672
  },
  "arch": "amd64",
  "appType": 1,
  "daemon": true,
  "serviceName": "cameramgr_serv.service",
  "route": "/cameramgr",
  "pkgType": "ugb",              // package type: ugb (native) or docker
  "category": "category.system.tools",
  "isDockerApp": false,
  "languageList": ["zh-CN","en-US","de-DE", ...],
  "i18n": [ { "langName":"en-US","name":"Surveillance Center","description":"..." } ]
}
```

The folder name upon unpacking is formed as **`<appId>-<version.version>`**, for example
`com.ugreen.cameramgr-1.0.0.0677`.
