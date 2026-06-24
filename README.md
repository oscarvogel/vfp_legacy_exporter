# vfp_legacy_exporter

Herramienta para exportar proyectos legacy de Visual FoxPro a formatos legibles por humanos e IA/Codex, sin modificar los archivos originales.

## Objetivo

Muchos sistemas Visual FoxPro productivos tienen lógica de negocio dentro de formularios, clases, reportes y menús. Archivos como `.scx`, `.vcx`, `.frx` y `.mnx` son tablas FoxPro con campos de definición visual, propiedades y métodos. Este proyecto busca extraer esa información a formatos seguros y analizables.

## Principios

- No modificar archivos originales del sistema VFP.
- Trabajar siempre sobre una copia del proyecto legacy.
- Exportar a formatos legibles: TXT, Markdown y JSON.
- Facilitar análisis con Codex/IA sin depender del diseñador visual de VFP.
- Priorizar cambios mínimos, trazables y seguros.
- Servir para varios proyectos VFP, no para un único sistema.

## Alcance inicial

- Exportar `.scx/.sct` formularios.
- Exportar `.vcx/.vct` clases.
- Exportar `.frx/.frt` reportes.
- Exportar `.mnx/.mnt` menús.
- Copiar `.prg`, `.h`, `.ini` y archivos de texto relevantes.
- Generar índices y documentación básica del sistema exportado.

## Uso MVP

Ejecutar desde Visual FoxPro 9 sobre una copia del sistema legacy.

### Exportar una carpeta completa

```foxpro
DO src\export_legacy.prg WITH ;
   "ruta\a\copia_sistema", ;
   "ruta\a\salida_exportada"
```

### Exportar un archivo puntual

Sirve para probar un formulario, clase, reporte, menú o PRG específico sin exportar todo el sistema.

```foxpro
DO src\export_legacy.prg WITH ;
   "ruta\a\copia_sistema\forms\pedido.scx", ;
   "ruta\a\salida_pedido"
```

Extensiones soportadas para archivo puntual:

```text
.scx .vcx .frx .mnx .prg .h .ini .txt
```

La carpeta destino queda con esta estructura:

```text
salida_exportada/
├─ json/
├─ md/
├─ txt/
└─ export_errors.log
```

### Generar índices

Una vez generada la exportación, se puede crear una vista resumida del sistema:

```foxpro
DO src\generate_indexes.prg WITH "ruta\a\salida_exportada"
```

Esto crea:

```text
salida_exportada/
└─ index/
   ├─ INDICE_GENERAL.md
   ├─ INDICE_FORMULARIOS.md
   ├─ INDICE_CLASES.md
   ├─ INDICE_REPORTES.md
   ├─ INDICE_MENUS.md
   └─ INDICE_PROGRAMAS.md
```

Los índices se generan a partir de los Markdown exportados y ayudan a ubicar rápidamente formularios, clases, métodos, objetos y clases base.

Notas:

- La carpeta destino puede estar fuera del proyecto VFP y es lo recomendado.
- Si la carpeta destino queda dentro del origen, el exportador la omite para evitar recursión.
- Las exportaciones reales no deben subirse a este repositorio público.
- Los archivos `.sct`, `.vct`, `.frt` y `.mnt` se leen indirectamente cuando Visual FoxPro abre su contenedor principal `.scx`, `.vcx`, `.frx` o `.mnx`.

## Flujo recomendado

```text
Sistema VFP original
   ↓
Copia de trabajo
   ↓
Exportador seguro
   ↓
TXT / MD / JSON
   ↓
Índices Markdown
   ↓
Análisis con Codex/IA
   ↓
Propuesta de cambio mínimo
   ↓
Aplicación manual o script VFP controlado
   ↓
Validación en Visual FoxPro
```

## Estructura esperada

```text
vfp_legacy_exporter/
├─ src/
│  ├─ export_legacy.prg
│  └─ generate_indexes.prg
├─ docs/
│  ├─ ROADMAP.md
│  ├─ FORMATO_EXPORTACION.md
│  ├─ CHECKLIST_CAMBIO_VFP.md
│  └─ PROMPTS_CODEX_VFP.md
├─ samples/
│  └─ README.md
├─ exported/
│  └─ .gitkeep
├─ AGENTS.md
├─ VALIDATION.md
└─ PR_CHECKLIST.md
```

## Estado

MVP inicial disponible. El exportador permite generar Markdown/JSON/TXT desde archivos o carpetas VFP legacy, y el generador de índices permite crear una vista resumida del sistema exportado.
