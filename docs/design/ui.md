# UI de nivel

Todo cuelga de `scenes/level_ui/LevelUI.tscn`, instanciada dentro de `Game`. Los textos están en español y el tema es `assets/ui/menu_theme.tres`.

## LevelUI

`scripts/level_ui/LevelUI.gd` (clase `LevelUI`), raíz `CanvasLayer` con `process_mode = ALWAYS` para seguir respondiendo con el juego en pausa.

Estructura: `UI/HBoxContainer` (sin separación) con tres columnas, de izquierda a derecha:

- `InfoPanel`: barra izquierda, 128 px, con la ficha (ver más abajo).
- `GameArea`: zona del mapa, ocupa el resto (704x540 px con el viewport de 960x540). Contiene `FpsLabel`, `GameOverScreen`, `VictoryScreen` y `PauseMenu`, ocultos al empezar, así que el oscurecido y los menús no tapan las barras. El mapa se centra en esta columna desde `Level` (ver [niveles.md](niveles.md)).
- `Sidebar`: barra derecha, 128 px.

`GameArea` contiene además `LevelIndicator`, declarado antes que las pantallas para que estos lo tapen.

Las dos barras usan el mismo estilo, `assets/ui/side_panel_style.tres`: `StyleBoxFlat` opaco con el fondo del tema (`#0a0f1a`), borde de 1 px en cian oscuro `#1c7496` y 4 px de margen interior en cada lado.

- `FpsLabel`: arriba a la izquierda del área de juego, muestra `"%d FPS"` cada frame. Solo se ve con la opción `show_fps` de `Settings` activada; `LevelUI` escucha `Settings.changed`, así que aparece o desaparece al momento. `_process` solo está activo mientras se ve.

Funciones de `LevelUI`:

- `setup(state, towers, level_number, spawner, has_next_level)`: oculta la opción `NEXT_LEVEL` de `VictoryScreen` si `has_next_level` es false (`LevelUI` no lee `GameData`; se lo dice `Game`), pasa el número de nivel al `LevelIndicator`, prepara la pestaña Oleadas (ver más abajo), conecta `state.money_changed` a `sidebar.set_money`, `state.selected_tower_changed` a `sidebar.show_selected` y `state.inspected_changed` a `info_panel.show_inspected`, crea los botones de torre, muestra el dinero inicial y pide a la ficha que enseñe `state.inspected` (null en un `LevelState` nuevo, así que al empezar o reiniciar vuelve al escáner). Si había un `LevelState` anterior, desconecta las tres.
- `_on_tower_selected(data)`: recibe `Sidebar.tower_selected` y escribe `selected_tower` en el `LevelState`. Es el único camino de la barra lateral a la selección.
- `_on_inspect_requested(data)`: recibe `Sidebar.inspect_requested` y escribe `inspected` en el `LevelState`. Es el único camino a lo inspeccionado.

**Estado de la UI.** Enum `UiState { PLAYING, PAUSED, LOST, WON }` guardado en `_ui_state`. `set_state(new_state)` es la única función que escribe la visibilidad de las pantallas, `get_tree().paused` y `Engine.time_scale`:

| Estado | Pantalla | Pausa |
|---|---|---|
| `PLAYING` | ninguna | no |
| `PAUSED` | `PauseMenu` | sí |
| `LOST` | `GameOverScreen`, tras la cámara lenta | sí, tras la cámara lenta |
| `WON` | `VictoryScreen`, tras el respiro | sí, tras el respiro |

La relación estado → pantalla está solo en el diccionario `_screens_by_state`; una pantalla nueva se añade ahí. `_ready` conecta `option_chosen` de todas las pantallas del diccionario y empieza en `PLAYING`.

- Acción `ui_cancel` (Escape): en `PLAYING` pasa a `PAUSED` y en `PAUSED` vuelve a `PLAYING`. En `LOST` y `WON` (también durante la cámara lenta y el respiro) no hace nada (ni marca el evento como gestionado).
- Bloqueo de la selección: `set_state` es lo único que lo decide. Llama a `sidebar.set_selection_locked(new_state != PLAYING)`, así que con pausa (plegada o no), derrota (desde que empieza la cámara lenta) o victoria (desde que empieza el respiro) no se puede seleccionar torre.
- `show_run_stats(stats: RunStats)`: pasa el resumen de partida a `GameOverScreen` y a `VictoryScreen`. Lo llama `Game` antes de `set_state(LOST)` o `set_state(WON)`; la UI no lee el `Level` ni el `LevelState` para el resumen.

**Secuencias de derrota y victoria.** `set_state(LOST)` y `set_state(WON)` no congelan el juego de golpe. Las dos usan el mismo tween (`_screen_delay`):

