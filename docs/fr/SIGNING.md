# Vérification de signature dans UGOS Pro : comment ça fonctionne et peut-on signer soi-même

**🌐 Langue :** [English](../en/SIGNING.md) · [中文](../zh/SIGNING.md) · [हिन्दी](../hi/SIGNING.md) · [Español](../es/SIGNING.md) · **Français** · [Русский](../SIGNING.md)

L'analyse a été réalisée à partir du firmware `firmware_image-1.16.0.89` (UGOS Pro, Debian 12, amd64).

## Qui vérifie les paquets

- **`/usr/sbin/uginstall`** — l'installateur des paquets `.upk` (binaire Go). C'est lui
  qui analyse le conteneur `UGREEN-PKG-V2-FORMAT`, vérifie les signatures et déploie
  l'arbre de l'application. Chaînes présentes dans le binaire : `systemVerify`, `GetVerifyKey`,
  `verifyData`, `un_support_sign_ver`, `parse_package_error`.
- Cryptographie : **RSA + SHA-256** (dans le binaire — `crypto/rsa`, `crypto/sha256`,
  indices de RSA-PSS). Confirmé par `upk_pack.py` : signatures `filesig/usersig/midsig`.

## Racine de confiance (ce qui est « gravé » dans le firmware)

Les clés **publiques** de confiance se trouvent dans une partition en lecture seule du firmware :

```
/rom/usr/ugreen/etc/rsa/ugreenRoot.pub         # clé racine
/rom/usr/ugreen/etc/rsa/ugreenRootImport.pub   # clé racine pour l'import
/rom/usr/ugreen/etc/rsa/ugreen.pub             # clé de niveau application
```

`uginstall` lit `ugreenRoot.pub` comme ancre de confiance. La partition `/rom` est
`fw.squashfs` (squashfs compressé xz, en lecture seule), elle fait partie du firmware signé.

## Chaîne de signature

La comparaison des clés sur 19 paquets révèle une chaîne à trois niveaux :

```
ugreenRoot (gravée dans /rom, clé privée détenue par UGREEN)
      └── signe la clé intermédiaire du canal  (midpub — IDENTIQUE dans tous les paquets)
                └── signe la clé de build       (userpub — PROPRE à chaque paquet)
                          └── signe le payload  (filesig/usersig)
```

- `midpub` est identique dans tous les paquets → c'est la clé intermédiaire de l'éditeur.
- `userpub` est unique pour chaque paquet → clé d'une build spécifique.
- Le paquet ne contient que les parties publiques (`midpub`, `userpub`) et les signatures.

## Conclusion principale sur « signer soi-même »

**Le firmware ne contient que des clés PUBLIQUES. Les clés privées d'UGREEN n'y sont pas** — et
ne doivent pas y être (sinon ce serait une compromission du fournisseur lui-même). Par conséquent :

| Question | Réponse |
|---|---|
| Extraire la clé privée de signature depuis le NAS ? | **Non** — elle n'y est pas, seulement les `.pub`. |
| Signer un paquet modifié pour un NAS « d'usine » ? | **Non** — il faut la clé privée `ugreenRoot`/`mid`. Falsifier = casser RSA. |
| Signer avec sa propre clé sur son propre appareil ? | Techniquement oui, mais uniquement en remplaçant l'ancre de confiance (voir ci-dessous). Fragile, non recommandé. |

### Pourquoi « sa propre signature » est une mauvaise voie

Pour que le NAS accepte un paquet signé avec votre clé, il faut remplacer
`ugreenRoot.pub` (et les clés associées) par votre clé publique. Mais :

- `/rom` est un squashfs en lecture seule issu d'un firmware **signé** ; le firmware est vérifié
  par un updater séparé `ugupdate`, donc simplement reconstruire le firmware ne fonctionnera pas ;
- remplacer la clé à l'exécution (bind-mount par-dessus `/rom`) ne survivra pas à une mise à jour
  du système et touche des composants système ;
- cela casse la vérification d'authenticité standard de toutes les applications de l'appareil.

## Quand la vérification a-t-elle réellement lieu

- **La signature n'est vérifiée qu'à l'INSTALLATION** du paquet (`uginstall`).
- Après l'installation, seul l'arbre de l'application (`contents/`) reste dans le système de fichiers ;
  le `.upk` lui-même et les signatures n'y sont plus.
- **À l'exécution**, UGOS utilise le mode `reconcile` : il vérifie l'absence de fichiers
  (`reason=files-missing`) et le manifeste d'intégrité **`.check-app`** (JSON
  `chemin → md5`). La signature n'est PAS revérifiée à ce moment-là.

## Conclusion pratique pour la localisation

Puisque la signature n'est vérifiée qu'à l'installation et que l'application fonctionne ensuite depuis un dossier
sur le disque — **on ajoute sa propre localisation par-dessus l'application installée, sans
re-signer**. Il suffit de modifier les fichiers de locale et de mettre à jour `.check-app`
(pour passer le `reconcile` à l'exécution). Scripts prêts à l'emploi et instructions —
dans [LOCALIZATION.md](LOCALIZATION.md).
