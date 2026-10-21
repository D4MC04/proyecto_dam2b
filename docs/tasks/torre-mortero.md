# Torre nueva: Mortero

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
No hay daño de área a distancia que golpee grupos lejos.

## Qué hay que hacer
- Proyectil en arco que cae donde estará la nave y daña en un radio.
- No puede disparar a naves muy cerca (alcance mínimo).
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_mortar.gd
- resources/turret_data/mortar.tres
- resources/turret_data/mortar_fusion.tres
- scripts/entities/Bullet.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Mortero: dispara en arco y la explosión daña a varias naves.
