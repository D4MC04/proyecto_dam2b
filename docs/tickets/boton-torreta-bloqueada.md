# Botón de torreta bloqueada más chulo y detallado

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El botón de una torreta aún no desbloqueada es una caja roja con un "?": se entiende, pero es pobre y poco original al lado de los botones normales.

## Qué hay que hacer
- Antes de implementar nada, hacer de 3 a 5 prototipos distintos del botón bloqueado (52x56, pixel art, misma caja recortada) y enseñárselos al usuario como imágenes, cada uno al lado de un botón activo normal (p. ej. el Cañón doble con su coste), a tamaño real y ampliado x4 para que se vean los píxeles. Pueden ser PNG generados con un script en el scratchpad o una página con los botones dibujados. Esperar a que el usuario elija (AskUserQuestion) antes de tocar el juego.
- Se puede mantener el rojo actual (fondo `#2a0e18`, borde `#ff3c5a`) o volver al tono azul del botón normal si queda claro e intuitivo que está bloqueado. No limitarse a un "?" sobre rojo: buscar algo más detallado y original (candado, precinto, cristal tapado, silueta oculta, banda de "CLASIFICADO", interferencia de pantalla...).
- Implementar el elegido en el estado Bloqueado de `TurretButton`, quitando el "?" (`QUESTION_MARK_PIXELS`, `_draw_question_mark`) si ya no hace falta. El comportamiento no cambia: no selecciona, no enseña ficha y no cambia con el dinero.
- Si hace falta un sprite nuevo, seguir docs/design/art.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "TurretButton" y "Botones"
- docs/design/art.md (solo si se dibuja un sprite)
- scripts/level_ui/TurretButton.gd › `setup()`, `_refresh()`, `_draw()`, `_draw_question_mark()`

## Archivos que toca
- scripts/level_ui/TurretButton.gd
- assets/ui/ (solo si hace falta un sprite nuevo)
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1.
2. En la rejilla de torretas, el Cañón doble sale normal y las otras 9 con el nuevo estilo de bloqueada.
3. Pulsar una bloqueada con clic izquierdo y derecho: no pasa nada (ni selección ni ficha).
