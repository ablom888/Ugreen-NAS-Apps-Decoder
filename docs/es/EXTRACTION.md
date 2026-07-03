# Descompresión de paquetes UGREEN `.upk`

**🌐 Idioma:** [English](../en/EXTRACTION.md) · [中文](../zh/EXTRACTION.md) · [हिन्दी](../hi/EXTRACTION.md) · **Español** · [Français](../fr/EXTRACTION.md) · [Русский](../EXTRACTION.md)

## Requisitos

- Python 3.8+ (solo la biblioteca estándar: `gzip`, `lzma`, `bz2`, `tarfile`).
- No se necesitan utilidades externas.

## Uso

```bash
python3 tools/upk_extract.py <carpeta-con-upk> [carpeta-de-salida]
```

- `<carpeta-con-upk>` — directorio donde están los archivos `*.upk`.
- `[carpeta-de-salida]` — dónde descomprimir (por defecto `<carpeta-con-upk>/packages`).

Ejemplo:

```bash
python3 tools/upk_extract.py ~/Downloads/ugreen ./packages
```

## Qué hace el script

Para cada `*.upk`:

1. **Analiza el contenedor externo** `UGREEN-PKG-V2-FORMAT` en campos `clave:longitud:valor`
   (ver [FORMAT.md](FORMAT.md)).
2. Toma la carga útil `ugb` y **retira las capas de compresión de forma recursiva** (gzip → xz),
   descomprimiendo los archivos tar.
3. Procesa ambas variantes de empaquetado:
   - un único `<appId>.ugb` anidado;
   - un tar multiarchivo con los scripts `install.sh`/`uninstall.sh` + `<appId>.ugb`
     (los `*.ugb` anidados se despliegan en su sitio con la función `expand_nested_ugb`).
4. Lee `config.json`, toma `appId` y `version.version`.
5. Distribuye el resultado:

   ```
   packages/<appId>-<version>/
   ├── contents/          # árbol de la aplicación
   ├── icon.png           # icono (campo ico)
   └── _package_meta/     # filesig, usersig, midsig, userpub, midpub, obj2
   ```

6. **Renombra** el `*.upk` original a `<appId>-<version>.upk`.
7. Escribe un `packages/catalog.json` consolidado con todos los metadatos.

## Funciones clave de `upk_extract.py`

| Función | Propósito |
|---|---|
| `parse_upk(path)` | Análisis del contenedor externo en un diccionario de campos |
| `sniff(data)` | Detección del formato por los bytes mágicos |
| `decompress_layers(data)` | Retirada de las capas consecutivas gzip/xz/bzip2 |
| `deep_extract(data, dest)` | Descompresión recursiva hasta el árbol de la aplicación |
| `expand_nested_ugb(dest)` | Despliegue de los `*.ugb` anidados dentro del árbol |
| `find_config(root)` | Búsqueda del manifiesto `config.json` |
| `process(upk, out)` | Ciclo completo para un solo paquete |

## Observaciones

- Solo se despliegan los `*.ugb` anidados; los assets normales como `index.html.gz`
  y `version.json.gz` dentro de `www/` **no** se tocan.
- El script usa `tarfile.extractall(..., filter="data")` — modo de extracción seguro
  (Python 3.12+), que bloquea las rutas fuera de la carpeta de destino.
- Las firmas de `_package_meta/` no se verifican — se guardan tal cual para el análisis.
  La verificación de integridad la realiza el propio UGOS durante la instalación.

## Comprobación del resultado

```bash
# lista de aplicaciones con versiones
python3 -c "import json;[print(x['appId'],x.get('version')) for x in json.load(open('packages/catalog.json'))]"

# árbol de un paquete
find packages/com.ugreen.cameramgr-1.0.0.0677/contents -maxdepth 2
```