1. Quita cualquier pantalla, deja el árbol sin pausa y bloquea la selección.
2. En `LOST`, cámara lenta: el tween baja `Engine.time_scale` de 1 a `SLOW_MOTION_MIN_SCALE` (0,2) en `SLOW_MOTION_RAMP_TIME` (1,1 s) con curva seno de entrada y salida, y lo mantiene `SLOW_MOTION_HOLD_TIME` (0,2 s). En `WON`, respiro: el tween espera `VICTORY_BREATH_TIME` (0,6 s) con el juego a velocidad normal, para que se vea explotar al último enemigo; no toca `Engine.time_scale`. El tween usa `set_ignore_time_scale()` (tiempo real, no se frena a sí mismo) y `TWEEN_PAUSE_PROCESS`.
3. Al acabar, `Engine.time_scale` vuelve a 1, el árbol se pausa y se enseña la pantalla del estado: `GameOverScreen` arranca su glitch y `VictoryScreen` su entrada.

Cada llamada a `set_state` mata la secuencia en curso (si la hay) y pone `Engine.time_scale` a 1 antes de nada, así que cualquier cambio de estado durante la cámara lenta o el respiro lo cancela y `PLAYING` siempre deja la velocidad normal. Las escrituras de `time_scale` y `paused` del tween están en lambdas dentro de `set_state`.
- `_on_option_chosen(option)`: `RESUME` pasa a `PLAYING`. `RESTART`, `QUIT` y `NEXT_LEVEL` pasan a `PLAYING` (quitan pantalla y pausa) y después emiten `action_requested`.

Señal: `action_requested(action: Action)`, con el enum `Action { RESTART, QUIT, NEXT_LEVEL }`. Es la única señal de `LevelUI` hacia `Game`.

## InfoPanel (ficha)

`scenes/level_ui/InfoPanel.tscn` + `scripts/level_ui/InfoPanel.gd` (clase `InfoPanel`). `PanelContainer` con el tema `menu_theme.tres` y el estilo de barra; dentro del margen quedan 120x532 px. El nombre sigue partido en líneas de 9 caracteres a 8 px, calculadas para 72 px, que caben de sobra. Es un marco fijo: la barra no aparece, desaparece ni cambia de tamaño; solo cambia lo de dentro.

Estructura (`Content`, `VBoxContainer` con 4 px de separación):

- `TitleHeader`: cabecera fija "FICHA" en cian `#40e0f0`, con el mismo estilo que `MoneyHeader` (`money_header_style.tres`).
- `Screen`: el resto de la barra. Contiene las dos vistas, de las que solo una es visible, y `ScanFlash`.
- **`IdleView` (reposo):** el escáner (`ScannerDisplay`, ver abajo), "SIN OBJETIVO" en ámbar `#ecb23c` y la ayuda "Clic derecho para analizar" en `#7fa6b8`, ambos con salto de línea automático y centrados. Se ve al empezar el nivel y al reiniciar; en cuanto se inspecciona algo no vuelve hasta el siguiente reinicio.
- **`DetailView`:**
  - Cabecera fija: `IconPad` (todo el ancho útil, 42 px de alto) con el icono a escala 1 centrado (cabe el Spikey de 34x34), fondo `#060b14` con una rejilla de puntos `#14304a` cada 4 px y esquinas de 4 px en el color de acento (se pinta en el `draw` de `IconPad`); `NameLabel` con el nombre partido por palabras en líneas de 9 caracteres, 2 como mucho (una palabra más larga se corta con guion: "Disinteg-rator"), con alto fijo de 2 líneas para que la cabecera mida siempre lo mismo; y `TypeTag` con la etiqueta del tipo (de ataque en las torres, "ENEMIGO" en los enemigos) en el color de acento sobre el fondo mezclado al 20 % con el acento. El nombre no se pasa a mayúsculas porque PressStart2P dibuja mal las mayúsculas con tilde.
  - `StatScroll`: `ScrollContainer` vertical (sin barra visible, como los de la barra derecha) con las filas de stat, una línea `#1c4a60` y la descripción en `#7fa6b8` con salto de línea automático (la línea y la descripción se ocultan si no hay descripción). La cabecera no entra en el scroll. Al cambiar de ficha vuelve arriba.
  - Cada fila la crea `StatRow.create(entry, index)` (ver abajo).
- `ScanFlash`: `ColorRect` cian al 20 % que tapa `Screen` durante 2 frames cada vez que cambia el contenido.

`show_inspected(data: Resource)`: con un `InspectableData` pinta lo que da el contrato común; con null (o cualquier otra cosa), el reposo. La ficha no distingue torres de enemigos ni sabe qué stats existen: crea una fila por cada `StatEntry` que recibe.

**`InspectableData`** (`scripts/resources/InspectableData.gd`, `Resource`): contrato de lo inspeccionable, que cumplen `TowerData` y `EnemyData` y cualquier cosa futura que se quiera enseñar (torres colocadas, enemigos del mapa). Métodos: `get_inspect_icon()`, `get_inspect_name()`, `get_inspect_tag()` (9 caracteres como máximo), `get_inspect_accent()`, `get_stats()` y `get_inspect_description()`. Los valores por defecto están vacíos. Torres: icono, `name`, tipo de ataque, `accent_color` y `description`. Enemigos: primer frame de `up`, `name`, "ENEMIGO", `EnemyData.ACCENT_COLOR` (rojo de motor `#f0323c`), y `description`.

