# Clic en todo el asteroide para colocar torretas

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El asteroide de cada hueco se dibuja de 32x32 (2x2 casillas), pero el clic solo cuenta en una casilla de 16x16, así que es fácil fallar al colocar o seleccionar una torreta. La zona de clic debe ser más o menos igual de grande que el asteroide.

## Qué hay que hacer
- Al colocar, en la vista previa y al seleccionar una torreta ya puesta, si el ratón cae sobre el dibujo del asteroide de un hueco (no solo en su casilla), cuenta como ese hueco. Si dos asteroides se tocan, gana el hueco cuyo centro esté más cerca del ratón.
- Hacerlo en un único sitio (por ejemplo una función de `Grid` que, dado un punto, dé el hueco cuyo asteroide está debajo) y usarla en `BuildManager._try_place()` y `_update_preview()` en lugar de `grid.cell(mouse_pos)` donde se busca hueco o torreta.
- Medir el tamaño real del asteroide en el tile (`make_turret_slot_tiles.gd`, `SIZE` 32, `CENTER`) y en cómo lo coloca `map_generator.gd › _place_turret_slots()` para que la zona coincida con lo que se ve.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › los puntos de clic izquierdo de `BuildManager` (al principio)
- scripts/level/Grid.gd › `cell()`, `center()`, `can_build()`
- scripts/level/BuildManager.gd › `_try_place()`, `_update_preview()`
- scripts/tools/map_generator.gd › `_place_turret_slots()`

## Archivos que toca
- scripts/level/Grid.gd
- scripts/level/BuildManager.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1 con una torreta de la tienda elegida.
2. Pasar el ratón por el borde de un asteroide libre: la vista previa sale en ese hueco.
3. Hacer clic en el borde del asteroide: la torreta se coloca ahí. Clic en el borde de una torreta ya puesta: se selecciona.
4. Clic en el espacio vacío lejos de los asteroides: suelta la selección, como antes.
