# Torre nueva: Lanzamisiles teledirigidos

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Contra Espectros y naves rápidas no hay proyectiles que sigan al objetivo.

## Qué hay que hacer
- Misiles que giran hacia su objetivo; si muere, buscan otro cercano.
- Estela de humo.
- Sprite de torre y su fusión con un script de `scripts/tools/` siguiendo art.md; `TowerData` y su versión fusionada; añadirla a las torres disponibles desde el nivel que se elija.

## Archivos que toca
- scripts/tools/make_missile.gd
- resources/turret_data/missile.tres
- resources/turret_data/missile_fusion.tres
- scripts/entities/Bullet.gd
- resources/level_data/level_*.tres (torres disponibles)
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar la torre: los misiles curvan su trayectoria y aciertan a naves rápidas.
