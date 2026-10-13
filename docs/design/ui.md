# UI de nivel

Todo cuelga de `scenes/level_ui/LevelUI.tscn`, instanciada dentro de `Game`. Los textos están en español y el tema es `assets/ui/menu_theme.tres`.

## LevelUI

`scripts/level_ui/LevelUI.gd` (clase `GameUI`), raíz `CanvasLayer` con `process_mode = ALWAYS` para seguir respondiendo con el juego en pausa.

Estructura: `UI/HBoxContainer` (sin separación) con tres columnas, de izquierda a derecha:

- `InfoPanel`: barra izquierda, 80 px. De momento vacía.
- `GameArea`: zona del mapa, ocupa el resto (480 px con el viewport de 640). Contiene `GameOverScreen` y `PauseMenu`, ocultos al empezar, así que el oscurecido y los menús no tapan las barras. El mapa se centra en esta columna desde `Level` (ver [niveles.md](niveles.md)).
- `Sidebar`: barra derecha, 80 px.

`GameArea` contiene además `LevelIndicator`, declarado antes que `GameOverScreen` y `PauseMenu` para que estos lo tapen.

Las dos barras usan el mismo estilo, `assets/ui/side_panel_style.tres`: `StyleBoxFlat` opaco con el fondo del tema (`#0a0f1a`), borde de 1 px en cian oscuro `#1c7496` y 4 px de margen interior en cada lado.

## InfoPanel

`scenes/level_ui/InfoPanel.tscn`: `PanelContainer` con el tema `menu_theme.tres` y el estilo de barra, y un `VBoxContainer` vacío llamado `Content`. Sin script.

Funciones:

- `setup(state, towers, level_number, spawner)`: pasa el número de nivel al `LevelIndicator`, prepara la pestaña Oleadas (ver más abajo), conecta `state.money_changed` a `sidebar.set_money` y `state.selected_tower_changed` a `sidebar.show_selected`, crea los botones de torre y muestra el dinero inicial. Si había un `LevelState` anterior, desconecta ambas.
- `_on_tower_selected(data)`: recibe `Sidebar.tower_selected` y escribe `selected_tower` en el `LevelState`. Es el único camino de la barra lateral al estado.
- `show_game_over()`: muestra la pantalla y pausa el árbol. `hide_game_over()` la oculta.
- Acción `ui_cancel` (Escape): alterna el menú de pausa y la pausa del árbol, salvo si se ve el game over.

Señales: `restart_requested` y `quit_requested`. Las emite cuando se pulsa el botón correspondiente en pausa o en game over, después de quitar la pausa.

## LevelIndicator

`scenes/level_ui/LevelIndicator.tscn` + `scripts/level_ui/LevelIndicator.gd` (clase `LevelIndicator`). `PanelContainer` anclado arriba en el centro de `GameArea` (3 px de margen superior) con un `Label` "NIVEL N" a 8 px. Estilo `assets/ui/level_indicator_style.tres`: mismo fondo y borde que las barras, pero con 4 px de margen horizontal y 2 px vertical (unos 14 px de alto). `mouse_filter = IGNORE` en el panel y en el `Label`.

- Número: `Game` lo calcula como la posición de `level_data` en `GameData.levels` más 1 y lo pasa por `LevelUI.setup`. Si el nivel no está en la lista (0), el indicador se oculta.
- Se ve con opacidad 0,7. Si el cursor o algún nodo del grupo `enemies` está dentro de su rectángulo (con 4 px de margen), baja a 0,15 con un tween de 0,15 s; al salir, vuelve a 0,7. Se comprueba en `_process`, que sigue activo con el juego en pausa.

## Sidebar

`scenes/level_ui/Sidebar.tscn` + `scripts/level_ui/Sidebar.gd` (clase `Sidebar`). Estilo de barra compartido con `InfoPanel`. Dentro del margen de 4 px quedan 72 px de ancho útil.

- **Pestañas:** `TabBar` con dos botones de icono de 16x16 (`TowersTab` y `WavesTab`, 34x24, en un `ButtonGroup`) y una página por pestaña (`TowersPage`, `WavesPage`) de las que solo una es visible. No hay texto: el nombre ("Torres", "Oleadas") sale en el tooltip. Torres está activa al empezar. Los iconos son `assets/ui/tab_towers.png` y `tab_waves.png`. Los estilos de pestaña se crean en `_ready`: la inactiva tiene borde `#1c4a60` e icono atenuado; la activa, fondo `#14304a`, borde `#40e0f0` e icono a plena luz. Ver "Pestaña Oleadas" para `WavesPage`.
- **`TowersPage`:** `MoneyHeader` (`PanelContainer` con `assets/ui/money_header_style.tres`) con `MoneyLabel` centrado en ámbar `#ecb23c`, formato `"%s€"` con `UiFormat.abbreviate`. Debajo, `TowerScroll` (`ScrollContainer`, scroll vertical sin barra visible, horizontal desactivado) con `TowerButtons`, un `GridContainer` de 2 columnas con 4 px de separación (2 x 34 + 4 = 72). El dinero no entra en el scroll, así que no se mueve.
- `build_buttons(towers)`: borra los botones anteriores y crea un `TowerButton` por torre.
- `set_money(amount)`: actualiza la etiqueta y avisa a cada botón.
- Señal `tower_selected(data)`: petición de cambio, con la torre al pulsar un botón y con `null` al soltarla. No guarda la selección.
- `show_selected(data)`: marca el botón de esa torre y desmarca los demás (todos con `null`). No emite nada.

## TowerButton

`scenes/level_ui/TowerButton.tscn` + `scripts/level_ui/TowerButton.gd` (clase `TowerButton`). `Button` de 34x44 sin `toggle_mode` ni `ButtonGroup`, sin foco: el estado seleccionado es solo visual y lo dicta `Sidebar.show_selected` mediante `set_selected`.

