# Aplicar cambios seguros en SCX/SCT

Esta guia describe el aplicador `src/apply_scx_changes.prg`, pensado para preparar cambios controlados sobre copias de formularios Visual FoxPro. No debe ejecutarse sobre produccion.

## Regla principal

No parchear `.SCX/.SCT` como texto bruto. El modo default es `sidecar-only`: el script no escribe en el campo `methods`, no reemplaza `Aceptar1.Click`, no modifica `properties` ni `reserved3`, y no guarda el `.SCX/.SCT`.

Visual FoxPro Designer es quien debe guardar el cambio manualmente despues de pegar cada bloque.

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

Backup opcional explicito:

```foxpro
DO src\apply_scx_changes.prg WITH ;
   "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX", ;
   "PREPARE_INGRESO_COMPROBANTES", ;
   "BACKUP"
```

Usar solamente una copia sandbox. No usar la ruta productiva `X:\FASA\FORMS\INGRESO COMPROBANTES.SCX`.

## Que automatiza

- Verifica que el archivo indicado sea `.SCX`.
- Verifica que exista el `.SCT` par.
- Rechaza la ruta productiva conocida del formulario.
- Si se pasa `"BACKUP"`, crea backup de `.SCX` y `.SCT` en `_scx_backups\...`.
- Abre el `.SCX` como tabla VFP con `USE ... SHARED ... NOUPDATE`.
- Localiza registros relevantes para informar el plan manual.
- Genera archivos limpios `.txt` / `.prg` para pegar desde VFP Designer.

No automatiza cambios dentro del `.SCX/.SCT`.

## Kit generado

- `INGRESO COMPROBANTES_codex_01_propiedades_formset.txt`
- `INGRESO COMPROBANTES_codex_02_reserved3.txt`
- `INGRESO COMPROBANTES_codex_03_metodos_formset.prg`
- `INGRESO COMPROBANTES_codex_04_aceptar1_click.prg`
- `INGRESO COMPROBANTES_codex_05_btnBuscaPrecarga_click.prg`
- `INGRESO COMPROBANTES_codex_06_validatablas.txt`
- `INGRESO COMPROBANTES_codex_PLAN_MANUAL.md`

El archivo `01_propiedades_formset.txt` indica agregar manualmente al Formset:

```text
nIdPrecarga = 0
lDesdePrecarga = .F.
```

El archivo `02_reserved3.txt` lista:

```text
nidprecarga
ldesdeprecarga
*safec
*safesqlc
*safen
*grabaprecarga
*buscaprecargaproveedor
*cargaprecarga
*marcaprecargacargada
```

El archivo `03_metodos_formset.prg` incluye:

- `SafeC`
- `SafeSQLC`
- `SafeN`
- `GrabaPrecarga`
- `BuscaPrecargaProveedor`
- `CargaPrecarga`
- `MarcaPrecargaCargada`

El archivo `04_aceptar1_click.prg` contiene el cuerpo final de `Aceptar1.Click` con menu:

- Salir
- Grabar ingreso a stock
- Pre-cargar factura
- Cancelar

Ese bloque no abre `Forms\bajapedidos`, guarda `lcProveedorBaja` antes de los `Release`, y ejecuta `loForm.Release()` antes de `Thisformset.Release()`.

El archivo `05_btnBuscaPrecarga_click.prg` contiene el click manual:

```foxpro
Local lnId

lnId = Thisformset.BuscaPrecargaProveedor()
If lnId > 0
    Thisformset.CargaPrecarga(lnId)
Endif

Thisform.grdDet.SetFocus()
```

El archivo `06_validatablas.txt` contiene un bloque para pegar al final de `validatablas`, sin declarar `Local lsCad`, usando `goMy.Sql(m.lsCad)` para crear o migrar:

- `codex_ingcomp_pre`
- `codex_ingcomp_pre_det`

## Aplicacion manual

1. Abrir el formulario:

```foxpro
MODIFY FORM "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX"
```

2. Seleccionar el `Formset`.
3. Agregar propiedades desde `INGRESO COMPROBANTES_codex_01_propiedades_formset.txt`:
  - `nIdPrecarga = 0`
  - `lDesdePrecarga = .F.`
4. Agregar metodos del Formset pegando desde `INGRESO COMPROBANTES_codex_03_metodos_formset.prg`.
5. Seleccionar `Aceptar1.Click`.
6. Reemplazar el cuerpo con `INGRESO COMPROBANTES_codex_04_aceptar1_click.prg`.
7. Agregar boton visual en `Ajustador1`:
   - clase: `btnaccdirecto`
   - classloc: `..\libs\botones.vcx`
   - name: `btnBuscaPrecarga`
   - caption: `Buscar pre-carga`
   - ubicacion sugerida: junto a los botones de accion existentes.
8. Pegar click desde `INGRESO COMPROBANTES_codex_05_btnBuscaPrecarga_click.prg`.
9. Ubicar `validatablas` real y pegar al final el bloque `INGRESO COMPROBANTES_codex_06_validatablas.txt`.
10. Guardar.
11. Cerrar y reabrir el formulario para validar.

## Rollback

Si se ejecuto con `"BACKUP"`, restaurar ambos archivos desde la carpeta de backup creada por el generador:

```text
_scx_backups\<formulario>_<timestamp>\
```

Restaurar siempre el par completo `.SCX/.SCT`.

## Checklist de prueba

- [ ] Preparar `X:\vfp_legacy_exporter\work\fasa_sandbox` con `forms`, `libs`, `include` y `graphics`.
- [ ] Ejecutar solamente contra `X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX`.
- [ ] Confirmar que no se modifico `X:\FASA\FORMS\INGRESO COMPROBANTES.SCX`.
- [ ] Confirmar que el generador no modifica `.SCX/.SCT`.
- [ ] Confirmar que se creo backup de `.SCX` y `.SCT` solo si se pidio con `"BACKUP"`.
- [ ] Confirmar que se generaron los siete archivos del kit manual.
- [ ] Abrir la copia con `MODIFY FORM`.
- [ ] Pegar propiedades, metodos, `Aceptar1.Click`, boton y `validatablas` desde los sidecars.
- [ ] Guardar el formulario sandbox.
- [ ] Cerrar y reabrir el formulario.
- [ ] Ejecutar el flujo principal de ingreso de comprobantes.
- [ ] Probar el caso de error esperado.
- [ ] No pasar el PR a ready hasta completar la validacion manual sobre sandbox.

## Riesgos

- Visual FoxPro puede rechazar formularios si se modifican registros visuales incompletos. Por eso este loop no modifica el `.SCX/.SCT` automaticamente.
- Los metodos del kit preparan el flujo de pre-carga, pero la validacion funcional sigue siendo manual porque depende de aliases/tablas disponibles en el sistema VFP.
- Si `MODIFY FORM` no abre la copia, detener el loop y restaurar backup antes de seguir.
