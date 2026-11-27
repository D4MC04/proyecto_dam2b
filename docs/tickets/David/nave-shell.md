# Nave nueva: Shell

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Todas las naves reciben el daño entero, así que da igual pegar muchos golpes pequeños o pocos grandes. La Shell resta 5 a cada golpe: los golpes flojos apenas le hacen nada y rinden más los fuertes. Es lo contrario de la Damper.

## Qué hay que hacer
- Campo `armor` en `EnemyData` (0 por defecto): `take_damage()` resta `armor` a cada golpe, mínimo 1.
- Haz continuo del Disintegrator: hace daño cada frame (`daño por segundo × delta`, menos de 1 por golpe). Restar `armor` por frame lo dejaría a 0 o, con el mínimo de 1, subiría su daño. Hay que restarlo por segundo: daño por segundo − `armor` (35 → 30). Se hace en `FocusBeam`.
- Los golpes que pierden más de la mitad sacan una chispa gris en vez del destello blanco. La ficha enseña una fila con el blindaje.
- Stats de docs/design/naves-plan.md (150 de vida, 30 px/s, 15 de daño, botín 30, `armor` 5).
- Sprite con `scripts/tools/make_shell.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadir la nave a las oleadas del nivel 4 (nivel propuesto) con el panel de balanceo (pestaña Niveles) y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Shell
- docs/design/enemigos.md › "Datos", "Daño y muerte" y "Efectos visuales"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Enemy.gd › `take_damage()`
- scripts/entities/FocusBeam.gd › donde aplica el daño

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd y FocusBeam.gd
- resources/enemy_data/shell.tres
- assets/sprites/enemies/shell/ y scripts/tools/make_shell.gd
- translations/textos.csv
- resources/wave_data/ (oleadas del nivel 4, editadas con el panel)
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 4.
2. Los Cañones dobles le hacen 1 por golpe y salen chispas grises; el Cañón pesado le quita casi todo su daño.
