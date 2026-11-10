# Salir de la oficina a la pantalla de inicio y transición desde el centro

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La puerta de la oficina cierra el juego en vez de volver a la pantalla de inicio. Y la transición al elegir ranura sale de donde se hizo clic, mientras que la de entrar a la oficina sale del centro: queda desigual.

## Qué hay que hacer
- **Transición:** el `ScreenWipe` que tapa la pantalla al elegir una ranura sale siempre del centro de la pantalla (`StartScreen.gd`, ahora `card.get_global_rect().get_center()`), igual que el que la destapa al entrar a la oficina.
- **Salir de la oficina:** la puerta (`ExitDoor`) y "Salir" de la confirmación llevan a la pantalla de inicio (`StartScreen`), no cierran el juego. Ajustar los textos de la confirmación ("¿SALIR DEL JUEGO?") a lo que hace ahora.
- **Volver desde las ranuras:** valorar si añadir un botón pulsable para volver al título en la selección de ranuras (hoy solo hay "ESC VOLVER" como texto). Si se pone, con el estilo de los botones del juego; si no, decir por qué en el informe.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Pantalla de inicio" (Entrar, ScreenWipe), "Escena y script" (`QuitConfirm`) y "Comportamiento"
- docs/design/flujo.md › "Cambio de escena"
- scripts/screens/StartScreen.gd › efecto de entrada (`wipe.cover`)
- scripts/screens/MainMenu.gd › `exit_door.opened` y `_close_quit_confirm()`

## Archivos que toca
- scripts/screens/StartScreen.gd
- scenes/StartScreen.tscn (si se añade el botón)
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- translations/textos.csv
- docs/design/menu.md, docs/design/flujo.md

## Cómo se prueba a mano
1. F5, pulsar una tecla y elegir una ranura: el efecto de transición sale del centro de la pantalla.
2. En la oficina, pulsar la puerta: vuelve a la pantalla de inicio, no cierra el juego.
3. Escape en la oficina: la confirmación dice que vuelve al inicio y "Salir" lleva allí.
4. En la selección de ranuras, si hay botón de volver, lleva al título.
