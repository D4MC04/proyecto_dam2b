# UI de nivel

Todo cuelga de `scenes/level_ui/LevelUI.tscn`, instanciada dentro de `Game`. Los textos están en español y el tema es `assets/ui/menu_theme.tres`.

## LevelUI

`scripts/level_ui/LevelUI.gd` (clase `GameUI`), raíz `CanvasLayer` con `process_mode = ALWAYS` para seguir respondiendo con el juego en pausa.

Estructura: `UI/HBoxContainer` (sin separación) con tres columnas, de izquierda a derecha:

- `InfoPanel`: barra izquierda, 80 px, con la ficha (ver más abajo).
- `GameArea`: zona del mapa, ocupa el resto (480 px con el viewport de 640). Contiene `GameOverScreen` y `PauseMenu`, ocultos al empezar, así que el oscurecido y los menús no tapan las barras. El mapa se centra en esta columna desde `Level` (ver [niveles.md](niveles.md)).
- `Sidebar`: barra derecha, 80 px.

`GameArea` contiene además `LevelIndicator`, declarado antes que `GameOverScreen` y `PauseMenu` para que estos lo tapen.

Las dos barras usan el mismo estilo, `assets/ui/side_panel_style.tres`: `StyleBoxFlat` opaco con el fondo del tema (`#0a0f1a`), borde de 1 px en cian oscuro `#1c7496` y 4 px de margen interior en cada lado.

Funciones de `LevelUI`:

- `setup(state, towers, level_number, spawner)`: pasa el número de nivel al `LevelIndicator`, prepara la pestaña Oleadas (ver más abajo), conecta `state.money_changed` a `sidebar.set_money`, `state.selected_tower_changed` a `sidebar.show_selected` y `state.inspected_changed` a `info_panel.show_inspected`, crea los botones de torre, muestra el dinero inicial y pide a la ficha que enseñe `state.inspected` (null en un `LevelState` nuevo, así que al empezar o reiniciar vuelve al escáner). Si había un `LevelState` anterior, desconecta las tres.
- `_on_tower_selected(data)`: recibe `Sidebar.tower_selected` y escribe `selected_tower` en el `LevelState`. Es el único camino de la barra lateral a la selección.
- `_on_inspect_requested(data)`: recibe `Sidebar.inspect_requested` y escribe `inspected` en el `LevelState`. Es el único camino a lo inspeccionado.
- `show_game_over()`: muestra la pantalla y pausa el árbol. `hide_game_over()` la oculta.
- Acción `ui_cancel` (Escape): alterna el menú de pausa y la pausa del árbol, salvo si se ve el game over.

Señales: `restart_requested` y `quit_requested`. Las emite cuando se pulsa el botón correspondiente en pausa o en game over, después de quitar la pausa.

## InfoPanel (ficha)

`scenes/level_ui/InfoPanel.tscn` + `scripts/level_ui/InfoPanel.gd` (clase `InfoPanel`). `PanelContainer` con el tema `menu_theme.tres` y el estilo de barra; dentro del margen quedan 72x264 px, unos 9 caracteres por línea a 8 px. Es un marco fijo: la barra no aparece, desaparece ni cambia de tamaño; solo cambia lo de dentro.

Estructura (`Content`, `VBoxContainer` con 4 px de separación):

