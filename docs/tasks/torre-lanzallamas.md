# Torre nueva: Lanzallamas

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
No hay daño continuo en cono a corta distancia ni quemaduras.

## Qué hay que hacer
- Cono de fuego corto que daña a todo lo que toca y deja quemadura (daño por segundo unos segundos).
- Partículas de fuego.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_flamethrower.gd
- resources/turret_data/flamethrower.tres
- resources/turret_data/flamethrower_fusion.tres
- scripts/entities/Enemy.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Lanzallamas junto al camino: quema a las naves que pasan y siguen perdiendo vida un rato.
