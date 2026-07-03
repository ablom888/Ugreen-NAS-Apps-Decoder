# Empaquetado inverso al formato UGREEN `.upk`

**🌐 Idioma:** [English](../en/REPACK.md) · [中文](../zh/REPACK.md) · [हिन्दी](../hi/REPACK.md) · **Español** · [Français](../fr/REPACK.md) · [Русский](../REPACK.md)

`tools/upk_pack.py` reconstruye el paquete `.upk` (UGREEN-PKG-V2-FORMAT) a partir de la carpeta
que creó `upk_extract.py`.

## Uso

```bash
python3 tools/upk_pack.py <carpeta-del-paquete> [salida.upk]
```

- `<carpeta-del-paquete>` — carpeta del tipo `<appId>-<version>/` con la subcarpeta `contents/` dentro
  (y, preferiblemente, `icon.png` + `_package_meta/`).
- `[salida.upk]` — ruta del resultado (por defecto `<carpeta>.repacked.upk` al lado).

Ejemplo:

```bash
python3 tools/upk_pack.py packages/com.ugreen.note-1.0.0.0070 note.upk
```

## Cómo se construye el contenedor

Las capas se construyen en el orden inverso al de la descompresión (ver [FORMAT.md](FORMAT.md)):

```
inner  = xz( tar(GNU)  [ contents/ sin install.sh/uninstall.sh ] )   ->  <appId>.ugb
ugb    = gzip( tar  [ install.sh?, uninstall.sh?, <appId>.ugb ] )
.upk   = "UGREEN-PKG-V2-FORMAT" + campos key:len:value
         (filesig, userpub, usersig, midpub, midsig, ico, ugb, obj2)
```

- El archivo interno es un tar GNU, comprimido con xz (CHECK_CRC64, preset 9|EXTREME).
- El payload externo es un tar, comprimido con gzip (nivel 9).
- Los campos del contenedor se escriben en orden fijo; `ico` se toma de `icon.png`,
  las firmas/claves/`obj2` — de `_package_meta/`.

## Verificación round-trip

Empaquetar → descomprimir conserva por completo el árbol de la aplicación:

```bash
python3 tools/upk_pack.py    packages/com.ugreen.note-1.0.0.0070 /tmp/note.upk
python3 tools/upk_extract.py /tmp/                                /tmp/out
diff -r packages/com.ugreen.note-1.0.0.0070/contents \
        /tmp/out/com.ugreen.note-1.0.0.0070/contents   # sin diferencias
```

Comprobado: `config.json`, la lista de archivos y el **contenido byte a byte de todos los archivos**
del árbol coinciden con el original.

## Limitación: firmas

Los campos `filesig` / `usersig` / `midsig` son firmas RSA del proveedor, creadas con sus
claves **privadas**, que no están en el paquete. Por eso es imposible reconstruir una firma
válida. `upk_pack.py` **reutiliza** las firmas, las claves públicas y el
`obj2` guardados en `_package_meta/`.

Consecuencia: al recomprimir el payload, su hash y su firma dejan de corresponder al
contenido, por lo que ese paquete **no pasa de forma garantizada la verificación de integridad
de UGOS durante la instalación**. La herramienta está destinada a la investigación del formato, la modificación
y la reconstrucción del árbol, y no a eludir la verificación de firmas.