- `TitleHeader`: cabecera fija "FICHA" en cian `#40e0f0`, con el mismo estilo que `MoneyHeader` (`money_header_style.tres`).
- `Screen`: el resto de la barra. Contiene las dos vistas, de las que solo una es visible, y `ScanFlash`.
- **`IdleView` (reposo):** el escáner (`ScannerDisplay`, ver abajo), "SIN OBJETIVO" en ámbar `#ecb23c` y la ayuda "Clic derecho para analizar" en `#7fa6b8`, ambos con salto de línea automático y centrados. Se ve al empezar el nivel y al reiniciar; en cuanto se inspecciona algo no vuelve hasta el siguiente reinicio.
- **`DetailView`:**
  - Cabecera fija: `IconPad` (72x38) con el icono a 32x32 centrado, fondo `#060b14` con una rejilla de puntos `#14304a` cada 4 px y esquinas de 4 px en el color de acento (se pinta en el `draw` de `IconPad`); `NameLabel` con el nombre partido por palabras en líneas de 9 caracteres, 2 como mucho (una palabra más larga se corta con guion: "Disinteg-rator"), con alto fijo de 2 líneas para que la cabecera mida siempre lo mismo; y `TypeTag` con la etiqueta del tipo de ataque en el color de acento sobre el fondo mezclado al 20 % con el acento. El nombre no se pasa a mayúsculas porque PressStart2P dibuja mal las mayúsculas con tilde.
  - `StatScroll`: `ScrollContainer` vertical (sin barra visible, como los de la barra derecha) con las filas de stat, una línea `#1c4a60` y la descripción en `#7fa6b8` con salto de línea automático (la línea y la descripción se ocultan si no hay descripción). La cabecera no entra en el scroll. Al cambiar de ficha vuelve arriba.
  - Cada fila es un `PanelContainer` (1 px de margen, fondo alterno `#0e1626` / `#0a0f1a`) con el icono de 8x8 a la izquierda y el valor a la derecha en `#befaff`. Su `tooltip_text` es el nombre del stat; `mouse_filter = PASS` para que la rueda siga llegando al scroll.
- `ScanFlash`: `ColorRect` cian al 20 % que tapa `Screen` durante 2 frames cada vez que cambia el contenido.

`show_inspected(data: Resource)`: con un `TowerData` pinta su icono, `name`, `get_attack_label()`, `accent_color`, `get_stats()` y `description`; con null, el reposo. La ficha no sabe qué stats existen: crea una fila por cada `StatEntry` que recibe.

**`StatEntry`** (`scripts/level_ui/StatEntry.gd`, `RefCounted`): `icon: Texture2D`, `label: String` y `value: String` ya formateado. `StatEntry.new(icon_name, label, value)` carga `assets/ui/stat_icons/<icon_name>.png`. `MAX_VALUE_CHARS = 7` es lo que cabe en el valor. Las filas las dan `TowerData.get_stats()` y los `get_stats()` de cada tipo de ataque (ver [torres.md](torres.md)).

**`ScannerDisplay`** (`scripts/level_ui/ScannerDisplay.gd`, `Control` de 57x57): radar de reposo. Pinta 32 frames del barrido píxel a píxel en `Image` (sin antialiasing) la primera vez y los reparte entre instancias; avanza un frame cada 0,06 s (unos 1,9 s por vuelta) solo mientras es visible. Disco `#0e1626`, anillo `#1c7496` de radio 27 con marcas `#40e0f0` en los cuatro puntos cardinales, anillos interiores y cruz punteados en `#1c4a60`, línea de barrido `#befaff` y estela en dos tramos (`#1c7496` hasta 25°, `#14304a` hasta 70°). Cuatro ecos de 1 px se encienden en `#befaff` al pasar el barrido y se apagan pasando por `#40e0f0`.

**Interacción:**

- Clic derecho en un `TowerButton` (aunque no se pueda pagar y con el juego en pausa): enseña su ficha sin seleccionarla.
- Clic izquierdo: la selecciona (si se puede pagar) y enseña su ficha.
- Deseleccionar (clic derecho en el mapa o quedarse sin dinero) no cambia la ficha.
- `TowerButton.inspect_requested` → `Sidebar.inspect_requested` → `LevelUI` escribe `LevelState.inspected` → `LevelState.inspected_changed` → `InfoPanel.show_inspected`. Nadie más guarda qué está inspeccionado.

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
- Señal `inspect_requested(data)`: reenvía la de cada `TowerButton`; petición de enseñar algo en la ficha.
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
- Señal `inspect_requested(data)`: petición de enseñar la torre en la ficha. La emiten el clic izquierdo (antes de comprobar el dinero) y el clic derecho, que se recoge en `_gui_input` y se marca como gestionado.

