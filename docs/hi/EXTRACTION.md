# UGREEN `.upk` पैकेज की अनपैकिंग

**🌐 भाषा:** [English](../en/EXTRACTION.md) · [中文](../zh/EXTRACTION.md) · **हिन्दी** · [Español](../es/EXTRACTION.md) · [Français](../fr/EXTRACTION.md) · [Русский](../EXTRACTION.md)

## आवश्यकताएँ

- Python 3.8+ (केवल मानक लाइब्रेरी: `gzip`, `lzma`, `bz2`, `tarfile`)।
- किसी बाहरी उपयोगिता की आवश्यकता नहीं।

## उपयोग

```bash
python3 tools/upk_extract.py <папка-с-upk> [папка-вывода]
```

- `<папка-с-upk>` — वह निर्देशिका जहाँ `*.upk` फ़ाइलें रखी हैं।
- `[папка-вывода]` — कहाँ अनपैक करना है (डिफ़ॉल्ट रूप से `<папка-с-upk>/packages`)।

उदाहरण:

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## स्क्रिप्ट क्या करती है

प्रत्येक `*.upk` के लिए:

1. **बाहरी कंटेनर** `UGREEN-PKG-V2-FORMAT` को `ключ:длина:значение` फ़ील्डों में पार्स करता है
   (देखें [FORMAT.md](FORMAT.md))।
2. पेलोड `ugb` को लेता है और **पुनरावर्ती रूप से संपीड़न की परतें हटाता है** (gzip → xz),
   tar-संग्रहों को अनपैक करते हुए।
3. पैकिंग के दोनों प्रकारों को संभालता है:
   - एकल नेस्टेड `<appId>.ugb`;
   - `install.sh`/`uninstall.sh` स्क्रिप्ट + `<appId>.ugb` वाला बहु-फ़ाइल tar
     (नेस्टेड `*.ugb` को `expand_nested_ugb` फ़ंक्शन द्वारा वहीं पर विस्तारित किया जाता है)।
4. `config.json` को पढ़ता है, `appId` और `version.version` लेता है।
5. परिणाम को व्यवस्थित करता है:

   ```
   packages/<appId>-<version>/
   ├── contents/          # дерево приложения
   ├── icon.png           # иконка (поле ico)
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. मूल `*.upk` को `<appId>-<version>.upk` में **पुनः नामित** करता है।
7. सभी मेटाडेटा के साथ सारांश `packages/catalog.json` लिखता है।

## `upk_extract.py` के मुख्य फ़ंक्शन

| फ़ंक्शन | उद्देश्य |
|---|---|
| `parse_upk(path)` | बाहरी कंटेनर को फ़ील्डों के शब्दकोश में पार्स करना |
| `sniff(data)` | मैजिक बाइटों द्वारा फ़ॉर्मैट का निर्धारण |
| `decompress_layers(data)` | gzip/xz/bzip2 की लगातार परतों को हटाना |
| `deep_extract(data, dest)` | अनुप्रयोग के ट्री तक पुनरावर्ती अनपैकिंग |
| `expand_nested_ugb(dest)` | ट्री के अंदर नेस्टेड `*.ugb` का विस्तार |
| `find_config(root)` | मैनिफ़ेस्ट `config.json` की खोज |
| `process(upk, out)` | एक पैकेज के लिए पूरा चक्र |

## टिप्पणियाँ

- केवल नेस्टेड `*.ugb` विस्तारित किए जाते हैं; `www/` के अंदर `index.html.gz`
  और `version.json.gz` जैसे सामान्य एसेट को **नहीं** छुआ जाता।
- स्क्रिप्ट `tarfile.extractall(..., filter="data")` का उपयोग करती है — यह निष्कर्षण का
  सुरक्षित मोड (Python 3.12+) है, जो लक्ष्य फ़ोल्डर के बाहर के पथों को अवरुद्ध करता है।
- `_package_meta/` के हस्ताक्षर सत्यापित नहीं किए जाते — उन्हें विश्लेषण के लिए ज्यों-का-त्यों सहेजा जाता है।
  अखंडता की जाँच UGOS स्वयं इंस्टॉलेशन के समय करता है।

## परिणाम की जाँच

```bash
# список приложений с версиями
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# дерево одного пакета
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
