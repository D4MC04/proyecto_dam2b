# Códigos secretos en el panel de acceso

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El panel de acceso junto a la puerta (pantallita verde y teclado de 3x4) es solo decorado. Se quiere usarlo como easter egg: acercarse a él, teclear códigos secretos y que pasen cosas.

## Qué hay que hacer
- **Zoom al panel:** al pulsar el panel de acceso (`OfficeLayout.LEFT.access`, vista izquierda) la cámara se acerca como al monitor de stats (`_zoom_in` / `_zoom_out`, con el mismo arreglo para la vista izquierda que ya usa el monitor) y desde `CLOSE_UP_FADE_START` aparece el panel de cerca (nuevo `AccessCloseUp`), dibujado como el del PNG pero grande.
- **Teclado:** las 12 teclas se pulsan con el ratón (y los números con el teclado): 0-9, borrar y aceptar. Los dígitos salen en la pantallita verde (máximo 4), con un pitido por tecla.
- **Respuesta:** código incorrecto → la pantalla parpadea en rojo con "DENEGADO" y se borra. Correcto → "ACCESO CONCEDIDO" en verde y su efecto. Escape, clic fuera o la tecla de volver hacen el zoom inverso.
- **Códigos** (constante en el script, sin pistas en el juego):
  - `1337` (visual): las luces de la oficina cambian de color un rato y la puerta se abre del todo un momento (`open_fully`).
  - `0451` (ventaja): +100 de dinero al empezar el siguiente nivel, una sola vez por partida guardada (guardado en `GameState`).
  - `7355` (logro secreto): desbloquea un logro nuevo oculto "Hacker" en `GameState.ACHIEVEMENTS` con su medalla en la vitrina (`medal_hacker.png`, pixel art como las demás). En la vitrina sale como "???" hasta conseguirlo.
  - Cada código, una vez usado, vuelve a decir "ACCESO CONCEDIDO" pero no repite la ventaja.
- Textos traducidos (claves nuevas como las `STATS_*`).
- Actualizar docs/design/menu.md (panel de acceso y zoom) y el doc de logros si existe.

## Qué leer
- docs/design/menu.md › "Oficina" (vista izquierda, tabla de objetos), "Comportamiento" › "Zoom a un objeto"
- docs/design/art.md › "Oficina del menú"
- scripts/screens/MainMenu.gd › `_zoom_in()`, `_zoom_out()`, zoom del monitor de stats
- scripts/main_menu/OfficeDoor.gd › `open_fully()`, `access_light`
- scripts/autoloads/GameState.gd › `ACHIEVEMENTS`, `stats`

## Archivos que toca
- scripts/main_menu/AccessCloseUp.gd (nuevo)
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scripts/autoloads/GameState.gd
- assets (medalla `medal_hacker.png`)
- archivo de traducciones
- docs/design/menu.md

## Cómo se prueba a mano
1. En la oficina, girar a la izquierda y pulsar el panel de acceso junto a la puerta: la cámara se acerca.
2. Teclear `1234` y aceptar: "DENEGADO" en rojo.
3. `1337`: luces de colores y la puerta se abre un momento.
4. `0451` y jugar un nivel: empieza con 100 más de dinero; repetir el código no lo vuelve a dar.
5. `7355`: la medalla "Hacker" aparece en la vitrina de la derecha.
6. Escape: la cámara se aleja.