## Pestaña Oleadas

`WavesPage` (dentro de `Sidebar`), de arriba abajo: `WaveHeader` fijo (mismo estilo que `MoneyHeader`) con `WaveLabel` en cian `#40e0f0`; `WaveControls`, una fila fija con los dos controles de oleada; y `WaveScroll` (scroll vertical sin barra visible) con `WaveBlocks`, un `VBoxContainer` con un `WaveBlock` por oleada (6 px de separación).

- **Cabecera:** `"OL. X/Y"` (X = última oleada lanzada desde 1, Y = total). La forma larga no cabe en 72 px a 8 px de fuente. Antes de lanzar ninguna muestra `"OL. 0/Y"`.
- **Controles** (`WaveControls`, `HBoxContainer` con 4 px de separación y dos botones de 34x18 sin foco). No caben junto a la cabecera, que ya ocupa 56 de los 66 px útiles, así que van en su propia fila, fuera del scroll. Los estilos se crean en `Sidebar._style_wave_controls()` con bordes de 1 px:
  - `NextWaveButton`: icono `assets/ui/wave_next.png` (▶▶ cian), tooltip "Siguiente oleada". Activo: fondo `#0e1626`, borde `#1c7496`; hover con borde `#40e0f0`. Cuando no se puede lanzar (quedan enemigos de la oleada actual por salir o vivos, o no quedan oleadas) está `disabled`: fondo `#0a0f1a`, borde `#1c4a60` e icono al 30 %. Antes de la primera oleada, si se puede pulsar, su borde parpadea entre `#1c7496` y `#befaff` (0,5 s cada medio ciclo) para invitar a empezar. Emite `Sidebar.next_wave_requested`.
  - `AutoWaveButton`: `toggle_mode`, icono `assets/ui/wave_auto.png` (rayo ámbar), tooltip sobre AUTO. Apagado: borde `#1c4a60` e icono al 30 %; encendido: fondo `#453d2b` (fondo mezclado al 25 % con ámbar), borde `#ecb23c` e icono a plena luz. Emite `Sidebar.auto_waves_toggled(enabled)`, que es una petición: el estado lo guarda `Spawner.auto_waves` y la barra lo refleja con `show_auto_waves(enabled)` (sin volver a emitir).
  - `Sidebar.set_next_wave_available(available, inviting)` activa o atenúa el botón y arranca o para el parpadeo.
- `Sidebar.build_waves(waves)`: borra los bloques anteriores y crea uno por `WaveData`. `Sidebar.set_current_wave(index, total)`: actualiza cabecera y estados, y tras esperar un frame desplaza la lista para que el título del bloque en curso (o el primero, antes de empezar) quede arriba; también se hace al volver a la pestaña.
- **`WaveBlock`** (`scenes/level_ui/WaveBlock.tscn` + `scripts/level_ui/WaveBlock.gd`): título `"OLEADA N"` en un panel de 72 px y una rejilla de 2 columnas (34 px, 4 px de separación) de `EnemyCell`. Agrupa las entradas por `EnemyData`, con el total de cada tipo, en orden de primera aparición (por `time`). No hay datos de enemigos en la UI.
- **Estados:** `WaveBlock.set_state`. En curso (la última lanzada): título con fondo `#14304a`, borde y texto `#40e0f0`. Pasada: todo el bloque al 40 % de opacidad. Próxima (la siguiente a la última lanzada; antes de empezar, la primera): título con fondo `#0e1626`, borde `#96641e` y texto `#ecb23c`. Futura: título con fondo `#0e1626`, borde `#1c4a60` y texto `#7fa6b8`.
- **`EnemyCell`** (`scenes/level_ui/EnemyCell.tscn` + `scripts/level_ui/EnemyCell.gd`): `Button` de 34x44 con los colores de `TowerButton`. Sprite = primer frame de `up` a escala 1, centrado en un área de 34x34 (el Spikey, de 34, ocupa todo el ancho de la celda y pisa el borde), y debajo `"×N"` a 8 px (abreviado con `UiFormat`). Tooltip con el nombre. Emite `enemy_clicked(data)`, que de momento nadie escucha.
- `LevelUI.setup(..., spawner)` llama a `_connect_spawner`: desconecta el `Spawner` anterior si lo había, construye los bloques con `spawner.waves`, refleja la oleada (`get_wave_index()`) y AUTO, y conecta `wave_started`, `wave_cleared` y `auto_waves_changed`. Tras cada cambio de oleada, `_refresh_wave_controls()` pide a la barra que active el botón según `spawner.can_start_next_wave()` y que parpadee si aún no ha empezado ninguna. `next_wave_requested` llama a `spawner.start_next_wave()` y `auto_waves_toggled` escribe `spawner.auto_waves`.

