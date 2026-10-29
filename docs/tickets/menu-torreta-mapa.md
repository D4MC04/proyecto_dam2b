# Mejorar y vender en un recuadro encima de la torreta

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Mejorar y vender están en la barra izquierda, lejos de la torreta en la que se ha hecho clic. Además, sin dinero "Mejorar" parece pulsable aunque no haga nada.

## Qué hay que hacer
- Quitar `UpgradeButton` y `SellButton` de `InfoPanel` (la ficha sigue enseñando la torreta seleccionada y sus filas BAJAS, HECHO y amplificación).
- Crear un recuadro pequeño (escena nueva `TurretActions`) con los dos botones: "Mejorar (-X€)" (solo si la torreta tiene `fusion`) y "Vender (+X€)" con la confirmación "¿Seguro?" de ahora. Se abre al seleccionar una torreta colocada (`LevelState.sellable_turret_changed`) justo encima de ella y se cierra al soltarla, venderla o reiniciar; tras mejorar se queda sobre la nueva. Si encima no cabe en el área de juego, sale debajo.
- Posición: `LevelUI` es un `CanvasLayer`, así que hay que pasar la posición de la torreta del mapa a pantalla (`get_global_transform_with_canvas()` o equivalente, teniendo en cuenta el centrado del mapa de `Level`). Va dentro de `GameArea`, por debajo de las pantallas de pausa, derrota y victoria.
- Las señales `upgrade_requested` y `sell_requested` salen del recuadro y `LevelUI` las sigue tratando igual (`_on_upgrade_requested`, `_on_sell_requested`, solo en `PLAYING`).
- "Mejorar" se ve apagado (como `NextWaveButton` desactivado: borde `#1c4a60`, texto al 30 %) cuando el dinero no llega a `fusion.cost`, y se enciende al llegar: escuchar `LevelState.money_changed`.
- Estilo de los botones con `ClippedBoxStyle.create`, como el resto de la UI.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "InfoPanel (ficha)" (`UpgradeButton`, `SellButton`), "Botones", "LevelUI"
- docs/design/torretas.md › "Mejorar (fusión)", "Vender"
- scripts/level_ui/InfoPanel.gd › `show_sellable()`, `_on_sell_pressed()`
- scripts/level_ui/LevelUI.gd › `setup()`, `_on_sell_requested()`, `_on_upgrade_requested()`
- scripts/level/LevelState.gd › `sellable_turret`, `money_changed`

## Archivos que toca
- scenes/level_ui/InfoPanel.tscn, scripts/level_ui/InfoPanel.gd
- scenes/level_ui/TurretActions.tscn, scripts/level_ui/TurretActions.gd (nuevos)
- scenes/level_ui/LevelUI.tscn, scripts/level_ui/LevelUI.gd
- docs/design/ui.md, docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y colocar una torreta que tenga mejora.
2. Hacer clic en ella: sale un recuadro encima con Mejorar y Vender; en la barra izquierda ya no están.
3. Sin dinero suficiente, Mejorar se ve apagado; al ganar dinero se enciende y mejora la torreta.
4. Vender pide "¿Seguro?" y vende al segundo clic; el recuadro se cierra. Clic en el espacio vacío también lo cierra.
5. Con una torreta en el borde de arriba del mapa, el recuadro sale debajo y no se corta.
