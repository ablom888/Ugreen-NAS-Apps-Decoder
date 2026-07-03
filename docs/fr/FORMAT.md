# Format du paquet UGREEN NAS `.upk` (UGREEN-PKG-V2-FORMAT)

**🌐 Langue :** [English](../en/FORMAT.md) · [中文](../zh/FORMAT.md) · [हिन्दी](../hi/FORMAT.md) · [Español](../es/FORMAT.md) · **Français** · [Русский](../FORMAT.md)

Le paquet d'installation d'une application UGOS Pro n'est **pas** un zip/tar ordinaire. C'est un
conteneur texte-binaire fait maison, avec des signatures cryptographiques et une charge utile multicouche.

## 1. Conteneur externe

Le fichier commence par une signature de 20 octets :

```
UGREEN-PKG-V2-FORMAT
```

Ensuite se succèdent des champs de longueur variable au format `clé:longueur:valeur`, où
`longueur` est le nombre d'octets de la valeur en décimal (ASCII), et `valeur` sont les octets bruts :

```
<ключ>:<len>:<len байт значения><ключ>:<len>:<value>...
```

Champs observés (dans l'ordre d'apparition) :

| Clé | Contenu | Encodage |
|---|---|---|
| `filesig` | Signature de la charge utile | base64 |
| `userpub` | Clé publique de l'utilisateur (RSA) | base64, corps DER (SubjectPublicKeyInfo) |
| `usersig` | Signature de l'utilisateur | base64 |
| `midpub`  | Clé publique de l'éditeur/canal (RSA) | base64 |
| `midsig`  | Signature de l'éditeur | base64 |
| `ico`     | Icône de l'application | PNG brut |
| `ugb`     | **Charge utile** (voir §2) | gzip |
| `obj2`    | Manifeste des hachages de fichiers | chaîne hex |

Les signatures et les clés forment un schéma à deux niveaux (utilisateur + éditeur `mid`), avec lequel UGOS
vérifie l'intégrité et l'origine du paquet avant l'installation.

### Pseudocode d'analyse

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

## 2. Charge utile `ugb`

Le champ `ugb` est constitué de plusieurs couches imbriquées. On rencontre deux variantes d'empaquetage.

### Variante A — bundle imbriqué unique

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (единственный файл)
                    =  xz
                        └── tar (GNU)
                             └── дерево приложения (config.json, sbin/, www/, ...)
```

Exemple : `com.ugreen.cameramgr`.

### Variante B — bundle multifichier avec scripts d'installation

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → дерево приложения)
```

Exemple : `com.ugreen.netdisk`, `com.ugreen.photo` et la plupart des applications UGOS 1.16.x.

Dans les deux cas, le `<appId>.ugb` interne est un **tar compressé en xz** (format GNU,
somme de contrôle CRC64) avec la racine de l'arbre de l'application.

### Signatures des couches

| Format | Octets magiques |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | `ustar` au décalage 257 |

## 3. Arbre de l'application

La racine de l'archive interne est le système de fichiers de l'application UGOS :

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

### Manifeste `config.json`

Champs clés :

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

Le nom du dossier lors du déballage est formé comme **`<appId>-<version.version>`**, par exemple
`com.ugreen.cameramgr-1.0.0.0677`.