## UiFormat

`scripts/level_ui/UiFormat.gd` (clase `UiFormat`). `UiFormat.abbreviate(amount: int) -> String`: hasta 9999 tal cual; después `12.3K`, `123K`, `1.2M`, `1.5B`, con 5 caracteres como máximo. Trunca en vez de redondear y quita el decimal si es 0 (`10K`, no `10.0K`). La usan el dinero y los costes.

- `UiFormat.number(value: float)`: para stats. Por debajo de 100 y con decimales, uno como mucho (`2.5`); si no, `abbreviate` del valor redondeado.
- `UiFormat.seconds(value: float)`: segundos con 2 decimales como mucho, sin ceros sobrantes y en 5 caracteres como máximo (`0.25s`, `1.5s`, `5s`, `123s`).

## PauseMenu

`scenes/level_ui/PauseMenu.tscn` + `scripts/level_ui/PauseMenu.gd`. Fondo negro al 59 %, título "PAUSA" y botones "Continuar", "Reiniciar" y "Salir". Señales `resume_requested`, `restart_requested` y `quit_requested`.

## GameOverScreen

`scenes/level_ui/GameOver.tscn` + `scripts/level_ui/GameOverScreen.gd`. Fondo negro al 59 %, título "GAME OVER" y botones "Reiniciar" y "Salir". Señales `restart_requested` y `quit_requested`.

## Comunicación con el resto

| Origen | Señal | Destino |
|---|---|---|
| `LevelState` | `money_changed` | `Sidebar.set_money` |
| `LevelState` | `selected_tower_changed` | `Sidebar.show_selected` |
| `LevelState` | `inspected_changed` | `InfoPanel.show_inspected` |
| `Spawner` | `wave_started` | `LevelUI._on_wave_started` (`Sidebar.set_current_wave` y controles) |
| `Spawner` | `wave_cleared` | `LevelUI._on_wave_cleared` (controles) |
| `Spawner` | `auto_waves_changed` | `Sidebar.show_auto_waves` |
| `Sidebar` | `tower_selected` | `LevelUI._on_tower_selected` (escribe en `LevelState`) |
| `Sidebar` | `inspect_requested` | `LevelUI._on_inspect_requested` (escribe `LevelState.inspected`) |
| `Sidebar` | `next_wave_requested` | `LevelUI._on_next_wave_requested` (`Spawner.start_next_wave`) |
| `Sidebar` | `auto_waves_toggled` | `LevelUI._on_auto_waves_toggled` (escribe `Spawner.auto_waves`) |
| `LevelUI` | `restart_requested` | `Game._restart_level` |
| `LevelUI` | `quit_requested` | `Game._quit_to_menu` |
| `Game` | llamada directa | `LevelUI.show_game_over` / `hide_game_over` |

## Dudas

- La interfaz no muestra la vida de la base.
- La ficha solo enseña torres; `EnemyCell.enemy_clicked` aún no está conectado.
- El scroll de la ficha no tiene barra visible: en las fichas que no caben (Cryo, Disintegrator) la descripción queda cortada abajo sin otra pista de que se puede bajar.
- El nodo raíz se llama `LevelUI` y el archivo `LevelUI.gd`, pero la clase es `GameUI`. El contenedor vertical de `GameOver.tscn` se llama `HBoxContainer`.
