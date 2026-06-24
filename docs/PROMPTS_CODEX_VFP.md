# Prompts Codex para Visual FoxPro legacy

## Análisis de formulario

```text
Analizá este formulario Visual FoxPro exportado.

No modifiques archivos originales SCX/SCT.

Necesito entender:
1. objetivo probable del formulario;
2. objetos principales;
3. eventos y métodos importantes;
4. clases heredadas;
5. tablas, aliases o campos mencionados;
6. reportes o programas llamados;
7. riesgos de modificarlo;
8. cambio mínimo recomendado si aplica;
9. pruebas manuales necesarias.

Priorizá explicación clara y cambios pequeños.
```

## Análisis de clase VCX

```text
Analizá esta librería de clases Visual FoxPro exportada.

No propongas cambios todavía.

Identificá:
1. clases definidas;
2. clases base;
3. jerarquías o herencias;
4. métodos compartidos;
5. propiedades relevantes;
6. formularios que podrían depender de estas clases;
7. riesgo de modificar cada clase;
8. zonas que parecen ser infraestructura común.
```

## Búsqueda de regla de negocio

```text
Buscá en estos archivos exportados dónde puede estar implementada esta regla de negocio:

[DESCRIBIR REGLA]

Devolvé:
1. archivos candidatos;
2. objetos/métodos candidatos;
3. evidencia textual;
4. dependencias;
5. qué revisar en Visual FoxPro;
6. riesgos antes de modificar.
```

## Propuesta de cambio mínimo

```text
Necesito modificar este comportamiento:

[DESCRIBIR CAMBIO]

Con base en los archivos exportados, proponé el cambio mínimo seguro.

Restricciones:
- no reestructurar;
- no cambiar nombres públicos;
- no tocar layout salvo necesidad;
- no modificar clases base salvo justificación;
- mantener compatibilidad VFP.

Salida esperada:
1. archivo;
2. objeto/método;
3. problema actual;
4. cambio sugerido;
5. código VFP propuesto;
6. riesgos;
7. pruebas manuales.
```

## Checklist de validación manual

```text
Generá un checklist de pruebas manuales para validar este cambio en Visual FoxPro:

[DESCRIBIR CAMBIO]

Incluir:
- caso normal;
- casos de error;
- impacto en reportes;
- impacto en tablas;
- rollback;
- evidencia esperada.
```