**`StatEntry`** (`scripts/level_ui/StatEntry.gd`, `RefCounted`): `icon: Texture2D`, `label: String` y `value: String` ya formateado. `StatEntry.new(icon_name, label, value)` carga `assets/ui/stat_icons/<icon_name>.png`. `MAX_VALUE_CHARS = 7` es lo que cabe en el valor. Las filas las dan `TowerData.get_stats()` y los `get_stats()` de cada tipo de ataque (ver [torres.md](torres.md)).

**`StatRow`** (`scripts/level_ui/StatRow.gd`): `StatRow.create(entry, index, h_margin = 1, v_margin = 1)` devuelve la fila de un `StatEntry`: `PanelContainer` con fondo alterno según `index` (`#0e1626` / `#0a0f1a`), el icono de 8x8 a la izquierda y el valor a la derecha en `#befaff`. Su `tooltip_text` es el nombre del stat; `mouse_filter = PASS` para que la rueda siga llegando a un scroll. La usan la ficha (márgenes de 1 px) y `RunSummary`.

**`ScannerDisplay`** (`scripts/level_ui/ScannerDisplay.gd`, `Control` de 57x57): radar de reposo. Pinta 32 frames del barrido píxel a píxel en `Image` (sin antialiasing) la primera vez y los reparte entre instancias; avanza un frame cada 0,06 s (unos 1,9 s por vuelta) solo mientras es visible. Disco `#0e1626`, anillo `#1c7496` de radio 27 con marcas `#40e0f0` en los cuatro puntos cardinales, anillos interiores y cruz punteados en `#1c4a60`, línea de barrido `#befaff` y estela en dos tramos (`#1c7496` hasta 25°, `#14304a` hasta 70°). Cuatro ecos de 1 px se encienden en `#befaff` al pasar el barrido y se apagan pasando por `#40e0f0`.

**Interacción:**

- Clic derecho en un `TowerButton` (aunque no se pueda pagar y con el juego en pausa): enseña su ficha sin seleccionarla.
- Clic izquierdo: la selecciona (si se puede pagar) y enseña su ficha. Con una pantalla abierta (selección bloqueada) solo enseña la ficha, sin seleccionar ni soltar; la torre ya seleccionada se conserva.
- Clic izquierdo o derecho en una `EnemyCell` de la pestaña Oleadas (también en pausa): enseña la ficha del enemigo sin tocar la selección de torre.
- Deseleccionar (clic derecho en el mapa o quedarse sin dinero) no cambia la ficha.
- `TowerButton.inspect_requested` → `Sidebar.inspect_requested` (o `EnemyCell.inspect_requested` → `WaveBlock.inspect_requested` → `Sidebar.inspect_requested`) → `LevelUI` escribe `LevelState.inspected` → `LevelState.inspected_changed` → `InfoPanel.show_inspected`. Nadie más guarda qué está inspeccionado.

## LevelIndicator

`scenes/level_ui/LevelIndicator.tscn` + `scripts/level_ui/LevelIndicator.gd` (clase `LevelIndicator`). `PanelContainer` anclado arriba en el centro de `GameArea` (3 px de margen superior) con un `Label` "NIVEL N" a 8 px. Estilo `assets/ui/level_indicator_style.tres`: mismo fondo y borde que las barras, pero con 4 px de margen horizontal y 2 px vertical (unos 14 px de alto). `mouse_filter = IGNORE` en el panel y en el `Label`.

- Número: `Game` lo calcula como la posición de `level_data` en `GameData.levels` más 1 y lo pasa por `LevelUI.setup`. Si el nivel no está en la lista (0), el indicador se oculta.
- Se ve con opacidad 0,7. Si el cursor o algún nodo del grupo `enemies` está dentro de su rectángulo (con 4 px de margen), baja a 0,15 con un tween de 0,15 s; al salir, vuelve a 0,7. Se comprueba en `_process`, que sigue activo con el juego en pausa.

## Sidebar

`scenes/level_ui/Sidebar.tscn` + `scripts/level_ui/Sidebar.gd` (clase `Sidebar`). Estilo de barra compartido con `InfoPanel`. Dentro del margen de 4 px quedan 120 px de ancho útil. Lo que se estira con los contenedores (cabeceras de dinero y de oleada, títulos de `WaveBlock`) ocupa todo ese ancho; lo de ancho fijo (pestañas, controles de oleada, rejilla de torres y rejillas de enemigos) va centrado en horizontal, con el mismo tamaño que antes.

