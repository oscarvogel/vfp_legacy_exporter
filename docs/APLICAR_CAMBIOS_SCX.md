# Aplicar cambios seguros en SCX/SCT

Esta guia describe el aplicador `src/apply_scx_changes.prg`, pensado para preparar cambios controlados sobre copias de formularios Visual FoxPro. No debe ejecutarse sobre produccion.

## Regla principal

No parchear `.SCX/.SCT` como texto bruto. El aplicador abre el `.SCX` como tabla Visual FoxPro, valida que exista su `.SCT` par y crea backup antes de modificar.

Ruta bloqueada explicitamente:

```text
X:\FASA\FORMS\INGRESO COMPROBANTES.SCX
```

## Caso soportado

Modo inicial:

```text
PREPARE_INGRESO_COMPROBANTES
```

Este modo esta acotado al primer loop del caso `INGRESO COMPROBANTES`.

## Ejecutar desde Visual FoxPro

Desde Visual FoxPro 9, parado en la raiz del repo:

```foxpro
DO src\apply_scx_changes.prg WITH ;
   "X:\vfp_legacy_exporter\work\fasa_ingreso_comprobantes_precarga\INGRESO COMPROBANTES.SCX", ;
   "PREPARE_INGRESO_COMPROBANTES"
```

Usar solamente una copia sandbox. No usar la ruta productiva `X:\FASA\FORMS\INGRESO COMPROBANTES.SCX`.

## Que automatiza

- Verifica que el archivo indicado sea `.SCX`.
- Verifica que exista el `.SCT` par.
- Rechaza la ruta productiva conocida del formulario.
- Crea backup de `.SCX` y `.SCT` en `_scx_backups\...`.
- Abre el `.SCX` como tabla VFP con `USE ... SHARED`.
- Busca el registro del formulario por `baseclass`/`class`.
- Agrega, sin duplicar, el metodo no visual `codex_issue10_precarga_manual` en el memo `methods`.
- Genera al lado del formulario:
  - `INGRESO COMPROBANTES_codex_click_manual.prg`
  - `INGRESO COMPROBANTES_codex_apply_plan.md`

## Que queda manual

El aplicador no crea botones visuales ni modifica layout. Para este loop, agregar el boton desde el diseñador VFP es mas seguro que fabricar registros visuales en la tabla SCX.

Despues de ejecutar el aplicador:

```foxpro
MODIFY FORM "X:\vfp_legacy_exporter\work\fasa_ingreso_comprobantes_precarga\INGRESO COMPROBANTES.SCX"
```

Pasos manuales:

1. Abrir la copia sandbox con `MODIFY FORM`.
2. Confirmar que el formulario abre correctamente.
3. Agregar el boton visual desde el diseñador.
4. Pegar en el evento `Click` el contenido de `INGRESO COMPROBANTES_codex_click_manual.prg`.
5. Guardar la copia sandbox.
6. Ejecutar el flujo manual del formulario.

## Rollback

Restaurar ambos archivos desde la carpeta de backup creada por el aplicador:

```text
_scx_backups\<formulario>_<timestamp>\
```

Restaurar siempre el par completo `.SCX/.SCT`.

## Checklist de prueba

- [ ] Ejecutar solamente contra `X:\vfp_legacy_exporter\work\fasa_ingreso_comprobantes_precarga\INGRESO COMPROBANTES.SCX`.
- [ ] Confirmar que no se modifico `X:\FASA\FORMS\INGRESO COMPROBANTES.SCX`.
- [ ] Confirmar que se creo backup de `.SCX` y `.SCT`.
- [ ] Confirmar que el aplicador no duplica el metodo si se ejecuta dos veces.
- [ ] Abrir la copia con `MODIFY FORM`.
- [ ] Agregar boton manual y pegar el codigo `_click` generado.
- [ ] Guardar el formulario sandbox.
- [ ] Ejecutar el flujo principal de ingreso de comprobantes.
- [ ] Probar el caso de error esperado.
- [ ] No pasar el PR a ready hasta completar la validacion manual sobre sandbox.

## Riesgos

- Visual FoxPro puede rechazar formularios si se modifican registros visuales incompletos. Por eso este loop no agrega el boton automaticamente.
- El metodo agregado es un punto de preparacion; la logica real de pre-carga debe conectarse recien despues de validar el sandbox.
- Si `MODIFY FORM` no abre la copia, detener el loop y restaurar backup antes de seguir.
