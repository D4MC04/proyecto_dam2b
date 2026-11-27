# El asteroide de la casilla desaparece bajo la torreta

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El asteroide con plataforma de las casillas de torreta (`TurretSlots`) se sigue viendo por detrás de la torreta, tanto en la vista previa al colocarla como cuando ya está puesta.

## Qué hay que hacer
- Con una torreta seleccionada, al pasar el ratón por una casilla libre, el asteroide de esa casilla deja de verse mientras se ve la vista previa (`BuildManager._update_preview()`). Al quitar el ratón o soltar la torreta, vuelve a verse.
- Al colocar la torreta, el asteroide de su casilla desaparece y no queda por detrás.
- Al vender la torreta (o si deja la casilla libre por otra vía), el asteroide vuelve a verse.
- Hacerlo sin escribir `tile_map_data` a mano: ocultar la casilla en tiempo de juego (por ejemplo, quitando y reponiendo su celda de la capa `TurretSlots` desde código, o con otra forma que no toque los mapas guardados).

## Qué leer
- docs/design/torretas.md › "Colocación: BuildManager" y "Animaciones de construir, fusionar y vender"
- docs/design/niveles.md › la fila de `TurretSlots` (capas del mapa)
- scripts/level/BuildManager.gd › `_update_preview()`, `_hide_preview()` y `_try_place()`
- Donde se vende una torreta y se libera su casilla (buscarlo con Grep)

## Archivos que toca
- scripts/level/BuildManager.gd
- el script que vende la torreta o libera la casilla (si hace falta)
- docs/design/torretas.md

## Cómo se prueba a mano
1. Seleccionar una torreta y pasar el ratón por una casilla libre: el asteroide de esa casilla no debería verse bajo la vista previa, y al apartar el ratón vuelve.
2. Colocar la torreta: el asteroide no queda por detrás.
3. Venderla: el asteroide vuelve a verse.
