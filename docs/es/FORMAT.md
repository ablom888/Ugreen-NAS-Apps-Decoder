# Formato del paquete UGREEN NAS `.upk` (UGREEN-PKG-V2-FORMAT)

**🌐 Idioma:** [English](../en/FORMAT.md) · [中文](../zh/FORMAT.md) · [हिन्दी](../hi/FORMAT.md) · **Español** · [Français](../fr/FORMAT.md) · [Русский](../FORMAT.md)

El paquete de instalación de una aplicación de UGOS Pro **no** es un zip/tar corriente. Es un
contenedor casero de texto y binario con firmas criptográficas y una carga útil multicapa.

## 1. Contenedor externo

El archivo empieza con una firma de 20 bytes:

```
UGREEN-PKG-V2-FORMAT
```

A continuación vienen, uno tras otro, campos de longitud variable en el formato `clave:longitud:valor`, donde
`longitud` es el número decimal de bytes del valor (ASCII) y `valor` son los bytes en bruto:

```
<clave>:<len>:<len bytes del valor><clave>:<len>:<value>...
```

Campos observados (en orden de aparición):

| Clave | Contenido | Codificación |
|---|---|---|
| `filesig` | Firma de la carga útil | base64 |
| `userpub` | Clave pública del usuario (RSA) | base64, cuerpo DER (SubjectPublicKeyInfo) |
| `usersig` | Firma del usuario | base64 |
| `midpub`  | Clave pública del editor/canal (RSA) | base64 |
| `midsig`  | Firma del editor | base64 |
| `ico`     | Icono de la aplicación | PNG en bruto |
| `ugb`     | **Carga útil** (ver §2) | gzip |
| `obj2`    | Manifiesto de hashes de los archivos | cadena hex |

Las firmas y las claves forman un esquema de dos niveles (usuario + editor `mid`) con el que UGOS
verifica la integridad y el origen del paquete antes de instalarlo.

### Pseudocódigo de análisis

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

## 2. Carga útil `ugb`

El campo `ugb` está formado por varias capas anidadas. Se dan dos variantes de empaquetado.

### Variante A — bundle anidado único

```
ugb  =  gzip
         └── tar
              └── <appId>.ugb        (único archivo)
                    =  xz
                        └── tar (GNU)
                             └── árbol de la aplicación (config.json, sbin/, www/, ...)
```

Ejemplo: `com.ugreen.cameramgr`.

### Variante B — bundle multiarchivo con scripts de instalación

```
ugb  =  gzip
         └── tar
              ├── install.sh
              ├── uninstall.sh
              └── <appId>.ugb        (xz → tar → árbol de la aplicación)
```

Ejemplo: `com.ugreen.netdisk`, `com.ugreen.photo` y la mayoría de las aplicaciones de UGOS 1.16.x.

En ambos casos el `<appId>.ugb` interno es un **tar comprimido con xz** (formato GNU,
suma de control CRC64) con la raíz del árbol de la aplicación.

### Firmas de las capas

| Formato | Bytes mágicos |
|---|---|
| gzip | `1f 8b` |
| xz   | `fd 37 7a 58 5a 00` (`\xFD7zXZ\x00`) |
| bzip2| `42 5a 68` (`BZh`) |
| tar (POSIX/ustar) | `ustar` en el offset 257 |

## 3. Árbol de la aplicación

La raíz del archivo interno es el sistema de archivos de la aplicación UGOS:

```
contents/
├── config.json        # manifiesto: appId, version, arch, service, i18n, permisos
├── .check-app         # datos de verificación de la aplicación
├── sbin/              # binarios principales de los servicios (p. ej. cameramgr_serv)
├── bin/               # binarios auxiliares
├── config/            # configuraciones (yaml/toml)
├── init.d/            # units de systemd (*.service) y scripts install/uninstall/pre/stop
├── www/               # interfaz web (SPA: index.html, assets/, locale/)
├── nginx/, syslog/, logrotate/   # configuraciones de servicios
├── i18n/              # traducciones (msg.csv)
└── target/, img/      # recursos
```

### Manifiesto `config.json`

Campos clave:

```jsonc
{
  "appId": "com.ugreen.cameramgr",
  "version": {
    "version": "1.0.0.0677",     // versión del paquete
    "versionNum": 100000677,
    "lowVersion": "1.16.0.0065", // versión mínima de UGOS
    "buildTime": 1779875672
  },
  "arch": "amd64",
  "appType": 1,
  "daemon": true,
  "serviceName": "cameramgr_serv.service",
  "route": "/cameramgr",
  "pkgType": "ugb",              // tipo de paquete: ugb (nativo) o docker
  "category": "category.system.tools",
  "isDockerApp": false,
  "languageList": ["zh-CN","en-US","de-DE", ...],
  "i18n": [ { "langName":"en-US","name":"Surveillance Center","description":"..." } ]
}
```

El nombre de la carpeta al descomprimir se forma como **`<appId>-<version.version>`**, por ejemplo
`com.ugreen.cameramgr-1.0.0.0677`.
