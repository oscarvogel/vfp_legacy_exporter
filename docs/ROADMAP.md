# Roadmap

## Hito 1 - Exportador seguro MVP

Objetivo: exportar archivos VFP legacy a formatos legibles sin modificar originales.

Incluye:

- Estructura base del proyecto.
- `src/export_legacy.prg`.
- Exportación TXT, Markdown y JSON.
- Recorrido recursivo de carpetas.
- Manejo básico de errores.
- Documentación de uso.

## Hito 2 - Índices del sistema exportado

Objetivo: generar una vista general de formularios, clases, reportes, menús y programas.

Incluye:

- Índice de formularios.
- Índice de clases.
- Índice de reportes.
- Índice de programas `.prg`.
- Detección inicial de objetos, métodos y clases base.

## Hito 3 - Análisis asistido por Codex

Objetivo: tener prompts y documentación para analizar cambios legacy con bajo riesgo.

Incluye:

- Prompts para analizar formularios.
- Prompts para analizar clases VCX.
- Prompts para buscar reglas de negocio.
- Prompts para proponer cambios mínimos.
- Checklist de pruebas manuales.

## Hito 4 - Mejoras de extracción

Objetivo: mejorar calidad de salida para sistemas grandes.

Ideas:

- Separar métodos por objeto.
- Detectar referencias a tablas, aliases y reportes.
- Generar mapa de dependencias.
- Exportar logs de errores.
- Permitir filtros por carpeta o extensión.
- Generar resumen por módulo.

## Hito 5 - Uso multi-proyecto

Objetivo: permitir usar la herramienta en varios sistemas VFP sin mezclar información.

Ideas:

- Perfil de exportación por proyecto.
- Carpeta de salida por sistema.
- Plantilla de documentación por cliente/proyecto.
- Guía para sanitizar samples.
- Convención para no subir exportaciones privadas.
