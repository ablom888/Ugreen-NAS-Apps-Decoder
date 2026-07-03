# Localización propia de aplicaciones UGOS sin volver a firmar

**🌐 Idioma:** [English](../en/LOCALIZATION.md) · [中文](../zh/LOCALIZATION.md) · [हिन्दी](../hi/LOCALIZATION.md) · **Español** · [Français](../fr/LOCALIZATION.md) · [Русский](../LOCALIZATION.md)

La verificación de firma en UGOS se realiza **solo al instalar** el paquete `.upk`
(más detalles en [SIGNING.md](SIGNING.md)). Tras la instalación, la aplicación funciona desde una
carpeta en el disco, por lo que el idioma propio se añade **editando los archivos de la aplicación
instalada** — sin reempaquetar ni volver a firmar. Solo hay que actualizar el manifiesto
de integridad `.check-app` para que pase la verificación `reconcile` en tiempo de ejecución.

Las herramientas (Python 3, sin dependencias) están en [`tools/localization/`](../tools/localization):

- **`ug_localize.py`** — localizar la aplicación, crear una plantilla de configuración regional, aplicar la traducción.
- **`ug_checkapp.py`** — verificar/recalcular `.check-app`.

## Dónde se almacena la localización

```
<app_dir>/
├── config.json            → campo languageList (lista de códigos de idioma)
├── www/locale/<lang>.json     textos de la interfaz web
├── www/locale/<lang>.json.gz  copia comprimida (la que sirve nginx) — la regenera el script
└── i18n/msg.csv               cadenas del servidor (opcional)
```

`<lang>` — código al estilo UGOS: `en-US`, `de-DE`, `ru-RU`, `zh-CN`, etc.

## Inicio rápido (en el propio NAS, como root/admin)

```bash
# 0) copiar tools/localization/ al NAS (ambos .py juntos)

# 1) localizar la carpeta de la aplicación instalada por appId
python3 ug_localize.py find com.ugreen.cameramgr

# 2) ver las configuraciones regionales y los idiomas actuales
python3 ug_localize.py list com.ugreen.cameramgr

# 3) crear una plantilla para un nuevo idioma a partir de la configuración regional inglesa
python3 ug_localize.py scaffold com.ugreen.cameramgr ru-RU --from en-US

# 4) editar los valores (¡no cambiar las claves!) en www/locale/ru-RU.json
#    con cualquier editor directamente en el NAS

# 5) aplicar: genera el .gz, añade ru-RU a languageList,
#    actualiza .check-app y (opc.) reinicia el servicio
python3 ug_localize.py apply com.ugreen.cameramgr ru-RU \
        <app_dir>/www/locale/ru-RU.json --restart
```

En lugar del `appId` puedes indicar en cualquier comando la ruta a la carpeta de la aplicación directamente
(si la búsqueda automática no la encuentra — por ejemplo, un volumen no estándar).

## Verificación y reversión

```bash
# verificar la integridad (todos los md5 de .check-app)
python3 ug_checkapp.py verify <app_dir>

# apply crea un respaldo del archivo de configuración regional anterior al lado: <lang>.json.bak
# reversión: devolver el .bak a su lugar y actualizar el manifiesto de nuevo
mv <app_dir>/www/locale/ru-RU.json.bak <app_dir>/www/locale/ru-RU.json
python3 ug_checkapp.py refresh <app_dir> <app_dir>/www/locale/ru-RU.json
```

## Qué hace exactamente `apply`

1. Comprueba que el archivo de traducción sea un JSON válido.
2. Lo coloca en `www/locale/<lang>.json` (o finaliza el ya editado),
   crea un respaldo `.bak` si el archivo existía.
3. Genera `www/locale/<lang>.json.gz` (para el `gzip_static` de nginx).
4. Añade `<lang>` a `config.json → languageList`.
5. Recalcula `.check-app`: actualiza los md5 de los archivos modificados (incluido
   `config.json`) y registra los nuevos archivos de configuración regional. No toca los archivos de `config/` —
   ya en el original están excluidos del manifiesto.
6. Con la opción `--restart` reinicia el servicio de la aplicación (`serviceName` de config.json).

## Notas importantes

- **Edita solo los valores de las traducciones, no las claves** en `<lang>.json` — las claves deben
  coincidir con la configuración regional base, de lo contrario la interfaz mostrará cadenas vacías.
- Los cambios sobreviven al reinicio, pero **pueden sobrescribirse al actualizar
  la aplicación** (la reinstalación coloca los archivos originales). Tras la actualización,
  vuelve a aplicar la localización.
- Todo esto son operaciones en **tu** dispositivo. La firma del proveedor no se falsifica ni se
  elude durante la instalación; solo complementamos la aplicación ya instalada y
  mantenemos su manifiesto de integridad local en un estado coherente.
- Se necesita acceso root/admin al sistema de archivos del NAS (normalmente por SSH).
