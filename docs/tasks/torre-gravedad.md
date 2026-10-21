# Torre nueva: Pozo de gravedad

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La Cryo es el único control de masas.

## Qué hay que hacer
- Crea un pozo que tira de las naves cercanas hacia atrás en su camino unos px cada pocos segundos.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_gravity.gd
- resources/turret_data/gravity.tres
- resources/turret_data/gravity_fusion.tres
- scripts/entities/Enemy.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar el Pozo: las naves cercanas retroceden un poco cada cierto tiempo.
