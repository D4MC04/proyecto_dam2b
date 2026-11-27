# Nave nueva: Wildfire

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Las naves van a la misma velocidad toda su vida, así que da igual matarlas de golpe o poco a poco. La Wildfire acelera según pierde vida: castiga quitarle vida a cuentagotas y premia rematarla rápido.

## Qué hay que hacer
- Campo `rage_speed` en `EnemyData` (0 = no tiene). Velocidad = `speed` × (1 + `rage_speed` × (1 − vida / vida máxima)); con 2,0 pasa de 30 a casi 90 px/s. Se multiplica con la ralentización.
- El sprite se va tiñendo de rojo y las llamas crecen; con menos del 25 % deja una estela roja.
- Stats de docs/design/naves-plan.md (150 de vida, 30 px/s de base, 15 de daño, botín 30).
- Sprite con `scripts/tools/make_wildfire.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadir la nave a las oleadas del nivel 7 (nivel propuesto) con el panel de balanceo (pestaña Niveles) y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Wildfire
- docs/design/enemigos.md › "Datos", "Movimiento" y "Ralentización"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Enemy.gd › `_process()` y `take_damage()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/wildfire.tres
- assets/sprites/enemies/wildfire/ y scripts/tools/make_wildfire.gd
- translations/textos.csv
- resources/wave_data/ (oleadas del nivel 7, editadas con el panel)
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 7.
2. La Wildfire entra lenta; al recibir daño se pone roja y acelera, y casi muerta corre con estela.
