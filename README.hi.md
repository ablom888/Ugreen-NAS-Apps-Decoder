# UGREEN NAS Apps Decoder

**🌐 भाषा:** [English](README.en.md) · [中文](README.zh.md) · **हिन्दी** · [Español](README.es.md) · [Français](README.fr.md) · [Русский](README.md)

**UGREEN NAS (UGOS Pro)** के अनुप्रयोगों के इंस्टॉलेशन पैकेज — `.upk` फ़ॉर्मैट (`UGREEN-PKG-V2-FORMAT`) की फ़ाइलों —
को अनपैक करने के लिए एक उपकरण और दस्तावेज़ीकरण।

📦 **मूल `.upk` पैकेज — [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1) खंड में।**

रिपॉज़िटरी में शामिल है:

- **`tools/upk_extract.py`** — बिना किसी बाहरी निर्भरता के `.upk` पैकेज का अनपैकर
  (केवल Python 3 की मानक लाइब्रेरी)।
- **`tools/upk_pack.py`** — विपरीत पैकर: अनपैक किए गए फ़ोल्डर से `.upk` इकट्ठा करता है
  (round-trip बाइट-दर-बाइट सत्यापित; देखें [`docs/hi/REPACK.md`](docs/hi/REPACK.md))।
- **`docs/`** — कंटेनर फ़ॉर्मैट का विश्लेषण और अनपैकिंग/पैकिंग का चरण-दर-चरण विवरण।
- **`apps/`** — अनपैक किए गए UGOS अनुप्रयोग (फ़ाइलें GitHub की 100 एमबी सीमा के भीतर;
  बड़ी बाइनरी बाहर रखी गई हैं — उनकी सूची [`apps/EXCLUDED.md`](apps/EXCLUDED.md) में)।
- **`catalog/`** — 19 आधिकारिक UGOS अनुप्रयोगों का मेटाडेटा: मैनिफ़ेस्ट `config.json`,
  आइकन और प्रत्येक पैकेज की फ़ाइलों की पूरी सूची।

> ⚠️ अनुप्रयोगों की सारी सामग्री — UGREEN का स्वामित्व वाला सॉफ़्टवेयर है, जो
> संगतता और विश्लेषण के उद्देश्यों से प्रकाशित किया गया है। मूल `.upk` (1.2 जीबी)
> [रिलीज़ `packages-v1`](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1) के साथ संलग्न हैं।
> GitHub की 100 एमबी सीमा से बड़ी अलग-अलग बाइनरी
> `apps/` में शामिल नहीं हैं — उनकी सूची [`apps/EXCLUDED.md`](apps/EXCLUDED.md) में है;
> पूरा सेट `tools/` उपकरण से रिलीज़ के `.upk` को अनपैक करके इकट्ठा किया जा सकता है।

## त्वरित शुरुआत

```bash
# распаковать все .upk из папки в ./packages, назвав папки по <appId>-<version>
python3 tools/upk_extract.py /путь/к/папке/с/upk ./packages

# собрать .upk обратно из распакованной папки
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

प्रत्येक पैकेज के लिए बनाया जाता है:

```
packages/<appId>-<version>/
├── contents/          # дерево приложения (config.json, sbin, www, init.d, ...)
├── icon.png           # иконка приложения
└── _package_meta/     # подписи и публичные ключи из контейнера
```

`.upk` फ़ाइलें स्वयं `<appId>-<version>.upk` में पुनः नामित हो जाती हैं।

## अनुप्रयोगों का कैटलॉग

19 आधिकारिक UGOS अनुप्रयोग (सभी — `amd64`, नेटिव)। संस्करणों, श्रेणियों और
विवरणों के साथ पूरी तालिका — [`catalog/catalog.md`](catalog/catalog.md) में।
मशीन-पठनीय संस्करण — [`catalog/catalog.json`](catalog/catalog.json)।

| App ID | अनुप्रयोग | संस्करण |
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

## `.upk` फ़ॉर्मैट

संक्षेप में: `ключ:длина:значение` फ़ील्ड वाला टेक्स्ट कंटेनर `UGREEN-PKG-V2-FORMAT`,
जिसके अंदर — एक आइकन, क्रिप्टो-हस्ताक्षर और पेलोड `ugb`
(**gzip → tar → `<appId>.ugb` → xz → tar →** अनुप्रयोग का ट्री)।
विस्तृत विश्लेषण — [`docs/hi/FORMAT.md`](docs/hi/FORMAT.md) में।

## Releases (डाउनलोड)

अनुप्रयोगों के मूल इंस्टॉलेशन पैकेज रिलीज़ के एसेट के रूप में उपलब्ध हैं:

- **रिलीज़ पृष्ठ:** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **रिलीज़ `packages-v1`** (19 `.upk` फ़ाइलें, ~1.2 जीबी): <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

GitHub CLI के माध्यम से सभी पैकेज डाउनलोड करें:

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## दस्तावेज़ीकरण

- [`docs/hi/FORMAT.md`](docs/hi/FORMAT.md) — `.upk` कंटेनर की संरचना बाइट-दर-बाइट।
- [`docs/hi/EXTRACTION.md`](docs/hi/EXTRACTION.md) — अनपैकर कैसे काम करता है और उसका उपयोग कैसे करें।
- [`docs/hi/REPACK.md`](docs/hi/REPACK.md) — `.upk` फ़ॉर्मैट में विपरीत पैकिंग।

## लाइसेंस

उपकरण का कोड और दस्तावेज़ीकरण — [MIT](LICENSE)।
ट्रेडमार्क, अनुप्रयोग और उनकी बाइनरी UGREEN की संपत्ति हैं। रिपॉज़िटरी
शैक्षिक उद्देश्यों और संगतता (interoperability) के लिए है।
