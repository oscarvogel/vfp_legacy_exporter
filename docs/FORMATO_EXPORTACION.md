# Formato de exportación

## Objetivo

La exportación debe convertir archivos legacy Visual FoxPro a formatos legibles por humanos y herramientas de IA.

## Formatos generados

### TXT

Uso principal: lectura rápida, búsqueda simple, análisis manual.

Debe incluir:

- Archivo original relativo.
- Tipo detectado.
- Número de registro.
- Campos relevantes.
- Separadores claros.

### Markdown

Uso principal: documentación y lectura en GitHub/Codex.

Debe incluir:

- Título por archivo.
- Tipo de archivo.
- Registro por objeto o elemento.
- Bloques de código para propiedades y métodos.

### JSON

Uso principal: procesamiento automático posterior.

Estructura inicial esperada:

```json
{
  "file": "forms/pedidos.scx",
  "kind": "form",
  "records": [
    {
      "_recno": 1,
      "objname": "frmPedidos",
      "class": "form",
      "baseclass": "form",
      "parent": "",
      "properties": "...",
      "methods": "..."
    }
  ]
}
```

## Tipos de archivo

| Extensión | Tipo | Descripción |
|---|---|---|
| `.scx` | `form` | Formulario VFP |
| `.vcx` | `classlib` | Librería de clases VFP |
| `.frx` | `report` | Reporte VFP |
| `.mnx` | `menu` | Menú VFP |
| `.prg` | `program` | Código fuente VFP |
| `.h` | `header` | Constantes/includes |
| `.ini` | `config` | Configuración textual |

## Campos importantes en SCX/VCX

Según el archivo, pueden aparecer:

- `objname`
- `class`
- `classloc`
- `baseclass`
- `parent`
- `properties`
- `methods`
- `protected`
- `ole`
- `reserved1`, `reserved2`, etc.

No todos los archivos tienen los mismos campos. El exportador debe leer dinámicamente la estructura.

## Reglas

- No alterar encoding ni contenido original más allá de escapado necesario en JSON.
- No omitir campos no vacíos salvo binarios/general fields.
- No fallar toda la exportación por un archivo problemático.
- Registrar errores de lectura.
