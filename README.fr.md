# UGREEN NAS Apps Decoder

**🌐 Langue :** [English](README.en.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · **Français** · [Русский](README.md)

Outil et documentation pour le déballage des paquets d'installation d'applications
**UGREEN NAS (UGOS Pro)** — fichiers au format `.upk` (`UGREEN-PKG-V2-FORMAT`).

📦 **Les paquets `.upk` d'origine se trouvent dans la section [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).**

Le dépôt contient :

- **`tools/upk_extract.py`** — outil de déballage des paquets `.upk` sans dépendances externes
  (uniquement la bibliothèque standard de Python 3).
- **`tools/upk_pack.py`** — outil d'empaquetage inverse : reconstruit un `.upk` à partir d'un dossier déballé
  (round-trip vérifié octet par octet ; voir [`docs/fr/REPACK.md`](docs/fr/REPACK.md)).
- **`docs/`** — analyse du format du conteneur et description pas à pas du déballage/empaquetage.
- **`apps/`** — applications UGOS déballées (fichiers dans la limite GitHub de 100 Mo ;
  les binaires volumineux sont exclus — leur liste dans [`apps/EXCLUDED.md`](apps/EXCLUDED.md)).
- **`catalog/`** — métadonnées des 19 applications officielles UGOS : manifeste `config.json`,
  icône et liste complète des fichiers de chaque paquet.

> ⚠️ Tout le contenu des applications est un logiciel propriétaire UGREEN, publié à des fins
> d'interopérabilité et d'analyse. Les `.upk` d'origine (1,2 Go) sont joints à la
> [release `packages-v1`](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).
> Les binaires individuels dépassant la limite GitHub de 100 Mo
> ne sont pas inclus dans `apps/` — leur liste dans [`apps/EXCLUDED.md`](apps/EXCLUDED.md) ;
> vous pouvez reconstituer l'ensemble complet en déballant les `.upk` de la release avec l'outil `tools/`.

## Démarrage rapide

```bash
# распаковать все .upk из папки в ./packages, назвав папки по <appId>-<version>
python3 tools/upk_extract.py /путь/к/папке/с/upk ./packages

# собрать .upk обратно из распакованной папки
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

Pour chaque paquet, il est créé :

```
packages/<appId>-<version>/
├── contents/          # дерево приложения (config.json, sbin, www, init.d, ...)
├── icon.png           # иконка приложения
└── _package_meta/     # подписи и публичные ключи из контейнера
```

Les fichiers `.upk` eux-mêmes sont renommés en `<appId>-<version>.upk`.

## Catalogue des applications

19 applications officielles UGOS (toutes en `amd64`, natives). Le tableau complet avec versions,
catégories et descriptions se trouve dans [`catalog/catalog.md`](catalog/catalog.md).
La variante lisible par machine est [`catalog/catalog.json`](catalog/catalog.json).

| App ID | Application | Version |
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

## Format `.upk`

En bref : conteneur textuel `UGREEN-PKG-V2-FORMAT` avec des champs `clé:longueur:valeur`,
à l'intérieur — une icône, des signatures cryptographiques et la charge utile `ugb`
(**gzip → tar → `<appId>.ugb` → xz → tar →** arbre de l'application).
L'analyse détaillée se trouve dans [`docs/fr/FORMAT.md`](docs/fr/FORMAT.md).

## Releases (téléchargements)

Les paquets d'installation d'origine des applications sont publiés comme assets de release :

- **Page des releases :** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **Release `packages-v1`** (19 fichiers `.upk`, ~1,2 Go) : <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

Télécharger tous les paquets via GitHub CLI :

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## Documentation

- [`docs/fr/FORMAT.md`](docs/fr/FORMAT.md) — structure du conteneur `.upk` octet par octet.
- [`docs/fr/EXTRACTION.md`](docs/fr/EXTRACTION.md) — comment fonctionne l'outil de déballage et comment l'utiliser.
- [`docs/fr/REPACK.md`](docs/fr/REPACK.md) — empaquetage inverse au format `.upk`.

## Licence

Le code de l'outil et la documentation sont sous [MIT](LICENSE).
Les marques déposées, les applications et leurs binaires appartiennent à UGREEN. Le dépôt
est destiné à des fins éducatives et d'interopérabilité (interoperability).