- **Pestañas:** `TabBar` con dos botones de icono de 16x16 (`TowersTab` y `WavesTab`, 34x24, en un `ButtonGroup`, centrados con 4 px de separación) y una página por pestaña (`TowersPage`, `WavesPage`) de las que solo una es visible. No hay texto: el nombre ("Torres", "Oleadas") sale en el tooltip. Torres está activa al empezar. Los iconos son `assets/ui/tab_towers.png` y `tab_waves.png`. Los estilos de pestaña se crean en `_ready`: la inactiva tiene borde `#1c4a60` e icono atenuado; la activa, fondo `#14304a`, borde `#40e0f0` e icono a plena luz. Ver "Pestaña Oleadas" para `WavesPage`.
- **`TowersPage`:** `MoneyHeader` (`PanelContainer` con `assets/ui/money_header_style.tres`) con `MoneyLabel` centrado en ámbar `#ecb23c`, formato `"%s€"` con `UiFormat.abbreviate`. Debajo, `TowerScroll` (`ScrollContainer`, scroll vertical sin barra visible, horizontal desactivado) con `TowerCenter` (`CenterContainer` que ocupa el ancho del scroll y centra la rejilla) y dentro `TowerButtons`, un `GridContainer` de 2 columnas con 4 px de separación (2 x 34 + 4 = 72 px de ancho). El dinero no entra en el scroll, así que no se mueve.
- `build_buttons(towers)`: borra los botones anteriores y crea un `TowerButton` por torre.
- `set_money(amount)`: actualiza la etiqueta y avisa a cada botón.
- Señal `tower_selected(data)`: petición de cambio, con la torre al pulsar un botón y con `null` al soltarla. No guarda la selección.
- Señal `inspect_requested(data)`: reenvía la de cada `TowerButton`; petición de enseñar algo en la ficha.
- `set_selection_locked(locked)`: guarda el bloqueo, atenúa `TowerButtons` al 50 % (la cabecera del dinero no cambia) y se lo pasa a cada `TowerButton` (también a los que cree `build_buttons`). Solo lo llama `LevelUI.set_state`.
- `show_selected(data)`: marca el botón de esa torre y desmarca los demás (todos con `null`). No emite nada.

## TowerButton

`scenes/level_ui/TowerButton.tscn` + `scripts/level_ui/TowerButton.gd` (clase `TowerButton`). `Button` de 34x44 sin `toggle_mode` ni `ButtonGroup`, sin foco: el estado seleccionado es solo visual y lo dicta `Sidebar.show_selected` mediante `set_selected`.

- Contenido: `data.icon` a 32x32 (sin escalar) y debajo el coste, a 8 px. El coste se abrevia con `UiFormat.abbreviate` y lleva `€` solo si el texto resultante tiene menos de 4 caracteres (el botón solo tiene sitio para 4 de 8 px). Tooltip con el nombre de la torre.
- Estados (estilos `StyleBoxFlat` de 1 px, sin antialiasing, creados en `_refresh`):
  - Normal: fondo `#0e1626`, borde `#1c7496`.
  - Hover: fondo `#16243c`, borde `#40e0f0`.
  - Seleccionada: borde con `data.accent_color`, fondo mezclado con el acento (25 %); con el ratón encima, 40 % y borde más claro.
  - Sin dinero: icono al 35 % de opacidad y coste en rojo `#ff3c5a` (con dinero, ámbar `#ecb23c`); sin resalte al pasar el ratón. El botón no está `disabled`, así que recibe todos los eventos de ratón (para el clic derecho de la ficha), pero el clic izquierdo no hace nada.
- Señal `selection_changed(data, on)`: petición, no estado. Con `set_selection_locked(true)` no se emite (ni por clic ni por quedarse sin dinero; al desbloquear, si la torre seleccionada ya no se puede pagar, pide soltarla). El clic izquierdo pide seleccionar (`on = true`) o, si ya estaba seleccionada, soltar. Si estando seleccionada deja de llegarle el dinero, pide soltarla.
- Señal `inspect_requested(data)`: petición de enseñar la torre en la ficha. La emiten el clic izquierdo (antes de comprobar el dinero) y el clic derecho, que se recoge en `_gui_input` y se marca como gestionado.

## Pestaña Oleadas

`WavesPage` (dentro de `Sidebar`), de arriba abajo: `WaveHeader` fijo (mismo estilo que `MoneyHeader`) con `WaveLabel` en cian `#40e0f0`; `WaveControls`, una fila fija con los dos controles de oleada; y `WaveScroll` (scroll vertical sin barra visible) con `WaveBlocks`, un `VBoxContainer` con un `WaveBlock` por oleada (6 px de separación).

