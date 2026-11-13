# La puerta de la oficina pregunta antes de salir

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Escape en la oficina pregunta si quieres volver a la pantalla de inicio, pero pulsar la puerta te saca sin preguntar. Las dos deberían comportarse igual.

## Qué hay que hacer
- Al pulsar la puerta (`ExitDoor`), abrir la misma confirmación que Escape (`QuitConfirm`).
- "Salir" de la confirmación hace lo de ahora (la puerta se entreabre y vuelve a la pantalla de inicio); "Cancelar", Escape o clic fuera la cierran sin salir.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Comportamiento" (Escape y la puerta) y la fila `ExitDoor` de "Oficina"
- scripts/screens/MainMenu.gd › `_on_exit_door_pressed()`, `_close_quit_confirm()` y dónde Escape abre `quit_confirm`

## Archivos que toca
- scripts/screens/MainMenu.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar a la oficina y girar a la puerta.
2. Pulsarla: sale la confirmación, igual que con Escape.
3. "Cancelar" la cierra y sigues en la oficina; "Salir" vuelve a la pantalla de inicio.
