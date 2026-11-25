# "Rendirse" en vez de "Oficina" en la pausa

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
En la pantalla de pausa, el botón que sale del nivel dice "Oficina". Debe decir "Rendirse".

## Qué hay que hacer
- Cambiar el texto del botón `QuitButton` de `PauseMenu` a "Rendirse" ("Surrender" en inglés), con una clave nueva en `translations/textos.csv` (por ejemplo `BTN_SURRENDER`). `BTN_MENU` lo usan también la derrota (`GameOver.tscn`) y la victoria (`VictoryScreen.tscn`), que siguen diciendo "Oficina".
- Mirar `LevelUI.QUIT_TEXT`, que también usa `BTN_MENU`, por si pone el texto a ese botón desde código.
- Solo cambia el texto: el botón sigue haciendo lo mismo.

## Qué leer
- scenes/level_ui/PauseMenu.tscn › nodo `QuitButton`
- scripts/level_ui/LevelUI.gd › `QUIT_TEXT` y dónde se usa
- translations/textos.csv › `BTN_MENU`
- docs/design/ui.md › la sección del menú de pausa (sacarla con Grep `^#`)

## Archivos que toca
- scenes/level_ui/PauseMenu.tscn
- scripts/level_ui/LevelUI.gd (si hace falta)
- translations/textos.csv
- docs/design/ui.md

## Cómo se prueba a mano
1. Empezar cualquier nivel y pulsar Escape.
2. El botón de abajo de la pausa debería decir "Rendirse" y seguir llevando a la oficina.
3. Perder o ganar un nivel: el botón de esas pantallas sigue diciendo "Oficina".
