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

## Preparar sandbox compatible con classloc

El formulario `INGRESO COMPROBANTES.SCX` usa `classloc` relativos como `..\libs\generales.vcx`. Por eso no alcanza con copiar el `.SCX/.SCT` a una carpeta plana: Visual FoxPro necesita que el sandbox respete la estructura relativa.

Sandbox recomendado:

```text
X:\vfp_legacy_exporter\work\fasa_sandbox\
├─ forms\
│  ├─ INGRESO COMPROBANTES.SCX
│  └─ INGRESO COMPROBANTES.SCT
├─ libs\
│  ├─ generales.vcx
│  ├─ generales.vct
│  ├─ coleccion.vcx
│  ├─ coleccion.vct
│  ├─ botones.vcx
│  ├─ botones.vct
│  ├─ fasa.vcx
│  ├─ fasa.vct
│  ├─ lookup.vcx
│  ├─ lookup.vct
│  ├─ validaciones.vcx
│  └─ validaciones.vct
├─ include\
│  ├─ def.h
│  └─ tastrade.h
└─ graphics\
```

Preparacion manual minima:

1. Crear `work\fasa_sandbox\forms`.
2. Crear `work\fasa_sandbox\libs`.
3. Crear `work\fasa_sandbox\include`.
4. Crear `work\fasa_sandbox\graphics`.
5. Copiar `INGRESO COMPROBANTES.SCX` y `INGRESO COMPROBANTES.SCT` a `forms`.
6. Copiar las librerias `.VCX/.VCT` requeridas a `libs`.
7. Copiar los `.H` requeridos a `include`.
8. Copiar a `graphics` solo archivos necesarios si `MODIFY FORM` reporta iconos o imagenes faltantes. La iconografia puede faltar sin invalidar el objetivo principal si las clases resuelven.

Helper PowerShell opcional:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\prepare_fasa_sandbox.ps1
```

El helper copia solo la lista minima documentada desde `X:\FASA` hacia `work\fasa_sandbox`. No borra el sandbox y no sobreescribe archivos existentes salvo que se use `-Force`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\prepare_fasa_sandbox.ps1 -Force
```

## Ejecutar desde Visual FoxPro

Desde Visual FoxPro 9, parado en la raiz del repo:

```foxpro
DO src\apply_scx_changes.prg WITH ;
   "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX", ;
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
MODIFY FORM "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX"
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

- [ ] Preparar `X:\vfp_legacy_exporter\work\fasa_sandbox` con `forms`, `libs`, `include` y `graphics`.
- [ ] Ejecutar solamente contra `X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX`.
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