- **Cabecera:** `"OL. X/Y"` (X = última oleada lanzada desde 1, Y = total). La forma corta viene de cuando la barra tenía 72 px útiles; se revisa con la fuente nueva. Antes de lanzar ninguna muestra `"OL. 0/Y"`.
- **Controles** (`WaveControls`, `HBoxContainer` centrado con 4 px de separación y dos botones de 34x18 sin foco). Van en su propia fila, fuera del scroll. Los estilos se crean en `Sidebar._style_wave_controls()` con bordes de 1 px:
  - `NextWaveButton`: icono `assets/ui/wave_next.png` (▶▶ cian), tooltip "Siguiente oleada". Activo: fondo `#0e1626`, borde `#1c7496`; hover con borde `#40e0f0`. Cuando no se puede lanzar (quedan enemigos de la oleada actual por salir o vivos, o no quedan oleadas) está `disabled`: fondo `#0a0f1a`, borde `#1c4a60` e icono al 30 %. Antes de la primera oleada, si se puede pulsar, su borde parpadea entre `#1c7496` y `#befaff` (0,5 s cada medio ciclo) para invitar a empezar. Emite `Sidebar.next_wave_requested`.
  - `AutoWaveButton`: `toggle_mode`, icono `assets/ui/wave_auto.png` (rayo ámbar), tooltip sobre AUTO. Apagado: borde `#1c4a60` e icono al 30 %; encendido: fondo `#453d2b` (fondo mezclado al 25 % con ámbar), borde `#ecb23c` e icono a plena luz. Emite `Sidebar.auto_waves_toggled(enabled)`, que es una petición: el estado lo guarda `Spawner.auto_waves` y la barra lo refleja con `show_auto_waves(enabled)` (sin volver a emitir).
  - `Sidebar.set_next_wave_available(available, inviting)` activa o atenúa el botón y arranca o para el parpadeo.
- `Sidebar.build_waves(waves)`: borra los bloques anteriores y crea uno por `WaveData`. `Sidebar.set_current_wave(index, total)`: actualiza cabecera y estados, y tras esperar un frame desplaza la lista para que el título del bloque en curso (o el primero, antes de empezar) quede arriba; también se hace al volver a la pestaña.
- **`WaveBlock`** (`scenes/level_ui/WaveBlock.tscn` + `scripts/level_ui/WaveBlock.gd`): título `"OLEADA N"` en un panel que ocupa el ancho de la barra y una rejilla `Cells` de 2 columnas (34 px, 4 px de separación) de `EnemyCell`, centrada en horizontal. Agrupa las entradas por `EnemyData`, con el total de cada tipo, en orden de primera aparición (por `time`). No hay datos de enemigos en la UI.
- **Estados:** `WaveBlock.set_state`. En curso (la última lanzada): título con fondo `#14304a`, borde y texto `#40e0f0`. Pasada: todo el bloque al 40 % de opacidad. Próxima (la siguiente a la última lanzada; antes de empezar, la primera): título con fondo `#0e1626`, borde `#96641e` y texto `#ecb23c`. Futura: título con fondo `#0e1626`, borde `#1c4a60` y texto `#7fa6b8`.
- **`EnemyCell`** (`scenes/level_ui/EnemyCell.tscn` + `scripts/level_ui/EnemyCell.gd`): `Button` de 34x44 con los colores de `TowerButton`. Sprite = primer frame de `up` a escala 1, centrado en un área de 34x34 (el Spikey, de 34, ocupa todo el ancho de la celda y pisa el borde), y debajo `"×N"` a 8 px (abreviado con `UiFormat`). Tooltip con el nombre. Emite `inspect_requested(data)` con el clic izquierdo y con el derecho (este se recoge en `_gui_input`); `WaveBlock` y `Sidebar` lo reenvían.
- `LevelUI.setup(..., spawner)` llama a `_connect_spawner`: desconecta el `Spawner` anterior si lo había, construye los bloques con `spawner.waves`, refleja la oleada (`get_wave_index()`) y AUTO, y conecta `wave_started`, `wave_cleared` y `auto_waves_changed`. Tras cada cambio de oleada, `_refresh_wave_controls()` pide a la barra que active el botón según `spawner.can_start_next_wave()` y que parpadee si aún no ha empezado ninguna. `next_wave_requested` llama a `spawner.start_next_wave()` y `auto_waves_toggled` escribe `spawner.auto_waves`.

## UiFormat

`scripts/level_ui/UiFormat.gd` (clase `UiFormat`). `UiFormat.abbreviate(amount: int) -> String`: hasta 9999 tal cual; después `12.3K`, `123K`, `1.2M`, `1.5B`, con 5 caracteres como máximo. Trunca en vez de redondear y quita el decimal si es 0 (`10K`, no `10.0K`). La usan el dinero y los costes.

- `UiFormat.number(value: float)`: para stats. Por debajo de 100 y con decimales, uno como mucho (`2.5`); si no, `abbreviate` del valor redondeado.
- `UiFormat.seconds(value: float)`: segundos con 2 decimales como mucho, sin ceros sobrantes y en 5 caracteres como máximo (`0.25s`, `1.5s`, `5s`, `123s`).

## OverlayScreen

