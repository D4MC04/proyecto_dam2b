# UI de nivel

Todo cuelga de `scenes/level_ui/LevelUI.tscn`, instanciada dentro de `Game`. Los textos están en español y el tema es `assets/ui/menu_theme.tres`.

## LevelUI

`scripts/level_ui/LevelUI.gd` (clase `GameUI`), raíz `CanvasLayer` con `process_mode = ALWAYS` para seguir respondiendo con el juego en pausa.

Estructura:

- `UI/HBoxContainer/GameArea`: zona del mapa. Contiene `GameOverScreen` y `PauseMenu`, ocultos al empezar.
- `UI/HBoxContainer/Sidebar`: barra lateral derecha, 96 px de ancho mínimo.

Funciones:

- `setup(state, towers)`: conecta `state.money_changed` a `sidebar.set_money` y `state.selected_tower_changed` a `sidebar.show_selected`, crea los botones de torre y muestra el dinero inicial. Si había un `LevelState` anterior, desconecta ambas.
- `_on_tower_selected(data)`: recibe `Sidebar.tower_selected` y escribe `selected_tower` en el `LevelState`. Es el único camino de la barra lateral al estado.
- `show_game_over()`: muestra la pantalla y pausa el árbol. `hide_game_over()` la oculta.
- Acción `ui_cancel` (Escape): alterna el menú de pausa y la pausa del árbol, salvo si se ve el game over.

Señales: `restart_requested` y `quit_requested`. Las emite cuando se pulsa el botón correspondiente en pausa o en game over, después de quitar la pausa.

## Sidebar

`scenes/level_ui/Sidebar.tscn` + `scripts/level_ui/Sidebar.gd` (clase `Sidebar`).

- `MoneyLabel`: dinero con el formato `"%s€"`.
- `TowerButtons`: `GridContainer` de 2 columnas.
- `build_buttons(towers)`: borra los botones anteriores y crea un `TowerButton` por torre, todos en un `ButtonGroup` con `allow_unpress`, de modo que solo hay uno pulsado y se puede soltar.
- `set_money(amount)`: actualiza la etiqueta y avisa a cada botón.
- Señal `tower_selected(data)`: petición de cambio, con la torre al pulsar un botón y con `null` al soltarlo (no si se suelta porque se pulsa otro). No guarda la selección.
- `show_selected(data)`: marca como pulsado el botón de esa torre y suelta los demás (todos con `null`), con `set_pressed_no_signal` para no volver a emitir.

## TowerButton

`scenes/level_ui/TowerButton.tscn` + `scripts/level_ui/TowerButton.gd` (clase `TowerButton`).

- Muestra `data.icon` y el coste (`"%s€"`).
- Se desactiva si el dinero no llega al coste. Si estaba pulsado al desactivarse, se suelta.
- Mantiene forma cuadrada igualando su alto mínimo a su ancho.
- Señal `selection_changed(data, on)`.

## PauseMenu

`scenes/level_ui/PauseMenu.tscn` + `scripts/level_ui/PauseMenu.gd`. Fondo negro al 59 %, título "PAUSA" y botones "Continuar", "Reiniciar" y "Salir". Señales `resume_requested`, `restart_requested` y `quit_requested`.

## GameOverScreen

`scenes/level_ui/GameOver.tscn` + `scripts/level_ui/GameOverScreen.gd`. Fondo negro al 59 %, título "GAME OVER" y botones "Reiniciar" y "Salir". Señales `restart_requested` y `quit_requested`.

## Comunicación con el resto

| Origen | Señal | Destino |
|---|---|---|
| `LevelState` | `money_changed` | `Sidebar.set_money` |
| `LevelState` | `selected_tower_changed` | `Sidebar.show_selected` |
| `Sidebar` | `tower_selected` | `LevelUI._on_tower_selected` (escribe en `LevelState`) |
| `LevelUI` | `restart_requested` | `Game._restart_level` |
| `LevelUI` | `quit_requested` | `Game._quit_to_menu` |
| `Game` | llamada directa | `LevelUI.show_game_over` / `hide_game_over` |

## Dudas

- La interfaz no muestra la vida de la base, la oleada ni el nombre o los datos de las torres.
- El nodo raíz se llama `LevelUI` y el archivo `LevelUI.gd`, pero la clase es `GameUI`. El contenedor vertical de `GameOver.tscn` se llama `HBoxContainer`.
