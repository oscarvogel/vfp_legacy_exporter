# AGENTS.md

Instrucciones para Codex/IA trabajando en este repositorio.

## Propósito del proyecto

Este repositorio contiene herramientas para exportar y analizar sistemas Visual FoxPro legacy. El objetivo principal es permitir análisis seguro de formularios, clases, reportes, menús y programas sin modificar los archivos originales.

## Reglas obligatorias

1. No modificar archivos `.scx`, `.sct`, `.vcx`, `.vct`, `.frx`, `.frt`, `.mnx`, `.mnt`, `.dbf`, `.fpt` o `.dbc` de sistemas reales.
2. No asumir que el sistema VFP puede abrirse visualmente desde este repo.
3. No reestructurar lógica legacy salvo que una issue lo pida explícitamente.
4. Priorizar cambios mínimos y auditables.
5. Documentar riesgos antes de proponer cambios sobre lógica VFP.
6. Mantener compatibilidad con Visual FoxPro 9 mientras no se indique otra versión.
7. No guardar datos sensibles de clientes dentro del repositorio.
8. Los ejemplos en `samples/` deben ser ficticios o sanitizados.

## Flujo de trabajo recomendado

Para cada issue:

1. Leer alcance y restricciones.
2. Cambiar solo archivos relacionados.
3. Actualizar documentación si cambia el formato de salida o el flujo.
4. Ejecutar validaciones manuales o automáticas disponibles.
5. Dejar checklist de prueba.

## Convenciones

- Código Visual FoxPro en `src/`.
- Documentación en `docs/`.
- Prompts reutilizables en `docs/PROMPTS_CODEX_VFP.md`.
- No versionar exportaciones reales de clientes.
- Usar `exported/.gitkeep` solo para conservar la carpeta.

## Criterio de calidad

Una mejora es aceptable si:

- no toca originales;
- genera salida legible;
- funciona sobre carpetas con subdirectorios;
- tolera errores de archivos individuales sin cortar toda la exportación;
- deja claro qué no pudo exportar;
- sirve para analizar varios sistemas VFP diferentes.
