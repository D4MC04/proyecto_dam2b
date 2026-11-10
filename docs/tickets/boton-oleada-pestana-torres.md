# START y Espacio no lanzan la oleada desde la pestaña Torres

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Fuera del tutorial, el botón START del pie y la tecla Espacio solo funcionan con la pestaña Oleadas abierta; desde la pestaña Torres no pasa nada.

## Qué hay que hacer
- En `Sidebar._on_next_wave_pressed()` la condición `waves_page.visible` se exige siempre, porque `tutorial_hints` nunca es `null` (LevelUI siempre lo asigna). Exigir la pestaña Oleadas solo mientras el tutorial está en marcha (por ejemplo, un `is_running()` en `TutorialHints` que devuelva `_active and _step != Step.DONE`).
- El atajo `next_wave` (`press_next_wave()` emite `next_wave_button.pressed`) también pasa por esa función: debe valer desde cualquier pestaña, como dice el diseño, también durante el tutorial.
- Actualizar la línea del tutorial en docs/design/ui.md si cambia cómo se describe.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Tutorial del nivel 1" (punto "Bloqueo de acciones")
- scripts/level_ui/Sidebar.gd › `_on_next_wave_pressed()`, `press_next_wave()`
- scripts/level_ui/TutorialHints.gd › `allows()`

## Archivos que toca
- scripts/level_ui/Sidebar.gd
- scripts/level_ui/TutorialHints.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Con el tutorial ya hecho (o saltado), jugar cualquier nivel.
2. Con la pestaña Torres abierta, pulsar START y, en otra oleada, Espacio.
3. Debería empezar la oleada en los dos casos. En el tutorial del nivel 1, el botón START sigue respondiendo solo con la pestaña Oleadas.