- Contenido: `data.icon` a 32x32 (sin escalar) y debajo el coste, a 8 px. El coste se abrevia con `UiFormat.abbreviate` y lleva `€` solo si el texto resultante tiene menos de 4 caracteres (el botón solo tiene sitio para 4 de 8 px). Tooltip con el nombre de la torre.
- Estados (estilos `StyleBoxFlat` de 1 px, sin antialiasing, creados en `_refresh`):
  - Normal: fondo `#0e1626`, borde `#1c7496`.
  - Hover: fondo `#16243c`, borde `#40e0f0`.
  - Seleccionada: borde con `data.accent_color`, fondo mezclado con el acento (25 %); con el ratón encima, 40 % y borde más claro.
  - Sin dinero: icono al 35 % de opacidad y coste en rojo `#ff3c5a` (con dinero, ámbar `#ecb23c`); sin resalte al pasar el ratón. El botón no está `disabled`, así que recibe todos los eventos de ratón (para el clic derecho de la ficha), pero el clic izquierdo no hace nada.
- Señal `selection_changed(data, on)`: petición, no estado. El clic izquierdo pide seleccionar (`on = true`) o, si ya estaba seleccionada, soltar. Si estando seleccionada deja de llegarle el dinero, pide soltarla.

## Pestaña Oleadas

`WavesPage` (dentro de `Sidebar`): `WaveHeader` fijo (mismo estilo que `MoneyHeader`) con `WaveLabel` en cian `#40e0f0`, y debajo `WaveScroll` (scroll vertical sin barra visible) con `WaveBlocks`, un `VBoxContainer` con un `WaveBlock` por oleada (6 px de separación).

- **Cabecera:** `"OL. X/Y"` (X = oleada en curso desde 1, Y = total). La forma larga no cabe en 72 px a 8 px de fuente. Antes de que empiece ninguna oleada muestra la 1.
- `Sidebar.build_waves(waves)`: borra los bloques anteriores y crea uno por `WaveData`. `Sidebar.set_current_wave(index, total)`: actualiza cabecera y estados, y desplaza la lista (`ensure_control_visible`, tras esperar un frame) para que el bloque en curso quede visible; también se hace al volver a la pestaña.
- **`WaveBlock`** (`scenes/level_ui/WaveBlock.tscn` + `scripts/level_ui/WaveBlock.gd`): título `"OLEADA N"` en un panel de 72 px y una rejilla de 2 columnas (34 px, 4 px de separación) de `EnemyCell`. Agrupa las entradas por `EnemyData`, con el total de cada tipo, en orden de primera aparición (por `time`). No hay datos de enemigos en la UI.
- **Estados:** `WaveBlock.set_state`. En curso: título con fondo `#14304a`, borde y texto `#40e0f0`. Pasada: todo el bloque al 40 % de opacidad. Futura: título con fondo `#0e1626`, borde `#1c4a60` y texto `#7fa6b8`.
- **`EnemyCell`** (`scenes/level_ui/EnemyCell.tscn` + `scripts/level_ui/EnemyCell.gd`): `Button` de 34x44 con los colores de `TowerButton`. Sprite = primer frame de `up` a escala 1, centrado en un área de 34x34 (el Spikey, de 34, ocupa todo el ancho de la celda y pisa el borde), y debajo `"×N"` a 8 px (abreviado con `UiFormat`). Tooltip con el nombre. Emite `enemy_clicked(data)`, que de momento nadie escucha.
- `LevelUI.setup(..., spawner)` construye los bloques con `spawner.waves`, marca la oleada actual con `spawner.get_wave_index()` y conecta `spawner.wave_started` a `sidebar.set_current_wave`, desconectando el `Spawner` anterior si lo había.

## UiFormat

`scripts/level_ui/UiFormat.gd` (clase `UiFormat`). `UiFormat.abbreviate(amount: int) -> String`: hasta 9999 tal cual; después `12.3K`, `123K`, `1.2M`, `1.5B`, con 5 caracteres como máximo. Trunca en vez de redondear y quita el decimal si es 0 (`10K`, no `10.0K`). La usan el dinero y los costes.

## PauseMenu

`scenes/level_ui/PauseMenu.tscn` + `scripts/level_ui/PauseMenu.gd`. Fondo negro al 59 %, título "PAUSA" y botones "Continuar", "Reiniciar" y "Salir". Señales `resume_requested`, `restart_requested` y `quit_requested`.

## GameOverScreen

`scenes/level_ui/GameOver.tscn` + `scripts/level_ui/GameOverScreen.gd`. Fondo negro al 59 %, título "GAME OVER" y botones "Reiniciar" y "Salir". Señales `restart_requested` y `quit_requested`.

## Comunicación con el resto

| Origen | Señal | Destino |
|---|---|---|
| `LevelState` | `money_changed` | `Sidebar.set_money` |
| `LevelState` | `selected_tower_changed` | `Sidebar.show_selected` |
| `Spawner` | `wave_started` | `Sidebar.set_current_wave` |
| `Sidebar` | `tower_selected` | `LevelUI._on_tower_selected` (escribe en `LevelState`) |
| `LevelUI` | `restart_requested` | `Game._restart_level` |
| `LevelUI` | `quit_requested` | `Game._quit_to_menu` |
| `Game` | llamada directa | `LevelUI.show_game_over` / `hide_game_over` |

## Dudas

- La interfaz no muestra la vida de la base, ni los datos de las torres (el nombre solo sale en el tooltip del botón).
- El nodo raíz se llama `LevelUI` y el archivo `LevelUI.gd`, pero la clase es `GameUI`. El contenedor vertical de `GameOver.tscn` se llama `HBoxContainer`.
