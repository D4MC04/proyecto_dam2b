# Revisar y quitar la música que no se usa

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`Tyrant.ogg` y `Space_1990-B.ogg` (~12 MB) no aparecen en ningún script ni escena.

## Qué hay que hacer
- Confirmar con grep en todo el proyecto (también .tres) qué pistas de assets/audio/music no se usan.
- Preguntar al usuario si quiere reservarlas para algún nivel; si no, borrarlas con su .import.
- Actualizar docs/design/menu.md (apartado Música).

## Archivos que toca
- assets/audio/music/*
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir el proyecto sin errores.
2. La música del menú y de los niveles sigue sonando.
