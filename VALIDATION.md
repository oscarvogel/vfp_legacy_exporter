# VALIDATION.md

Validaciones del proyecto.

## Validación manual del MVP

Ejecutar siempre sobre una copia del sistema VFP, nunca sobre producción directamente.

```foxpro
DO src\export_legacy.prg WITH "C:\COPIA_SISTEMA_VFP", "C:\COPIA_SISTEMA_VFP_EXPORTADO"
```

Verificar:

- Se crean carpetas de salida `json`, `md` y `txt`.
- Se procesan archivos `.scx`, `.vcx`, `.frx` y `.mnx`.
- Se copian archivos `.prg`, `.h`, `.ini` y `.txt` relevantes.
- La exportación no modifica archivos originales.
- Los errores de un archivo quedan registrados sin cortar toda la ejecución.
- En formularios aparecen campos como `objname`, `class`, `baseclass`, `parent`, `properties` y `methods` cuando existen.
- El JSON generado puede abrirse con un validador JSON.
- El Markdown generado puede leerse claramente.

## Validación de seguridad

Antes de subir exportaciones o samples:

- Confirmar que no contienen CUIT, claves, rutas sensibles, nombres reales de clientes o datos comerciales privados.
- Confirmar que los archivos en `samples/` son ficticios o sanitizados.
- Confirmar que no se versionan exportaciones completas de clientes.

## Validación de cambios de lógica VFP

Cuando una issue proponga cambios sobre un sistema VFP real, la validación debe incluir:

- Formulario abre correctamente en Visual FoxPro.
- El caso principal funciona.
- El caso de error esperado funciona.
- No se rompe impresión/reportes asociados.
- No se modifica layout salvo que la issue lo pida.
- Se documenta el cambio mínimo aplicado.
