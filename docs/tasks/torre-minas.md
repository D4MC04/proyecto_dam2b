# Torre nueva: Sembradora de minas

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No hay defensa que actúe sobre el camino.

## Qué hay que hacer
- Lanza minas a puntos del camino en su alcance; explotan al pasar una nave (máximo N minas).
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_mine_layer.gd
- resources/turret_data/mine_layer.tres
- resources/turret_data/mine_layer_fusion.tres
- scripts/entities/
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar la torre: aparecen minas en el camino que explotan con las naves.
