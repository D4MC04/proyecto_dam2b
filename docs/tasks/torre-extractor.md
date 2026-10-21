# Torre nueva: Extractor de dinero

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No hay forma de invertir para ganar dinero.

## Qué hay que hacer
- No dispara; da dinero al acabar cada oleada (con `FloatingText`).
- Cara y solo rentable si se pone pronto.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_extractor.gd
- resources/turret_data/extractor.tres
- resources/turret_data/extractor_fusion.tres
- scripts/level/Level.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Extractor y acabar una oleada: suma dinero con un texto flotante.
