# UGREEN NAS Apps Decoder

**🌐 Idioma:** [English](README.en.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md) · **Español** · [Français](README.fr.md) · [Русский](README.md)

Herramienta y documentación para descomprimir los paquetes de instalación de aplicaciones
de **UGREEN NAS (UGOS Pro)** — archivos con formato `.upk` (`UGREEN-PKG-V2-FORMAT`).

📦 **Los paquetes `.upk` originales están en la sección [Releases](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).**

El repositorio contiene:

- **`tools/upk_extract.py`** — descompresor de paquetes `.upk` sin dependencias externas
  (solo la biblioteca estándar de Python 3).
- **`tools/upk_pack.py`** — empaquetador inverso: reconstruye el `.upk` a partir de una carpeta descomprimida
  (round-trip verificado byte a byte; ver [`docs/REPACK.md`](docs/es/REPACK.md)).
- **`docs/`** — análisis del formato del contenedor y descripción paso a paso de la descompresión/empaquetado.
- **`apps/`** — aplicaciones UGOS descomprimidas (archivos dentro del límite de 100 MB de GitHub;
  los binarios grandes están excluidos — su lista está en [`apps/EXCLUDED.md`](apps/EXCLUDED.md)).
- **`catalog/`** — metadatos de 19 aplicaciones oficiales de UGOS: el manifiesto `config.json`,
  el icono y la lista completa de archivos de cada paquete.

> ⚠️ Todo el contenido de las aplicaciones es software propietario de UGREEN, publicado con fines
> de compatibilidad y análisis. Los `.upk` originales (1.2 GB) están adjuntos a la
> [release `packages-v1`](https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1).
> Los binarios individuales que superan el límite de 100 MB de GitHub
> no se incluyen en `apps/` — su lista está en [`apps/EXCLUDED.md`](apps/EXCLUDED.md);
> se puede reconstruir el conjunto completo descomprimiendo los `.upk` de la release con la herramienta `tools/`.

## Inicio rápido

```bash
# descomprimir todos los .upk de una carpeta en ./packages, nombrando las carpetas como <appId>-<version>
python3 tools/upk_extract.py /ruta/a/la/carpeta/con/upk ./packages

# reconstruir el .upk a partir de una carpeta descomprimida
python3 tools/upk_pack.py ./packages/com.ugreen.note-1.0.0.0070 note.upk
```

Para cada paquete se crea:

```
packages/<appId>-<version>/
├── contents/          # árbol de la aplicación (config.json, sbin, www, init.d, ...)
├── icon.png           # icono de la aplicación
└── _package_meta/     # firmas y claves públicas del contenedor
```

Los propios archivos `.upk` se renombran a `<appId>-<version>.upk`.

## Catálogo de aplicaciones

19 aplicaciones oficiales de UGOS (todas `amd64`, nativas). La tabla completa con versiones,
categorías y descripciones está en [`catalog/catalog.md`](catalog/catalog.md).
La variante legible por máquina es [`catalog/catalog.json`](catalog/catalog.json).

| App ID | Aplicación | Versión |
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

## Formato `.upk`

En resumen: un contenedor de texto `UGREEN-PKG-V2-FORMAT` con campos `clave:longitud:valor`,
y dentro — el icono, las firmas criptográficas y la carga útil `ugb`
(**gzip → tar → `<appId>.ugb` → xz → tar →** árbol de la aplicación).
El análisis detallado está en [`docs/FORMAT.md`](docs/es/FORMAT.md).

## Releases (descargas)

Los paquetes de instalación originales de las aplicaciones están publicados como assets de la release:

- **Página de releases:** <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases>
- **Release `packages-v1`** (19 archivos `.upk`, ~1.2 GB): <https://github.com/ablom888/Ugreen-NAS-Apps-Decoder/releases/tag/packages-v1>

Descargar todos los paquetes con GitHub CLI:

```bash
gh release download packages-v1 --repo ablom888/Ugreen-NAS-Apps-Decoder --pattern '*.upk'
```

## Documentación

- [`docs/FORMAT.md`](docs/es/FORMAT.md) — estructura del contenedor `.upk` byte a byte.
- [`docs/EXTRACTION.md`](docs/es/EXTRACTION.md) — cómo funciona el descompresor y cómo usarlo.
- [`docs/REPACK.md`](docs/es/REPACK.md) — empaquetado inverso al formato `.upk`.
- [`docs/SIGNING.md`](docs/es/SIGNING.md) — cómo funciona la verificación de firma en UGOS Pro y si es posible firmar por cuenta propia.
- [`docs/LOCALIZATION.md`](docs/es/LOCALIZATION.md) — cómo añadir tu propia localización a las aplicaciones sin volver a firmar.

## Licencia

El código de la herramienta y la documentación están bajo [MIT](LICENSE).
Las marcas registradas, las aplicaciones y sus binarios pertenecen a UGREEN. El repositorio
está destinado a fines educativos y de compatibilidad (interoperability).
