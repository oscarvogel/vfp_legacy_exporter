# PR_CHECKLIST.md

Checklist para pull requests.

## Alcance

- [ ] La PR resuelve una issue concreta.
- [ ] No mezcla exportador, documentación y análisis de negocio sin necesidad.
- [ ] No agrega archivos reales de clientes.
- [ ] No modifica originales VFP reales.

## Código

- [ ] Mantiene compatibilidad con Visual FoxPro 9.
- [ ] Maneja errores de archivo individual sin cortar toda la exportación.
- [ ] No requiere rutas absolutas fijas.
- [ ] Permite carpeta origen y carpeta destino como parámetros.
- [ ] No sobrescribe datos originales.

## Salidas

- [ ] Genera TXT legible.
- [ ] Genera Markdown legible.
- [ ] Genera JSON válido.
- [ ] Registra archivos no exportables o errores.

## Documentación

- [ ] Actualiza README o docs si cambió el uso.
- [ ] Actualiza VALIDATION.md si cambió la forma de validar.
- [ ] Agrega notas de limitaciones conocidas.

## Validación

- [ ] Probado sobre carpeta sample o copia local.
- [ ] Verificado que los originales no fueron modificados.
- [ ] Verificado que no se subieron datos sensibles.
