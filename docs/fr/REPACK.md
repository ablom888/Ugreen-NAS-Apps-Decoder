# Empaquetage inverse au format UGREEN `.upk`

**🌐 Langue :** [English](../en/REPACK.md) · [中文](../zh/REPACK.md) · [हिन्दी](../hi/REPACK.md) · [Español](../es/REPACK.md) · **Français** · [Русский](../REPACK.md)

`tools/upk_pack.py` reconstruit un paquet `.upk` (UGREEN-PKG-V2-FORMAT) à partir du dossier
créé par `upk_extract.py`.

## Utilisation

```bash
python3 tools/upk_pack.py <папка-пакета> [выход.upk]
```

- `<папка-пакета>` — dossier du type `<appId>-<version>/` contenant un sous-dossier `contents/`
  (et, de préférence, `icon.png` + `_package_meta/`).
- `[выход.upk]` — chemin du résultat (par défaut `<папка>.repacked.upk` à côté).

Exemple :

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## Comment le conteneur est assemblé

Les couches sont construites dans l'ordre inverse du déballage (voir [FORMAT.md](FORMAT.md)) :

```
inner  = xz( tar(GNU)  [ contents/ без install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + поля key:len:value
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- L'archive interne est un GNU tar, compressé en xz (CHECK_CRC64, preset 9|EXTREME).
- Le payload externe est un tar, compressé en gzip (niveau 9).
- Les champs du conteneur sont écrits dans un ordre fixe ; `ico` est pris depuis `icon.png`,
  les signatures/clés/`obj2` depuis `_package_meta/`.

## Vérification round-trip

Empaquetage → déballage préserve intégralement l'arbre de l'application :

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # различий нет
```

Vérifié : `config.json`, la liste des fichiers et le **contenu octet par octet de tous les fichiers**
de l'arbre correspondent à l'original.

## Limitation : les signatures

Les champs `filesig` / `usersig` / `midsig` sont des signatures RSA du fournisseur, créées avec ses
clés **privées**, qui ne sont pas présentes dans le paquet. Par conséquent, il est impossible de
reconstruire une signature valide. `upk_pack.py` **réutilise** les signatures, les clés publiques et
`obj2` conservés dans `_package_meta/`.

Conséquence : lors de la recompression du payload, son hachage et sa signature cessent de correspondre au
contenu, c'est pourquoi un tel paquet **ne passe pas nécessairement la vérification d'intégrité
d'UGOS lors de l'installation**. L'outil est destiné à l'étude du format, à la modification
et à la reconstruction de l'arbre, et non au contournement de la vérification de signature.
