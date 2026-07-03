# Формат пакета UGREEN NAS `.upk` (UGREEN-PKG-V2-FORMAT)

Установочный пакет приложения UGOS Pro — это **не** обычный zip/tar. Это самодельный
текстово-бинарный контейнер с криптоподписями и многослойной полезной нагрузкой.

## 1. Внешний контейнер

Файл начинается с 20-байтовой сигнатуры:

```
UGREEN-PKG-V2-FORMAT
```

Далее подряд идут поля переменной длины в формате `ключ:длина:значение`, где
`длина` — десятичное число байт значения (ASCII), а `значение` — сырые байты:

```
<ключ>:<len>:<len байт значения><ключ>:<len>:<value>...
```

Наблюдаемые поля (в порядке следования):

| Ключ | Содержимое | Кодировка |
|---|---|---|
| `filesig` | Подпись полезной нагрузки | base64 |
| `userpub` | Публичный ключ пользователя (RSA) | base64, тело DER (SubjectPublicKeyInfo) |
| `usersig` | Подпись пользователя | base64 |
| `midpub`  | Публичный ключ издателя/канала (RSA) | base64 |
| `midsig`  | Подпись издателя | base64 |
| `ico`     | Иконка приложения | сырой PNG |
| `ugb`     | **Полезная нагрузка** (см. §2) | gzip |
| `obj2`    | Манифест хешей файлов | hex-строка |

Подписи и ключи — двухуровневая схема (пользователь + издатель `mid`), которой UGOS
проверяет целостность и происхождение пакета перед установкой.

### Псевдокод разбора

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

## 2. Полезная нагрузка `ugb`

Поле `ugb` — это несколько вложенных слоёв. Встречаются два варианта упаковки.

### Вариант A — одиночный вложенный бандл

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (единственный файл)
                    =  xz
                        └── tar (GNU)
                             └── дерево приложения (config.json, sbin/, www/, ...)
```

Пример: `com.ugreen.cameramgr`.

### Вариант B — многофайловый бандл со скриптами установки

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → дерево приложения)
```

Пример: `com.ugreen.netdisk`, `com.ugreen.photo` и большинство приложений UGOS 1.16.x.

В обоих случаях внутренний `<appId>.ugb` — это **xz-сжатый tar** (GNU format,
контрольная сумма CRC64) с корнем дерева приложения.

### Сигнатуры слоёв

| Формат | Магические байты |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | `ustar` по смещению 257 |

## 3. Дерево приложения

Корень внутреннего архива — файловая система приложения UGOS:

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

### Манифест `config.json`

Ключевые поля:

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

Имя папки при распаковке формируется как **`<appId>-<version.version>`**, например
`com.ugreen.cameramgr-1.0.0.0677`.
