# Torre nueva: Bahía de drones

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Todas las torres disparan desde su casilla.

## Qué hay que hacer
- Suelta 2 drones que vuelan hacia las naves en un radio grande y disparan; vuelven a la bahía.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_drone_bay.gd
- resources/turret_data/drone_bay.tres
- resources/turret_data/drone_bay_fusion.tres
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar una Bahía: salen drones que persiguen y atacan naves y vuelven.
