# Nave nueva: Kamikaze

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Falta una nave que castigue dejar huecos: rápida, frágil y que hace mucho daño a la estación.

## Qué hay que hacer
- Sprite con `scripts/tools/make_kamikaze.gd` (pixel art según art.md).
- `EnemyData`: muy rápida, poca vida, `base_damage` alto.
- Acelera al final del camino.
- Añadirla a la tabla de `scripts/tools/make_waves.gd` (nivel 5 en adelante) y a la Navedex.

## Archivos que toca
- scripts/tools/make_kamikaze.gd
- resources/enemy_data/kamikaze.tres
- scripts/entities/Enemy.gd
- scripts/tools/make_waves.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Nivel 5: salen Kamikazes, rápidas; si llegan, quitan mucha vida.
