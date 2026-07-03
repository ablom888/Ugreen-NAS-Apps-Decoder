# UGREEN NAS `.upk` पैकेज फ़ॉर्मैट (UGREEN-PKG-V2-FORMAT)

**🌐 भाषा:** [English](../en/FORMAT.md) · [中文](../zh/FORMAT.md) · **हिन्दी** · [Español](../es/FORMAT.md) · [Français](../fr/FORMAT.md) · [Русский](../FORMAT.md)

UGOS Pro अनुप्रयोग का इंस्टॉलेशन पैकेज एक साधारण zip/tar **नहीं** है। यह क्रिप्टो-हस्ताक्षरों
और बहु-स्तरीय पेलोड वाला एक स्वनिर्मित टेक्स्ट-बाइनरी कंटेनर है।

## 1. बाहरी कंटेनर

फ़ाइल 20-बाइट के हस्ताक्षर से शुरू होती है:

```
UGREEN-PKG-V2-FORMAT
```

इसके आगे लगातार `ключ:длина:значение` फ़ॉर्मैट में परिवर्तनशील लंबाई के फ़ील्ड आते हैं, जहाँ
`длина` — मान की बाइटों की दशमलव संख्या (ASCII) है, और `значение` — कच्ची बाइटें हैं:

```
<ключ>:<len>:<len байт значения><ключ>:<len>:<value>...
```

देखे गए फ़ील्ड (क्रम के अनुसार):

| कुंजी | सामग्री | एन्कोडिंग |
|---|---|---|
| `filesig` | पेलोड का हस्ताक्षर | base64 |
| `userpub` | उपयोगकर्ता की सार्वजनिक कुंजी (RSA) | base64, DER बॉडी (SubjectPublicKeyInfo) |
| `usersig` | उपयोगकर्ता का हस्ताक्षर | base64 |
| `midpub`  | प्रकाशक/चैनल की सार्वजनिक कुंजी (RSA) | base64 |
| `midsig`  | प्रकाशक का हस्ताक्षर | base64 |
| `ico`     | अनुप्रयोग का आइकन | कच्चा PNG |
| `ugb`     | **पेलोड** (देखें §2) | gzip |
| `obj2`    | फ़ाइल हैश का मैनिफ़ेस्ट | hex-स्ट्रिंग |

हस्ताक्षर और कुंजियाँ — दो-स्तरीय योजना (उपयोगकर्ता + प्रकाशक `mid`) हैं, जिससे UGOS
इंस्टॉलेशन से पहले पैकेज की अखंडता और उत्पत्ति की जाँच करता है।

### पार्सिंग स्यूडोकोड

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

## 2. पेलोड `ugb`

फ़ील्ड `ugb` — यह कई नेस्टेड परतें हैं। पैकिंग के दो प्रकार मिलते हैं।

### प्रकार A — एकल नेस्टेड बंडल

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (единственный файл)
                    =  xz
                        └── tar (GNU)
                             └── дерево приложения (config.json, sbin/, www/, ...)
```

उदाहरण: `com.ugreen.cameramgr`।

### प्रकार B — इंस्टॉलेशन स्क्रिप्ट के साथ बहु-फ़ाइल बंडल

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → дерево приложения)
```

उदाहरण: `com.ugreen.netdisk`, `com.ugreen.photo` और अधिकांश UGOS 1.16.x अनुप्रयोग।

दोनों ही मामलों में आंतरिक `<appId>.ugb` — यह **xz-संपीड़ित tar** (GNU format,
चेकसम CRC64) है, जिसका मूल अनुप्रयोग का ट्री है।

### परतों के हस्ताक्षर

| फ़ॉर्मैट | मैजिक बाइटें |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | ऑफ़सेट 257 पर `ustar` |

## 3. अनुप्रयोग का ट्री

आंतरिक संग्रह का मूल — UGOS अनुप्रयोग का फ़ाइल सिस्टम है:

```
contents/
├── config.json        # манифест: appId, version, arch, service, i18n, права
├── .check-app         # контрольные данные приложения
├── sbin/              # основные бинарники сервисов (напр. cameramgr_serv)
├── bin/               # вспомогательные бинарники
├── config/            # конфиги (yaml/toml)
├── init.d/            # systemd-юниты (*.service) и скрипты install/uninstall/pre/stop
├── www/               # веб-интерфейс (SPA: index.html, assets/, locale/)
├── nginx/, syslog/, logrotate/   # сервисные конфиги
├── i18n/              # переводы (msg.csv)
└── target/, img/      # ресурсы
```

### मैनिफ़ेस्ट `config.json`

मुख्य फ़ील्ड:

```jsonc
{
  "appId": "com.ugreen.cameramgr",
  "version": {
    "version": "1.0.0.0677",     // версия пакета
    "versionNum": 100000677,
    "lowVersion": "1.16.0.0065", // минимальная версия UGOS
    "buildTime": 1779875672
  },
  "arch": "amd64",
  "appType": 1,
  "daemon": true,
  "serviceName": "cameramgr_serv.service",
  "route": "/cameramgr",
  "pkgType": "ugb",              // тип пакета: ugb (нативный) либо docker
  "category": "category.system.tools",
  "isDockerApp": false,
  "languageList": ["zh-CN","en-US","de-DE", ...],
  "i18n": [ { "langName":"en-US","name":"Surveillance Center","description":"..." } ]
}
```

अनपैकिंग के समय फ़ोल्डर का नाम **`<appId>-<version.version>`** के रूप में बनता है, उदाहरण के लिए
`com.ugreen.cameramgr-1.0.0.0677`।
