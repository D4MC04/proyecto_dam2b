# Jefe para el nivel 3: Coloso

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Solo hay un jefe (Nodriza) y sale en los niveles 6 y 9.

## Qué hay que hacer
- Jefe lento y muy resistente que suelta naves normales al perder un tercio de vida.
- Sprite grande con script de `scripts/tools/`.
- Que salga con `BossAlert` al final de la última oleada del nivel 3 (en `make_waves.gd`).

## Archivos que toca
- scripts/tools/make_coloso.gd
- resources/enemy_data/coloso.tres
- scripts/entities/Enemy.gd
- scripts/level/Spawner.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Última oleada del nivel 3: sale el Coloso con aviso de jefe y suelta naves al dañarlo.
