# Torre nueva: Amplificador

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
No hay torres de apoyo que hagan pensar en la colocación.

## Qué hay que hacer
- No dispara; sube daño y cadencia un % a las torres vecinas (8 casillas alrededor).
- Aura visible y la mejora en la ficha de las torres afectadas.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_amplifier.gd
- resources/turret_data/amplifier.tres
- resources/turret_data/amplifier_fusion.tres
- scripts/level_ui/InfoPanel.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Amplificador junto a dos torres: disparan más rápido y la ficha lo indica.
