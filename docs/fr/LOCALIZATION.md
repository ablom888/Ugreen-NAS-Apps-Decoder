# Localisation personnalisée des applications UGOS sans re-signature

**🌐 Langue :** [English](../en/LOCALIZATION.md) · [中文](../zh/LOCALIZATION.md) · [हिन्दी](../hi/LOCALIZATION.md) · [Español](../es/LOCALIZATION.md) · **Français** · [Русский](../LOCALIZATION.md)

La vérification de signature dans UGOS n'a lieu **qu'à l'installation** du paquet `.upk`
(plus de détails — [SIGNING.md](SIGNING.md)). Après l'installation, l'application fonctionne depuis un
dossier sur le disque, on ajoute donc sa propre langue en **modifiant les fichiers de l'application
installée** — sans réempaquetage ni re-signature. Il suffit de mettre à jour le manifeste
d'intégrité `.check-app` pour passer la vérification `reconcile` à l'exécution.

Les outils (Python 3, sans dépendances) — dans [`tools/localization/`](../tools/localization):

- **`ug_localize.py`** — trouver l'application, créer une ébauche de locale, appliquer la traduction.
- **`ug_checkapp.py`** — vérifier/recalculer `.check-app`.

## Où est stockée la localisation

```
<app_dir>/
├── config.json            → champ languageList (liste des codes de langue)
├── www/locale/<lang>.json     textes de l'interface web
├── www/locale/<lang>.json.gz  copie compressée (servie par nginx) — régénérée par le script
└── i18n/msg.csv               chaînes côté serveur (optionnel)
```

`<lang>` — code au style UGOS : `en-US`, `de-DE`, `ru-RU`, `zh-CN`, etc.

## Démarrage rapide (sur le NAS lui-même, en root/admin)

```bash
# 0) скопировать tools/localization/ на NAS (оба .py рядом)

# 1) найти папку установленного приложения по appId
python3 ug_localize.py find com.ugreen.cameramgr

# 2) посмотреть текущие локали и языки
python3 ug_localize.py list com.ugreen.cameramgr

# 3) создать заготовку для нового языка из английской локали
python3 ug_localize.py scaffold com.ugreen.cameramgr ru-RU --from en-US

# 4) отредактировать значения (ключи не меняем!) в www/locale/ru-RU.json
#    любым редактором прямо на NAS

# 5) применить: генерирует .gz, добавляет ru-RU в languageList,
#    обновляет .check-app и (опц.) перезапускает сервис
python3 ug_localize.py apply com.ugreen.cameramgr ru-RU \
        <app_dir>/www/locale/ru-RU.json --restart
```

À la place de `appId`, on peut indiquer directement dans n'importe quelle commande le chemin du dossier de l'application
(si l'auto-détection ne le trouve pas — par exemple, un volume non standard).

## Vérification et retour en arrière

```bash
# проверить целостность (все md5 из .check-app)
python3 ug_checkapp.py verify <app_dir>

# apply делает бэкап предыдущего файла локали рядом: <lang>.json.bak
# откат: вернуть .bak на место и снова обновить манифест
mv <app_dir>/www/locale/ru-RU.json.bak <app_dir>/www/locale/ru-RU.json
python3 ug_checkapp.py refresh <app_dir> <app_dir>/www/locale/ru-RU.json
```

## Ce que fait exactement `apply`

1. Vérifie que le fichier de traduction est un JSON valide.
2. Le place dans `www/locale/<lang>.json` (ou finalise celui déjà édité),
   fait une sauvegarde `.bak` si le fichier existait.
3. Génère `www/locale/<lang>.json.gz` (pour le `gzip_static` de nginx).
4. Ajoute `<lang>` dans `config.json → languageList`.
5. Recalcule `.check-app` : met à jour les md5 des fichiers modifiés (y compris
   `config.json`) et enregistre les nouveaux fichiers de locale. Ne touche pas aux fichiers de `config/` —
   ils sont déjà exclus du manifeste dans l'original.
6. Avec le drapeau `--restart`, redémarre le service de l'application (`serviceName` depuis config.json).

## Remarques importantes

- **Ne modifiez que les valeurs des traductions, pas les clés** dans `<lang>.json` — les clés doivent
  correspondre à la locale de base, sinon l'interface affichera des chaînes vides.
- Les modifications survivent à un redémarrage, mais **peuvent être écrasées lors d'une mise à jour
  de l'application** (la réinstallation remet les fichiers d'origine). Après une mise à jour,
  appliquez de nouveau la localisation.
- Tout ceci concerne des opérations sur **votre** appareil. La signature du fournisseur n'est ni falsifiée ni
  contournée lors de l'installation ; nous ne faisons que compléter l'application déjà installée et
  maintenir son manifeste d'intégrité local dans un état cohérent.
- Un accès root/admin au système de fichiers du NAS est nécessaire (généralement via SSH).
