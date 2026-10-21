# Torre nueva: Láser de barrido

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Los haces existentes van a un solo objetivo.

## Qué hay que hacer
- Haz que barre un arco de lado a lado dañando todo lo que cruza.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_sweeper.gd
- resources/turret_data/sweeper.tres
- resources/turret_data/sweeper_fusion.tres
- scripts/entities/Beam.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar la torre: el láser barre un arco y daña a varias naves a la vez.
