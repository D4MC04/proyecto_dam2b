# Flecha de giro de la oficina y monitor de stats

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La flecha para girar la silla es fea, el monitor de stats queda pegado a ella, y la pantalla de stats lleva textos de relleno que sobran.

## Qué hay que hacer
- **Giro:** valorar quitar la flecha y girar al mover mucho el ratón hacia un lado. Solo si se puede garantizar que es intuitivo y que no gira sin querer (por ejemplo, al ir a pulsar algo cerca del borde). Si no se puede garantizar, quedarse con la flecha y hacerla más bonita. Decir en el informe qué se eligió y por qué.
- **Si se queda la flecha:** darle margen al monitor de stats, que ahora tiene en cuenta la pared pero no la flecha y queda pegado a ella.
- **Monitor de stats (`CombatScoreboard`):** quitar "SISTEMA EN ESPERA" (con su cursor) y "// REGISTRO DE COMBATE".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Comportamiento" (Giro de la silla) y "Oficina" (Izquierda, fila `CombatScoreboard`)
- scripts/main_menu/TurnArrow.gd
- scripts/screens/MainMenu.gd › `_turn()`
- scripts/main_menu/CombatScoreboard.gd
- scripts/tools/office/gen_left.py (posición del monitor)

## Archivos que toca
- scripts/main_menu/TurnArrow.gd
- scripts/screens/MainMenu.gd
- scripts/main_menu/CombatScoreboard.gd
- scripts/tools/office/gen_left.py, assets/sprites/office/left_static.png y scripts/main_menu/OfficeLayout.gd (generados, si se mueve el monitor)
- translations/textos.csv (si se quitan claves)
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar a la oficina y girar a los dos lados (con la flecha o el ratón, según lo elegido).
2. Si es con el ratón: al mover el ratón cerca de un borde para pulsar algo no gira sin querer.
3. En la vista izquierda, el monitor de stats no toca la flecha y ya no pone "SISTEMA EN ESPERA" ni "REGISTRO DE COMBATE".
