# Torreta seleccionada con borde y alcance solo con el ratón encima

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Al seleccionar una torreta colocada, su círculo de alcance se queda puesto y tapa el mapa aunque ya no se esté mirando. Se quiere ver el alcance solo al pasar el ratón y marcar la selección de otra forma.

## Qué hay que hacer
- En `Turret._draw()`, quitar `selected` de la condición del alcance: se dibuja solo con la opción `show_turret_range` o con `_hovered` (esté seleccionada o no).
- Con `selected`, dibujar un borde alrededor de la casilla de la torreta (16x16, píxeles enteros, sin antialiasing). Color: ámbar `#ecb23c`, el mismo que marca el `TurretButton` seleccionado, para que "seleccionado" sea un solo color en todo el juego (el usuario propuso verde, pero no está en la paleta de la UI; si al probarlo no se distingue bien, se cambia). El borde va por encima del sprite (que no lo tape la torreta), por ejemplo en un nodo hijo con `z_index` mayor.
- Actualizar el comentario de `selected` y de `_draw()`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Escena y script"
- docs/design/ui.md › "TurretButton" (colores de seleccionado)
- scripts/entities/Turret.gd › `selected`, `_draw()`, `_physics_process()`

## Archivos que toca
- scripts/entities/Turret.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1 con la opción "mostrar rango" apagada y colocar una torreta.
2. Hacer clic en ella: sale el borde ámbar y no sale el alcance.
3. Pasar el ratón por encima: sale el alcance; al quitarlo, se va y el borde sigue. Pasar el ratón por una no seleccionada: también sale su alcance.
