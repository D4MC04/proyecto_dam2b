# Cada tipo de enemigo quita una vida distinta a la estación

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
Todos los enemigos quitan 10 de vida al llegar al final (`Level.ENEMY_BASE_DAMAGE`), da igual que sea un dart pequeño o una nodriza (docs/design/enemigos.md, "Dudas"). Que los grandes hagan más daño da sentido a priorizarlos.

## Qué hay que hacer
- Añadir a `EnemyData` un campo tipado `@export var base_damage: int = 10`.
- Que la señal de llegada al final lleve el daño del enemigo (o el enemigo) y que `Level` use ese valor en vez de la constante. Quitar `ENEMY_BASE_DAMAGE` si deja de usarse.
- Dar valores en los 12 `.tres` de `resources/enemy_data/`: pequeños (darts, wasp) 5, normales 10, grandes (acorazado, ariete) 20, nodriza 40. Ajustar si algún nombre no encaja.
- Mostrar "Daño a la estación" en la ficha del enemigo si `InfoPanel` ya enseña stats de enemigos; si no, dejarlo.
- Actualizar docs/design/enemigos.md y docs/design/base.md.

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- scripts/level/Spawner.gd
- scripts/level/Level.gd
- resources/enemy_data/*.tres
- docs/design/enemigos.md, docs/design/base.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y entrar a un nivel con darts y algún enemigo grande.
2. Sin poner torres, lanzar la oleada.
3. Cuando llega un dart, la estación baja poco; cuando llega uno grande, baja bastante más (se nota en la fase de daño, o en la barra si ya está hecho `vida-de-la-base-en-ui`).
