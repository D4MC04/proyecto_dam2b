# Deseleccionar la torreta colocada al volver a pulsarla o al usar la barra

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Una torreta colocada seleccionada (contorno ámbar, mejorar y vender) solo se suelta pulsando en el espacio; lo natural es soltarla al volver a pulsarla o al tocar la barra derecha.

## Qué hay que hacer
- En `BuildManager._try_place`: si la torreta pulsada ya es `state.sellable_turret`, soltarla (sin selección colocada ni ficha, como `_deselect_all()`) en vez de volver a seleccionarla.
- Pulsar cualquier botón de la barra derecha (pestañas, botones de torreta, INICIAR, AUTO, ×1/×2, flechas de oleada, celdas de enemigo) suelta la torreta colocada (`state.sellable_turret = null`). Con una señal de `Sidebar` que escuche `LevelUI`, sin que la barra lea el `LevelState`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Colocación: BuildManager"
- docs/design/ui.md › "LevelUI" (funciones) y "Sidebar"
- scripts/level/BuildManager.gd › `_try_place()`, `_deselect_all()`
- scripts/level/LevelState.gd › `inspected`, `sellable_turret`
- scripts/level_ui/LevelUI.gd › `setup()`, `_on_turret_selected()`

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/level_ui/Sidebar.gd
- scripts/level_ui/LevelUI.gd
- docs/design/torretas.md
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 2 y colocar un Cañón doble.
2. Pulsarlo: salen el contorno ámbar y el recuadro de mejorar/vender. Pulsarlo otra vez: desaparecen.
3. Seleccionarlo y pulsar la pestaña Oleadas, AUTO o ×2: se deselecciona.
