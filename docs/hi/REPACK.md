# UGREEN `.upk` फ़ॉर्मैट में विपरीत पैकिंग

**🌐 भाषा:** [English](../en/REPACK.md) · [中文](../zh/REPACK.md) · **हिन्दी** · [Español](../es/REPACK.md) · [Français](../fr/REPACK.md) · [Русский](../REPACK.md)

`tools/upk_pack.py` उस फ़ोल्डर से `.upk` पैकेज (UGREEN-PKG-V2-FORMAT) वापस इकट्ठा करता है,
जिसे `upk_extract.py` ने बनाया था।

## उपयोग

```bash
python3 tools/upk_pack.py <папка-пакета> [выход.upk]
```

- `<папка-пакета>` — `<appId>-<version>/` जैसा फ़ोल्डर, जिसके अंदर `contents/` सबफ़ोल्डर हो
  (और, बेहतर हो तो, `icon.png` + `_package_meta/`)।
- `[выход.upk]` — परिणाम का पथ (डिफ़ॉल्ट रूप से पास में `<папка>.repacked.upk`)।

उदाहरण:

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## कंटेनर कैसे इकट्ठा होता है

परतें अनपैकिंग के विपरीत क्रम में बनाई जाती हैं (देखें [FORMAT.md](FORMAT.md)):

```
inner  = xz( tar(GNU)  [ contents/ без install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + поля key:len:value
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- आंतरिक संग्रह — GNU tar, xz से संपीड़ित (CHECK_CRC64, preset 9|EXTREME)।
- बाहरी payload — tar, gzip से संपीड़ित (स्तर 9)।
- कंटेनर के फ़ील्ड निश्चित क्रम में लिखे जाते हैं; `ico` को `icon.png` से लिया जाता है,
  हस्ताक्षर/कुंजियाँ/`obj2` — `_package_meta/` से।

## round-trip की जाँच

पैकिंग → अनपैकिंग अनुप्रयोग के ट्री को पूरी तरह सुरक्षित रखती है:

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # различий нет
```

जाँचा गया: `config.json`, फ़ाइलों की सूची और ट्री की **सभी फ़ाइलों की बाइट-दर-बाइट सामग्री**
मूल के साथ मेल खाती है।

## सीमा: हस्ताक्षर

फ़ील्ड `filesig` / `usersig` / `midsig` — ये विक्रेता के RSA-हस्ताक्षर हैं, जो उसकी
**निजी** कुंजियों से बनाए गए हैं, जो पैकेज में मौजूद नहीं हैं। इसलिए वैध हस्ताक्षर को दोबारा
इकट्ठा करना असंभव है। `upk_pack.py` सहेजे गए हस्ताक्षरों, सार्वजनिक कुंजियों और
`obj2` को `_package_meta/` से **पुनः उपयोग** करता है।

परिणामस्वरूप: payload के पुनः संपीड़न पर उसका हैश और हस्ताक्षर सामग्री से मेल खाना बंद कर
देते हैं, इसलिए ऐसा पैकेज **इंस्टॉलेशन के समय UGOS की अखंडता जाँच को पास करने की गारंटी नहीं
देता**। यह उपकरण फ़ॉर्मैट के अध्ययन, संशोधन और ट्री के पुनः निर्माण के लिए है, न कि हस्ताक्षर
जाँच को दरकिनार करने के लिए।
