# Torre nueva: Proyector de escudo

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
No hay forma de proteger la estación directamente.

## Qué hay que hacer
- Solo junto a la estación; le da un escudo que absorbe el daño de N naves y se recarga entre oleadas.
- Reutilizar `shield.png` y `shield_debil.png` si sirven.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_shield_projector.gd
- resources/turret_data/shield_projector.tres
- resources/turret_data/shield_projector_fusion.tres
- scripts/entities/Base.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocarla junto a la estación y dejar pasar naves: el escudo se gasta antes que la vida.
