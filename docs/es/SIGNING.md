# Verificación de firma en UGOS Pro: cómo funciona y si es posible firmar por cuenta propia

**🌐 Idioma:** [English](../en/SIGNING.md) · [中文](../zh/SIGNING.md) · [हिन्दी](../hi/SIGNING.md) · **Español** · [Français](../fr/SIGNING.md) · [Русский](../SIGNING.md)

El análisis se realizó sobre el firmware `firmware_image-1.16.0.89` (UGOS Pro, Debian 12, amd64).

## Quién verifica los paquetes

- **`/usr/sbin/uginstall`** — el instalador de paquetes `.upk` (binario Go). Es él quien
  analiza el contenedor `UGREEN-PKG-V2-FORMAT`, verifica las firmas y despliega el
  árbol de la aplicación. Cadenas presentes en el binario: `systemVerify`, `GetVerifyKey`,
  `verifyData`, `un_support_sign_ver`, `parse_package_error`.
- Criptografía: **RSA + SHA-256** (en el binario: `crypto/rsa`, `crypto/sha256`,
  indicios de RSA-PSS). Lo mismo confirma `upk_pack.py`: firmas `filesig/usersig/midsig`.

## Raíz de confianza (lo que está «incrustado» en el firmware)

Las claves **públicas** de confianza se encuentran en una partición de solo lectura del firmware:

```
/rom/usr/ugreen/etc/rsa/ugreenRoot.pub         # clave raíz
/rom/usr/ugreen/etc/rsa/ugreenRootImport.pub   # clave raíz para importación
/rom/usr/ugreen/etc/rsa/ugreen.pub             # clave a nivel de aplicación
```

`uginstall` lee `ugreenRoot.pub` como ancla de confianza. La partición `/rom` es
`fw.squashfs` (squashfs comprimido con xz, solo lectura), y forma parte del firmware firmado.

## Cadena de firma

El cotejo de claves entre 19 paquetes muestra una cadena de tres niveles:

```
ugreenRoot (incrustada en /rom, clave privada en poder de UGREEN)
      └── firma la clave intermedia del canal  (midpub — IGUAL en todos los paquetes)
                └── firma la clave de compilación  (userpub — PROPIA de cada paquete)
                          └── firma el payload  (filesig/usersig)
```

- `midpub` es igual en todos los paquetes → es la clave intermedia del editor.
- `userpub` es única para cada paquete → es la clave de la compilación concreta.
- En el paquete solo se almacenan las partes públicas (`midpub`, `userpub`) y las firmas.

## Conclusión principal sobre «firmar por cuenta propia»

**En el firmware solo hay claves PÚBLICAS. Las claves privadas de UGREEN no están ahí** — y no
deberían estarlo (de lo contrario sería un compromiso del propio proveedor). Por lo tanto:

| Pregunta | Respuesta |
|---|---|
| ¿Extraer la clave privada de firma del NAS? | **No** — no está ahí, solo hay `.pub`. |
| ¿Firmar un paquete modificado para un NAS «de fábrica»? | **No** — se necesita la clave privada `ugreenRoot`/`mid`. Falsificarla = romper RSA. |
| ¿Firmar con tu propia clave en tu propio dispositivo? | Técnicamente sí, pero solo reemplazando el ancla de confianza (ver abajo). Frágil, no recomendado. |

### Por qué la «firma propia» es un mal camino

Para que el NAS acepte un paquete firmado con tu clave, hay que reemplazar
`ugreenRoot.pub` (y las relacionadas) por tu clave pública. Pero:

- `/rom` es un squashfs de solo lectura de un firmware **firmado**; el firmware lo verifica
  un actualizador aparte, `ugupdate`, así que no basta con reempaquetar el firmware;
- la sustitución de la clave en caliente (bind-mount sobre `/rom`) no sobrevive a la
  actualización del sistema y toca componentes del sistema;
- esto rompe la verificación de autenticidad estándar de todas las aplicaciones del dispositivo.

## Cuándo se ejecuta realmente la verificación

- **La firma se verifica solo al INSTALAR** el paquete (`uginstall`).
- Tras la instalación, en el sistema de archivos solo queda el árbol de la aplicación
  (`contents/`); el propio `.upk` y las firmas ya no están ahí.
- **Durante la ejecución**, UGOS usa el modo `reconcile`: comprueba la falta de archivos
  (`reason=files-missing`) y el manifiesto de integridad **`.check-app`** (JSON
  `ruta → md5`). La firma no se vuelve a verificar en ese proceso.

## Conclusión práctica para la localización

Dado que la firma se verifica solo al instalar, y luego la aplicación funciona desde una carpeta
en el disco, **la localización propia se añade sobre la aplicación instalada, sin
volver a firmar**. Basta con editar los archivos de la configuración regional y actualizar `.check-app`
(para que pase el `reconcile` en tiempo de ejecución). Los scripts listos y las instrucciones están
en [LOCALIZATION.md](LOCALIZATION.md).
