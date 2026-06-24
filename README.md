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

Ejecutar desde Visual FoxPro 9 sobre una copia del sistema legacy:

```foxpro
DO C:\vfp_legacy_exporter\src\export_legacy.prg WITH ;
   "C:\COPIA_SISTEMA_VFP", ;
   "D:\VFP_EXPORTS\COPIA_SISTEMA_VFP"
```

La carpeta destino queda con esta estructura:

```text
D:\VFP_EXPORTS\COPIA_SISTEMA_VFP\
├─ json\
├─ md\
├─ txt\
└─ export_errors.log
```

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
│  └─ export_legacy.prg
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

MVP inicial en desarrollo. El primer hito es crear un exportador que pueda ejecutarse desde Visual FoxPro sobre una copia de un sistema legacy.
