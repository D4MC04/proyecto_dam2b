# Usar o quitar la capa 'buildable' del tileset

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`tileset.tres` declara una capa de datos `buildable` que nadie lee (Dudas de niveles.md).

## Qué hay que hacer
- Comprobar que `Grid` usa `kind`; quitar la capa `buildable` del tileset.
- Quitar la Duda.

## Archivos que toca
- resources/tilesets/tileset.tres
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1: se puede construir en las mismas casillas que antes.
