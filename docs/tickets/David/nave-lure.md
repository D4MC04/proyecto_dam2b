# Nave nueva: Lure

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Las torretas siempre eligen bien el objetivo. La Lure les obliga a apuntarla a ratos, así protege a sus vecinas y hay que pensar dónde va cada torreta. Sustituye al antiguo ticket del Señuelo; va a pulsos para que se lea bien y no bloquee las torretas todo el rato.

## Qué hay que hacer
- Cada 5 s suelta un pulso (anillo) que dura 2,5 s. Durante el pulso, las torretas que la tienen a tiro la eligen como objetivo (en `Turret._best_enemy()` / `_get_target()`); fuera del pulso eligen normal.
- Las torretas atraídas pintan una línea roja fina hasta ella mientras dura el pulso.
- Camuflada no atrae. El área que la golpea sigue salpicando a sus vecinas.
- En las oleadas: como mucho una por grupo.
- Stats de docs/design/naves-plan.md (125 de vida, 45 px/s, 10 de daño, botín 25).
- Sprite con `scripts/tools/make_lure.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadir la nave a las oleadas del nivel 8 (nivel propuesto) con el panel de balanceo (pestaña Niveles) y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Lure
- docs/design/enemigos.md › "Datos" y "Camuflaje"
- docs/design/torretas.md › "Objetivo"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Turret.gd › `_best_enemy()` y `_get_target()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd y Turret.gd
- resources/enemy_data/lure.tres
- assets/sprites/enemies/lure/ y scripts/tools/make_lure.gd
- translations/textos.csv
- resources/wave_data/ (oleadas del nivel 8, editadas con el panel)
- docs/design/enemigos.md, docs/design/torretas.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 8.
2. Cada 5 s la Lure suelta un anillo y, durante 2,5 s, las torretas que la tienen a tiro le disparan a ella, con una línea roja.
3. Al acabar el pulso vuelven a elegir normal.
