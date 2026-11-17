# Sectores sin la oficina detrás, como opciones y Navedex

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Al abrir Sectores, la pantalla de Sectores no tapa la oficina: se sigue viendo detrás, y durante la animación se ven a la vez la pantalla de la mesa y la oficina, mezcladas. Con la consola de opciones y la Navedex no pasa, porque al final del zoom aparece encima su panel con un fundido y tapa la oficina.

## Qué hay que hacer
- Abrir y cerrar Sectores como la consola de opciones y la Navedex: la oficina se acerca a la mesa del radar y, en la parte final del zoom (como `CLOSE_UP_FADE_START`), la pantalla de Sectores aparece encima con un fundido, tapando la oficina; al cerrar con Escape, lo inverso.
- Con Sectores abierto no se ve la oficina detrás ni a los lados: la pantalla de Sectores lleva su propio fondo opaco (el de la pantalla de la mesa o el que encaje con su estilo), y durante la animación nunca se ven mezcladas la pantalla de la mesa y la oficina.
- Mantener lo que ya funciona: el radar y la ficha en vivo en la mesa mientras está cerrada (`RadarViewport`), la pista "ESC para volver", `_refresh_sectors()` y el tutorial de la oficina (paso `RADAR`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Escena y script" (`LevelSelectionScreen`, `SectorsEscHint`), "Oficina" (fila de `RadarConsole`) y "Comportamiento" (puntos "Mesa del radar" y "Consola de opciones")
- scripts/screens/MainMenu.gd › `_zoom_in()`, `_zoom_out()`, `_open_sectors()`, `_close_sectors()`, `_set_radar_zoom()`, `_move_sectors()`, `_update_screen_rect()`, `_on_options_console_pressed()`, `_set_options_zoom()`, `_set_tablet_zoom()`
- scripts/main_menu/RadarConsole.gd › `set_zoom()`

## Archivos que toca
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scripts/main_menu/RadarConsole.gd (si hace falta)
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego y entrar en una partida hasta la oficina.
2. Pulsar la mesa de Sectores: la oficina se acerca a la mesa y al final aparece la pantalla de Sectores con un fundido; durante la animación no se ven la pantalla y la oficina mezcladas.
3. Con Sectores abierto, no se ve la oficina detrás. Escape: vuelve a la oficina con la animación inversa, igual de limpia.
4. Comparar con la consola de opciones y la tablet de la Navedex: se sienten iguales.