`scenes/level_ui/OverlayScreen.tscn` + `scripts/level_ui/OverlayScreen.gd` (clase `OverlayScreen`). Escena base de las pantallas que tapan el área de juego, con el tema `menu_theme.tres`. Contiene lo común:

- `Background`: `ColorRect` que oscurece el área de juego (color `dim_color`, negro por defecto, con opacidad `dim_opacity`).
- `Center` (`CenterContainer`) → `Frame` (`OverlayFrame`, ver abajo) → `Margin` (20 px a los lados, 16 arriba y abajo) → `Box` (`VBoxContainer`, 10 px de separación):
  - `Title` (`%Title`, `title_label`): fuente de 24 px en `#cce6ff` con contorno negro de 4 px, centrado. En la base no tiene texto.
  - `Options` (`%Options`, `options`): `VBoxContainer` con 10 px de separación, vacío en la base.

**`OverlayFrame`** (`scripts/level_ui/OverlayFrame.gd`, `PanelContainer`): fondo `#0a0f1a` al 96 %, borde de 1 px en `accent_color` y esquinas en L (5 px de largo, 2 de grueso) del mismo color pintadas en `_draw`. También lo usa la etiqueta plegada de la pausa.

Tres `@export` en la base, que cada escena heredada fija en su `.tscn`:

| Pantalla | `accent_color` | `dim_color` | `dim_opacity` |
|---|---|---|---|
| Pausa | cian `#40e0f0` | negro | 0,35 |
| Derrota | rojo `#ff3c5a` | rojo muy oscuro `#1a0509` | 0,6 |
| Victoria | ámbar `#ecb23c` | negro | 0,45 |

`_ready` aplica el acento al marco y a los botones, el oscurecido al fondo, y conecta el `pressed` de cada `OverlayOptionButton` de `Options`. Enum `Option { RESUME, RESTART, QUIT, NEXT_LEVEL, SETTINGS }` y una sola señal, `option_chosen(option)`.


La pantalla no toca su visibilidad: la decide `LevelUI.set_state()`. Una pantalla con comportamiento propio extiende `OverlayScreen` con un script (como `PauseScreen` y `GameOverScreen`).

**`OverlayOptionButton`** (`scripts/level_ui/OverlayOptionButton.gd`, `Button`): `@export var option` y `@export var accent_color` (se lo pasa la pantalla). Es un juego de ratón: `focus_mode = NONE`, sin teclado salvo Escape (lo gestiona `LevelUI`). Caja de 1 px: fondo `#0e1626` y borde en el acento mezclado al 50 %; con el ratón encima, fondo mezclado al 20 %, borde y texto en el acento y un selector `>` pintado delante (en `_draw`). Texto en `#cce6ff`. Miden 136x24 con 6 px de separación y van centrados en horizontal.

## PauseMenu

`scenes/level_ui/PauseMenu.tscn`, escena heredada de `OverlayScreen.tscn` con el script `scripts/level_ui/PauseScreen.gd` (clase `PauseScreen`). Título "PAUSA" y opciones "Continuar" (`RESUME`), "Opciones" (`SETTINGS`, ver abajo), "Reiniciar" (`RESTART`) y "Salir" (`QUIT`). Aparece al instante, sin animación de entrada.

- **Cursor:** el título es "PAUSA" en cian y a su derecha hay un `Label` "_" (creado en `_add_cursor`, en un `HBoxContainer` con el título) que parpadea cada 0,5 s con la opacidad, así el panel no cambia de tamaño. Se enciende cada vez que se abre la pausa.
- **Plegado:** `FoldButton` (12x12, icono `assets/ui/fold.png`, tooltip "Plegar", sin foco) en la esquina superior derecha del marco. Al pulsarlo se ocultan `Background` y `Frame` y se enseña `FoldedTag`, un `OverlayFrame` cian con "PAUSA" a 8 px, a 3 px de la esquina superior izquierda del área de juego. Plegada no hay oscurecido y el mapa se ve limpio; el juego sigue en pausa. Clic izquierdo en la etiqueta: se despliega. Escape, plegada o no, quita la pausa (lo gestiona `LevelUI`). Al volver a pausar, `_on_shown` la despliega siempre.
- Plegar y desplegar es solo cosa de `PauseScreen`: `LevelUI` sigue en `PAUSED`.
- **Opciones:** `PauseScreen` escucha su propio `option_chosen` y, con `SETTINGS`, abre la instancia de `scenes/OptionsMenu.tscn` que cuelga de `PauseMenu` (`%OptionsMenu`, ver [menu.md](menu.md)) con `open_from(Center)`: el marco de la pausa se funde a las opciones sobre el mismo oscurecido y "Volver" regresa a él. `LevelUI` ignora `SETTINGS`. El juego sigue en pausa todo el rato; las opciones funcionan porque heredan `process_mode = ALWAYS` de `LevelUI`. Si la pausa se cierra con las opciones abiertas (Escape), `PauseScreen` llama a `close()` para que la siguiente pausa empiece por el marco.

