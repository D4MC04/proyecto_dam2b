# Torre nueva: Pulso inhibidor

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las naves con habilidades (Espectro, Reparadora, Saboteadora) no tienen contra directo.

## Qué hay que hacer
- Pulso que cada X s anula habilidades en su radio durante unos segundos (revela al Espectro, corta curación y EMP).
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_inhibitor.gd
- resources/turret_data/inhibitor.tres
- resources/turret_data/inhibitor_fusion.tres
- scripts/entities/Enemy.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Nivel 8: con el Pulso cerca, las Saboteadoras no apagan torres y los Espectros se ven.
