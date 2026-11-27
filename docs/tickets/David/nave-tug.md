# Nave nueva: Tug

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las naves pesadas son lentas y dan mucho tiempo de disparo. La Tug las arrastra con un rayo tractor a su velocidad, y el orden en que las matas cambia la oleada: si cae la Tug, la pesada vuelve a ir lenta; si cae la pesada, la Tug sale disparada sola.

## Qué hay que hacer
- Al salir, engancha un rayo tractor a la nave pesada más cercana de su camino que no lleve ya otra Tug (las que tengan un campo nuevo `towable` en `EnemyData`: Ram, Juggernaut, Mothership, Damper…). Mientras dure, la pesada avanza a la velocidad de la Tug, pegada a ella.
- Visual: rayo azul de píxeles entre las dos, la pesada con un leve brillo azul y los motores apagados.
- Si muere la Tug, la pesada vuelve a su velocidad. Si muere la pesada, la Tug sigue sola. Sin pesada cerca, va sola sin rayo.
- En las oleadas: sacarla justo delante de un grupo de pesadas.
- Stats de docs/design/naves-plan.md (75 de vida, 75 px/s, 10 de daño, botín 20).
- Sprite con `scripts/tools/make_tug.gd` (nave pequeña con motores enormes y emisor delante; pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadir la nave a las oleadas del nivel 6 (nivel propuesto) con el panel de balanceo (pestaña Niveles) y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Tug
- docs/design/enemigos.md › "Datos" y "Movimiento"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Enemy.gd › `_process()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/tug.tres (y `towable` en las pesadas)
- assets/sprites/enemies/tug/ y scripts/tools/make_tug.gd
- translations/textos.csv
- resources/wave_data/ (oleadas del nivel 6, editadas con el panel)
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 6.
2. Una Tug arrastra a una Juggernaut con un rayo azul, las dos a la velocidad de la Tug.
3. Al matar la Tug, la Juggernaut vuelve a ir lenta; al matar antes la Juggernaut, la Tug sigue sola.
