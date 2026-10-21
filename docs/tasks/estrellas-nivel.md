# Estrellas por nivel

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Ganar un nivel con 1 de vida o con toda cuenta igual.

## Qué hay que hacer
- 1 estrella por ganar, 2 con más del 50 % de vida, 3 sin perder vida.
- Guardarlas en `GameState`.
- Enseñarlas en la victoria.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/level_ui/VictoryScreen.gd
- docs/design/flujo.md

## Cómo se prueba a mano
1. Ganar el nivel 1 sin perder vida: salen 3 estrellas y se guardan al reiniciar el juego.
