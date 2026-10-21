# Reintentar desde la última oleada

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Perder en la oleada 9 de 10 obliga a empezar de cero.

## Qué hay que hacer
- Guardar al empezar cada oleada (torres, dinero, vida).
- En la derrota, botón 'Reintentar oleada' que vuelve a ese punto.

## Archivos que toca
- scripts/level/Level.gd
- scripts/level/Spawner.gd
- scripts/level_ui/GameOverScreen.gd
- docs/design/flujo.md

## Cómo se prueba a mano
1. Perder en una oleada y pulsar 'Reintentar oleada': se vuelve con las mismas torres y dinero.