## GameOverScreen

`scenes/level_ui/GameOver.tscn` (nodo `GameOverScreen`), escena heredada de `OverlayScreen.tscn` con el script `scripts/level_ui/GameOverScreen.gd` (clase `GameOverScreen`). Es la derrota, con personalidad de "señal perdida" en rojo `#ff3c5a`. Entra tras la cámara lenta (ver "Secuencia de derrota" en `LevelUI`).

- **Aspecto:** título "ESTACION" / "PERDIDA" (dos líneas) en el rojo del acento. Se iba a llamar "SEÑAL PERDIDA", pero PressStart2P encoge la Ñ (cuerpo de 5 px frente a los 7 de la N) para que quepa la tilde. Oscurecido con `dim_color` `#1a0509` (rojo muy oscuro) al 60 %. Entre el título y las opciones va `RunSummary` (`%RunSummary`) con el acento rojo. Opciones "Reintentar" (`RESTART`) y "Menú" (`QUIT`). No conecta botones a mano: lo hace la base.
- **`GlitchLayer`** (`%GlitchLayer`): `ColorRect` entre `Background` y `Center` que tapa el área de juego, con `mouse_filter = IGNORE` y un `ShaderMaterial` con `resources/shaders/defeat_glitch.gdshader`. El shader lee la pantalla ya dibujada (`hint_screen_texture`, filtro nearest), así que trabaja sobre el mapa oscurecido pero no sobre el panel, que se dibuja después. Todo va sobre la rejilla de píxeles de juego (1 px de juego = 1 px del viewport de 960x540), sin desenfoque:
  - Bandas horizontales de 2, 4, 6 u 8 px; con probabilidad `0,4 × intensity` cada banda se desplaza un número entero de píxeles (hasta 40 × `intensity`) y se tiñe un poco de rojo. Las lecturas se limitan al área de juego, así que no entran trozos de las barras.
  - Estática: un `8 % × intensity` de los píxeles pasa a `#ffaabe`.
  - Estática residual (`residual`): algunas filas sueltas con píxeles tenues.
  - Líneas de barrido: una fila de cada dos algo más oscura.
  - El patrón cambia con el uniforme `seed`, que pone el script a saltos.
- **Glitch de entrada** (en `GameOverScreen`, con `delta` real porque la pantalla corre con el árbol en pausa y `time_scale` ya está en 1): cada `GLITCH_STEP_TIME` (0,05 s) cambia `seed`. Durante `INTRO_TIME` (0,5 s) la intensidad baja de 1 a 0,5 con ruido, el marco se ve u oculta al azar (cada vez más probable que se vea) y el título alterna entre visible y tenue. Después la intensidad es 0, `residual` = `RESIDUAL_STATIC` (0,12) y el panel queda estable; cada 2,5 a 5 s el título parpadea durante `TITLE_FLICKER_TIME` (0,15 s). Cada vez que se abre la pantalla, la entrada vuelve a empezar.
- Las barras no se tocan: el glitch solo cubre `GameArea` y las barras siguen activas para inspeccionar.
- `show_run_stats(stats)`: pasa el `RunStats` al `RunSummary`.

## RunSummary

`scenes/level_ui/RunSummary.tscn` + `scripts/level_ui/RunSummary.gd` (clase `RunSummary`). Resumen de partida reutilizable; no sabe en qué pantalla está. `PanelContainer` de 136 px de ancho (lo mismo que las opciones), fondo `#0a0f1a`, borde de 1 px en el acento mezclado al 50 % y 2 px de margen. Dentro, el rótulo "RESUMEN" a 8 px en el acento y las filas.

- `@export var accent_color`: color del rótulo y del borde. La derrota lo pone en rojo y la victoria en ámbar.
- `show_stats(stats: RunStats)`: sustituye las filas por tres `StatRow` (4 px de margen en horizontal y 2 en vertical) con los valores finales de golpe (así los enseña la derrota). Corta un conteo en curso:

| Icono | Tooltip | Valor |
|---|---|---|
| `wave.png` | Oleada | `"X/Y"` (oleada alcanzada / total) |
| `kills.png` | Enemigos destruidos | `UiFormat.abbreviate` |
| `cost.png` | Dinero gastado | `UiFormat.abbreviate` + `€` |

- `count_up(duration, delay = 0.0)`: opcional, después de `show_stats`. Pone enemigos destruidos y dinero gastado a 0 y, tras `delay` segundos, los hace contar hasta su valor en `duration` segundos (tween de tiempo real, curva cuártica que frena al final). Cada paso pasa por `UiFormat.abbreviate`, así que el texto tiene el formato del valor final y las filas (de ancho fijo) no saltan. La oleada no cuenta. `finish_count()` corta el conteo y deja los valores finales; `is_counting()` dice si hay uno en curso. Lo usa la victoria.
- `StatRow.get_value_label(row)` da la etiqueta del valor de una fila para cambiar su texto sin rehacerla.

