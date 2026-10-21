# Torre nueva: Francotirador

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Falta una torre de mucho alcance y disparo lento contra naves duras.

## Qué hay que hacer
- Alcance muy largo, daño alto, cadencia lenta; prioriza la nave con más vida.
- Reutilizar el ataque de bala o de haz.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_sniper.gd
- resources/turret_data/sniper.tres
- resources/turret_data/sniper_fusion.tres
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Francotirador: dispara lento y de lejos, y elige a las naves grandes.
