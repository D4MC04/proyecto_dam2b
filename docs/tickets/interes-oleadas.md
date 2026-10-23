# Interés por el dinero ahorrado

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
No hay razón para ahorrar.

## Qué hay que hacer
- Al limpiar una oleada, +5 % del dinero actual (con tope), con texto flotante.
- Junto al premio de oleada perfecta en `Level._on_wave_cleared`.

## Archivos que toca
- scripts/level/Level.gd
- scripts/level/LevelState.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Acabar una oleada con dinero: se suma el interés y se ve el texto.