`RunStats` está en [niveles.md](niveles.md).

## VictoryScreen

`scenes/level_ui/VictoryScreen.tscn` (heredada de `OverlayScreen.tscn`) + `scripts/level_ui/VictoryScreen.gd` (clase `VictoryScreen`, extiende `OverlayScreen`). Pantalla de celebración, contraparte de la derrota. Corre con el árbol en pausa (hereda `process_mode` ALWAYS de `LevelUI`), así que sus tweens y su `delta` son tiempo real.

- **Aspecto:** título "SECTOR" / "ASEGURADO" (dos líneas, sin tildes ni Ñ) en el ámbar del acento `#ecb23c`. Oscurecido negro al 45 %, más ligero que la derrota para que se vea el mapa ganado. Entre el título y las opciones va `RunSummary` (`%RunSummary`) con el acento ámbar. No conecta botones a mano: lo hace la base.
- **Entrada:** cada vez que se abre (`visibility_changed`), el nodo `Center` (que centra el marco) se coloca justo encima del área de juego y baja hasta su sitio en `SLIDE_TIME` (0,35 s): curva cúbica que frena hasta pasarse `SLIDE_OVERSHOOT_PX` (2 px) y vuelve a su sitio en los últimos `SLIDE_SETTLE_TIME` (0,08 s). La posición se redondea a píxeles enteros en cada paso. A la vez, el oscurecido se funde de 0 a su opacidad en `DIM_FADE_TIME` (0,2 s, con el `modulate` de `Background`).
- **Conteo:** al abrirse llama a `run_summary.count_up(COUNT_TIME, SLIDE_TIME)`: los números se ven a 0 mientras baja el marco y cuentan en `COUNT_TIME` (0,8 s) cuando llega. La oleada sale directamente ("Y/Y").
- **Saltar:** clic izquierdo en el oscurecido, el marco o el resumen (no en los botones) durante la entrada o el conteo: lo corta todo y deja el marco en su sitio, el oscurecido entero y los valores finales. Las opciones se pueden pulsar desde el principio. Al cerrarse la pantalla también se deja en su estado final.
- **Destellos:** tres destellos de cuatro puntas junto al título (a la izquierda y arriba a la derecha de "SECTOR" y a la derecha de "ASEGURADO"), pintados sobre el título con su señal `draw` y colocados según el ancho de cada línea. Son píxeles enteros con `draw_rect`, sin antialiasing: cruz de 1 px en `#ecb23c`, centro de 3x3 en cruz en `#ffe082` y, al tamaño máximo de 4 o más, cuatro píxeles en diagonal en `#96641e`. El largo de las puntas sube y baja en pasos de 1 px con un seno de ritmo y fase propios (máximos de 5, 3 y 4 px). No se reutiliza `_draw_sparkle` del menú porque usa polígonos y un halo suave.
- `show_run_stats(stats)`: pasa el `RunStats` al `RunSummary`.

Opciones "Siguiente nivel" (`NEXT_LEVEL`) y "Menú" (`QUIT`, la misma opción que "Salir": lleva a la selección de nivel). `OverlayScreen.set_option_visible(option, visible)` oculta el botón de una opción; `LevelUI.setup` lo usa para quitar "Siguiente nivel" cuando es el último nivel o el nivel no está en la lista.

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
| `PauseMenu`, `GameOverScreen`, `VictoryScreen` | `option_chosen` | `LevelUI._on_option_chosen` (`RESUME` lo resuelve ella) |
| `LevelUI` | `action_requested` | `Game._on_action_requested` (reiniciar, volver al menú o pasar al siguiente nivel) |
| `LevelUI` | llamada directa | `Sidebar.set_selection_locked` (en cada `set_state`) |
| `LevelUI` | llamada directa | `GameOverScreen.show_run_stats` y `VictoryScreen.show_run_stats` (desde `show_run_stats`) |
| `GameOverScreen` | llamada directa | `RunSummary.show_stats` |
| `VictoryScreen` | llamada directa | `RunSummary.show_stats`, `count_up` y `finish_count` |
| `Game` | llamada directa | `LevelUI.show_run_stats(level.get_run_stats())` y después `LevelUI.set_state(LOST)` en la derrota o `set_state(WON)` en la victoria |

## Dudas

- La interfaz no muestra la vida de la base.
- El título de la derrota es "ESTACION PERDIDA" en vez de "SEÑAL PERDIDA" porque la Ñ de PressStart2P sale encogida.
- Durante los 0,5 s del glitch de entrada los botones de la derrota pueden estar invisibles (marco a opacidad 0) pero siguen recibiendo clics.
- El scroll de la ficha no tiene barra visible: en las fichas que no caben (Cryo, Disintegrator) la descripción queda cortada abajo sin otra pista de que se puede bajar.
