# Checklist para cambios en sistemas VFP legacy

Usar este checklist cuando el exportador se utilice para analizar o preparar modificaciones en un sistema real.

## Antes de analizar

- [ ] Identificar sistema/proyecto.
- [ ] Trabajar sobre copia, no producción.
- [ ] Identificar módulo o pantalla afectada.
- [ ] Exportar formularios/clases/reportes relacionados.
- [ ] Exportar PRG relacionados.
- [ ] Verificar que la exportación no contiene datos sensibles antes de compartirla.

## Análisis con Codex/IA

Pedir siempre:

- [ ] Dónde está implementada la lógica actual.
- [ ] Qué eventos/métodos participan.
- [ ] Qué tablas, aliases o campos se mencionan.
- [ ] Qué clases heredadas intervienen.
- [ ] Qué reportes o procesos externos se llaman.
- [ ] Riesgos de modificar esa zona.
- [ ] Cambio mínimo recomendado.
- [ ] Pruebas manuales necesarias.

## Antes de tocar VFP

- [ ] Backup completo del proyecto.
- [ ] Backup de datos si corresponde.
- [ ] Anotar archivos a modificar.
- [ ] Anotar método/evento exacto a tocar.
- [ ] Evitar tocar clases base salvo justificación.
- [ ] Evitar cambiar layout si no es necesario.

## Después del cambio

- [ ] Abrir formulario/clase en Visual FoxPro.
- [ ] Compilar si aplica.
- [ ] Ejecutar flujo principal.
- [ ] Ejecutar casos de error.
- [ ] Probar impresión/reportes relacionados.
- [ ] Verificar que no se rompieron pantallas dependientes.
- [ ] Documentar cambio aplicado.

## Criterio de cambio seguro

Un cambio es seguro cuando:

- es mínimo;
- está localizado;
- tiene rollback claro;
- fue probado manualmente;
- no modifica datos históricos sin validación;
- no cambia comportamiento compartido sin revisión.
