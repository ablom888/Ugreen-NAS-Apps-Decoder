# Déballage des paquets UGREEN `.upk`

**🌐 Langue :** [English](../en/EXTRACTION.md) · [中文](../zh/EXTRACTION.md) · [हिन्दी](../hi/EXTRACTION.md) · [Español](../es/EXTRACTION.md) · **Français** · [Русский](../EXTRACTION.md)

## Prérequis

- Python 3.8+ (uniquement la bibliothèque standard : `gzip`, `lzma`, `bz2`, `tarfile`).
- Aucun utilitaire externe n'est nécessaire.

## Utilisation

```bash
python3 tools/upk_extract.py <папка-с-upk> [папка-вывода]
```

- `<папка-с-upk>` — répertoire où se trouvent les fichiers `*.upk`.
- `[папка-вывода]` — où déballer (par défaut `<папка-с-upk>/packages`).

Exemple :

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## Ce que fait le script

Pour chaque `*.upk` :

1. **Analyse le conteneur externe** `UGREEN-PKG-V2-FORMAT` en champs `clé:longueur:valeur`
   (voir [FORMAT.md](FORMAT.md)).
2. Prend la charge utile `ugb` et **retire récursivement les couches de compression** (gzip → xz),
   en déballant les archives tar.
3. Traite les deux variantes d'empaquetage :
   - `<appId>.ugb` imbriqué unique ;
   - tar multifichier avec les scripts `install.sh`/`uninstall.sh` + `<appId>.ugb`
     (les `*.ugb` imbriqués sont dépliés sur place par la fonction `expand_nested_ugb`).
4. Lit `config.json`, en extrait `appId` et `version.version`.
5. Dispose le résultat :

   ```
   packages/<appId>-<version>/
   ├── contents/          # дерево приложения
   ├── icon.png           # иконка (поле ico)
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. **Renomme** le `*.upk` source en `<appId>-<version>.upk`.
7. Écrit un `packages/catalog.json` récapitulatif avec toutes les métadonnées.

## Fonctions clés de `upk_extract.py`

| Fonction | Rôle |
|---|---|
| `parse_upk(path)` | Analyse du conteneur externe en dictionnaire de champs |
| `sniff(data)` | Détection du format par les octets magiques |
| `decompress_layers(data)` | Retrait des couches gzip/xz/bzip2 successives |
| `deep_extract(data, dest)` | Déballage récursif jusqu'à l'arbre de l'application |
| `expand_nested_ugb(dest)` | Dépliage des `*.ugb` imbriqués dans l'arbre |
| `find_config(root)` | Recherche du manifeste `config.json` |
| `process(upk, out)` | Cycle complet pour un paquet |

## Remarques

- Seuls les `*.ugb` imbriqués sont dépliés ; les assets ordinaires comme `index.html.gz`
  et `version.json.gz` à l'intérieur de `www/` ne sont **pas** touchés.
- Le script utilise `tarfile.extractall(..., filter="data")` — mode d'extraction
  sûr (Python 3.12+), qui bloque les chemins hors du dossier cible.
- Les signatures de `_package_meta/` ne sont pas vérifiées — elles sont conservées telles quelles pour l'analyse.
  La vérification d'intégrité est effectuée par UGOS lui-même lors de l'installation.

## Vérification du résultat

```bash
# список приложений с версиями
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# дерево одного пакета
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
