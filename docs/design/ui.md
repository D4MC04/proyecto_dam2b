# UI de nivel

Todo cuelga de `scenes/level_ui/LevelUI.tscn`, instanciada dentro de `Game`. Los textos están en español y el tema es `assets/ui/menu_theme.tres`.

## LevelUI

`scripts/level_ui/LevelUI.gd` (clase `LevelUI`), raíz `CanvasLayer` con `process_mode = ALWAYS` para seguir respondiendo con el juego en pausa.

Estructura: `UI/HBoxContainer` (sin separación) con tres columnas, de izquierda a derecha:

- `InfoPanel`: barra izquierda, 128 px, con la ficha (ver más abajo).
- `GameArea`: zona del mapa, ocupa el resto (704x540 px con el viewport de 960x540). Contiene `FpsLabel`, `TurretActions` (oculto hasta seleccionar una torreta, ver más abajo), `GameOverScreen`, `VictoryScreen` y `PauseMenu`, ocultos al empezar, así que el oscurecido y los menús no tapan las barras. El mapa se centra en esta columna desde `Level` (ver [niveles.md](niveles.md)).
- `Sidebar`: barra derecha, 128 px.

`GameArea` contiene además `LevelIndicator`, declarado antes que las pantallas para que estos lo tapen.

Encima de las tres columnas, como último hijo de `UI`, va `TutorialHints` (ver "Tutorial del nivel de emergencia").

### Barras: tablet física

Las dos barras son una tablet: un marco de metal y, dentro, una pantalla oscura. Usan el mismo estilo, `assets/ui/tablet_frame_style.tres`, un `TabletFrameStyle` (`scripts/level_ui/TabletFrameStyle.gd`, `StyleBox` propio con `@tool`) que lo dibuja todo en `_draw` con rectángulos de píxeles enteros, sin texturas ni antialiasing:

- **Marco**, de fuera hacia dentro: contorno de 1 px `#0c0e16`; metal `#606a7c` con bisel de 1 px de luz `#96a2b6` arriba y a la izquierda y 1 px de sombra `#343a4a` abajo y a la derecha; y otro contorno de 1 px `#0c0e16` contra la pantalla. Grosor total: 6 px a los lados, 8 arriba y 18 abajo (`FRAME_SIDE`, `FRAME_TOP`, `FRAME_BOTTOM`).
- **Tornillos** de 3x3 en las cuatro esquinas del metal, a 2 px del borde: cruz con luz `#96a2b6` arriba y a la izquierda y el centro y el resto en `#343a4a`.
- **Rejilla de altavoz** centrada en la franja de abajo: dos filas de 12 puntos `#343a4a` de 1x1, cada 2 px (24 px de ancho).
- **Pantalla:** líneas de barrido (filas alternas `#08111f` y `#060d18`) y corchetes en L de 4 px en `#40e0f0` en las cuatro esquinas.
- **Margen de contenido:** 3 px dentro de la pantalla (`SCREEN_PADDING`). En una barra de 128x540 el contenido queda en 110x508 px, empezando en (9, 11).

**`ScreenHeader`** (`scenes/level_ui/ScreenHeader.tscn` + `scripts/level_ui/ScreenHeader.gd`, `VBoxContainer` con `@tool`): cabecera de pantalla reutilizable. `@export var title` (sin el prefijo); enseña `"// " + title` en `#40e0f0` a 16 px y debajo una regla de marcas pintada en `_draw` de su hijo `Ruler`: línea de 1 px `#1c7496` a todo el ancho con marcas hacia abajo de 2 px cada 4 px y de 3 px cada 16 px (4 px de alto). Se usa en tres sitios: `// ANÁLISIS` arriba de la barra izquierda, `// TORRETAS` entre los créditos y la rejilla de torretas y `// OLEADAS` arriba de la pestaña Oleadas. La regla se pinta con `ScreenHeader.draw_ruler(item, origin, width, color)` (estática), que también usa el panel holograma de `OverlayFrame`.

**Pies:** cada barra acaba con una fila de texto a 16 px dentro de la pantalla. Los dos son un `MarginContainer` con 4 px a cada lado, así que sus textos quedan 4 px más adentro que los botones de encima. La izquierda, `ScanFooter`, es decorativa: solo `ModelLabel` "MK3" a la derecha, en `#1c7496`. La derecha es el pie de oleadas (ver "Pie de la barra").

**Sin tooltips:** ningún control del juego tiene `tooltip_text`. Los nombres que antes salían en tooltip están escritos (filas de stat) o se ven en la ficha (torretas y enemigos).

- `FpsLabel`: arriba a la izquierda del área de juego, muestra `"%d FPS"` cada frame. Solo se ve con la opción `show_fps` de `Settings` activada; `LevelUI` escucha `Settings.changed`, así que aparece o desaparece al momento. `_process` solo está activo mientras se ve.

Funciones de `LevelUI`:

- `setup(state, turrets, level_number, spawner, has_next_level, base)`: oculta la opción `NEXT_LEVEL` de `VictoryScreen` si `has_next_level` es false (`LevelUI` no lee `GameData`; se lo dice `Game`), pasa el número de nivel al `LevelIndicator`, prepara la pestaña Oleadas (ver más abajo), conecta la vida de la base (ver "Vida de la estación"), conecta `state.money_changed` a `sidebar.set_money`, `state.selected_turret_changed` a `sidebar.show_selected` y `state.inspected_changed` a `info_panel.show_inspected`, crea los botones de torreta, muestra el dinero inicial y pide a la ficha que enseñe `state.inspected` (null en un `LevelState` nuevo, así que al empezar o reiniciar vuelve al escáner). Si había un `LevelState` anterior, desconecta las tres.
- `_on_turret_selected(data)`: recibe `Sidebar.turret_selected` y escribe `selected_turret` en el `LevelState`. Es el único camino de la barra lateral a la selección.
- `_input(event)`: cualquier clic sobre un control de la interfaz (barras, ficha, pantallas) suelta la torreta colocada (`sellable_turret = null`, diferido), menos dentro del recuadro de Mejorar y Vender (`turret_actions`): sus botones actúan al soltar el clic y necesitan la torreta. `_on_upgrade_requested` la suelta después de mejorar; al vender desaparece. Los clics sobre el mapa los atiende `BuildManager`. Las barras no emiten nada ni leen el `LevelState`.
- `_on_inspect_requested(data)`: recibe `Sidebar.inspect_requested` y escribe `inspected` en el `LevelState`. Es el único camino a lo inspeccionado.

**Estado de la UI.** Enum `UiState { PLAYING, PAUSED, LOST, WON }` guardado en `_ui_state`. `set_state(new_state)` es la única función que escribe la visibilidad de las pantallas, `get_tree().paused` y `Engine.time_scale`:

| Estado | Pantalla | Pausa |
|---|---|---|
| `PLAYING` | ninguna | no |
| `PAUSED` | `PauseMenu` | sí |
| `LOST` | `GameOverScreen`, tras la cámara lenta | sí, tras la cámara lenta |
| `WON` | `VictoryScreen`, tras el respiro | sí, tras el respiro |

La relación estado → pantalla está solo en el diccionario `_screens_by_state`; una pantalla nueva se añade ahí. `_ready` conecta `option_chosen` de todas las pantallas del diccionario y empieza en `PLAYING`.

- `pause_if_playing()`: pasa a `PAUSED` solo si está en `PLAYING`; en cualquier otro estado no hace nada. La llama `Game` al perder la ventana el foco.
- Acción `ui_cancel` (Escape): en `PLAYING` pasa a `PAUSED` y en `PAUSED` vuelve a `PLAYING`. En `LOST` y `WON` (también durante la cámara lenta y el respiro) no hace nada (ni marca el evento como gestionado).
- **Atajos de teclado** (solo en `PLAYING`; en pausa, derrota y victoria `_handle_shortcut` ni se llama). Acciones del Input Map en `project.godot`: `select_turret_1`…`select_turret_7` (teclas 1-7), `next_wave` (Espacio), `toggle_auto` (A), `toggle_speed` (F), `power_meteor` (Q), `power_freeze` (E) y `power_orbital` (R), por tecla física. `LevelUI._unhandled_input` las traduce a los mismos botones que el ratón: 1-7 llaman a `Sidebar.press_turret_button(i)` (emite `pressed` del i-ésimo `TurretButton` en el orden de la rejilla, así que sin dinero o con selección bloqueada no hacen nada); Espacio emite `pressed` de `NextWaveButton` (el `Spawner` solo lanza si la anterior acabó); A y F invierten `button_pressed` de `AutoWaveButton` y `SpeedButton`; Q, E y R llaman a `_use_power` como los botones de poder. No se escribe la tecla en los botones (salvo en los de poder, ver "Poderes").
- Bloqueo de la selección: `set_state` es lo único que lo decide. Llama a `sidebar.set_selection_locked(new_state != PLAYING)`, así que con pausa (plegada o no), derrota (desde que empieza la cámara lenta) o victoria (desde que empieza el respiro) no se puede seleccionar torreta.
- `show_run_stats(stats: RunStats)`: pasa el resumen de partida a `GameOverScreen` y a `VictoryScreen`. Lo llama `Game` antes de `set_state(LOST)` o `set_state(WON)`; la UI no lee el `Level` ni el `LevelState` para el resumen.

**Secuencias de derrota y victoria.** `set_state(LOST)` y `set_state(WON)` no congelan el juego de golpe. Las dos usan el mismo tween (`_screen_delay`):

1. Quita cualquier pantalla, deja el árbol sin pausa y bloquea la selección.
2. En `LOST`, cámara lenta: el tween baja `Engine.time_scale` de 1 a `SLOW_MOTION_MIN_SCALE` (0,2) en `SLOW_MOTION_RAMP_TIME` (1,1 s) con curva seno de entrada y salida, y lo mantiene `SLOW_MOTION_HOLD_TIME` (0,2 s). En `WON`, respiro: el tween espera `VICTORY_BREATH_TIME` (0,6 s) con el juego a velocidad normal, para que se vea explotar al último enemigo; no toca `Engine.time_scale`. El tween usa `set_ignore_time_scale()` (tiempo real, no se frena a sí mismo) y `TWEEN_PAUSE_PROCESS`.
3. Al acabar, `Engine.time_scale` vuelve a 1, el árbol se pausa y se enseña la pantalla del estado: `GameOverScreen` arranca su glitch y `VictoryScreen` su entrada.

Cada llamada a `set_state` mata la secuencia en curso (si la hay) y pone `Engine.time_scale` a 1 antes de nada (salvo en `PLAYING` con ×2 activo, donde lo pone a `FAST_SPEED` = 2), así que cualquier cambio de estado durante la cámara lenta o el respiro lo cancela. Las escrituras de `time_scale` y `paused` del tween están en lambdas dentro de `set_state`.
- **Velocidad ×2.** `_fast_speed` (bool, empieza en `false`) la cambia `_on_fast_speed_toggled`, que si se está jugando vuelve a llamar a `set_state(PLAYING)` para que `time_scale` se aplique en el único sitio que lo escribe. La pausa la conserva (en pausa `time_scale` es 1 y al reanudar vuelve a 2); `LOST`, `WON` y cualquier acción de `_request_action` (reiniciar, salir, siguiente nivel) la ponen a `false` con `_set_fast_speed(false)`, que también devuelve el botón a "×1". Por eso la cámara lenta y el respiro empiezan siempre desde ×1.
- `_on_option_chosen(option)`: `RESUME` pasa a `PLAYING`. `RESTART`, `QUIT` y `NEXT_LEVEL` pasan a `PLAYING` (quitan pantalla y pausa) y después emiten `action_requested`.

Señal: `action_requested(action: Action)`, con el enum `Action { RESTART, QUIT, NEXT_LEVEL }`. Es la única señal de `LevelUI` hacia `Game`.

## InfoPanel (ficha)

`scenes/level_ui/InfoPanel.tscn` + `scripts/level_ui/InfoPanel.gd` (clase `InfoPanel`). `PanelContainer` con el tema `menu_theme.tres` y el estilo de tablet; dentro quedan 110x508 px. El nombre va en mayúsculas y partido en líneas de 18 caracteres (`NAME_MAX_CHARS`: Monogram a 16 px, 6 px por carácter, en 110 px útiles). Es un marco fijo: la barra no aparece, desaparece ni cambia de tamaño; solo cambia lo de dentro.

Estructura (`Content`, `VBoxContainer` con 4 px de separación):

- `TitleHeader`: `ScreenHeader` fijo con `// ANÁLISIS`.
- `Screen`: el resto de la barra. Contiene las dos vistas, de las que solo una es visible, y `ScanFlash`.
- `ScanFooter`: el pie decorativo "MK3" (ver "Barras: tablet física").
- **`IdleView` (reposo):** el escáner (`ScannerDisplay`, ver abajo), "SIN OBJETIVO" en ámbar `#ecb23c` y la ayuda "Clic derecho para analizar" en `#7fa6b8`, ambos con salto de línea automático y centrados. Se ve al empezar el nivel y al reiniciar; en cuanto se inspecciona algo no vuelve hasta el siguiente reinicio.
- **`DetailView`:**
  - Cabecera fija: `IconPad` (todo el ancho útil, 42 px de alto) con el icono a escala 1 centrado, fondo `#060b14` con una rejilla de puntos `#14304a` cada 4 px y esquinas de 4 px en el color de acento (se pinta en el `draw` de `IconPad`). El acento es fijo por clase: cian `#40e0f0` en todas las torretas y rojo en todos los enemigos; `NameLabel` con el nombre en `#befaff`, en mayúsculas y partido por palabras en líneas de 18 caracteres, 2 como mucho (una palabra más larga se corta con guion: "Disinteg-rator"), con alto fijo de 2 líneas para que la cabecera mida siempre lo mismo; y `TypeTag` con la etiqueta del tipo (de ataque en las torretas, "ENEMIGO" en los enemigos) en el color de acento sobre el fondo mezclado al 20 % con el acento. El nombre se pasa a mayúsculas ("CAÑÓN DOBLE", "LÁSER").
  - `StatScroll`: `ScrollContainer` vertical (sin barra visible, como los de la barra derecha; la pista de que hay más abajo es `ScrollHint`, ver abajo) con las filas de stat, una línea `#1c4a60` y la descripción en `#5a7a96` con salto de línea automático (la línea y la descripción se ocultan si no hay descripción). La cabecera no entra en el scroll. Al cambiar de ficha vuelve arriba.
  - `ScrollHint`: `Control` de 5 px de alto al final de `DetailView` que pinta un triángulo ▼ de 7x4 px en `#40e0f0` centrado. Solo es visible (por transparencia, para que su hueco no cambie el alto del scroll) cuando queda contenido por debajo: `_update_scroll_hint()` mira la `VScrollBar` interna (`value_changed` y `changed`) y lo apaga al llegar al final o si la ficha cabe entera. Se eligió la flecha y no una barra fina porque cabe en el estilo de las esquinas y las marcas del holograma, no roba ancho a los 110 px y se dibuja con rects como el resto; no se usa el glifo ▼ de texto porque Monogram no lo trae seguro.
  - Cada fila la crea `StatRow.create(entry, index)` (ver abajo).
  - Torreta colocada seleccionada: `show_sellable(turret)` (null la quita) añade al final de la ficha dos filas, BAJAS y HECHO (daño), con `turret.kills` y `turret.damage_dealt` abreviados (se rehacen en cada selección, no se actualizan en vivo), y si la torreta está amplificada una tercera con lo que gana (`AmpEffect.get_stat`, icono `amp.png`: p. ej. ÁREA `+50%`, ver [torretas.md](torretas.md) › "Amplificador"). Esa fila sí se rehace en vivo: la ficha escucha `Turret.amplification_changed` de la torreta enseñada. Mejorar y vender ya no están aquí: van en `TurretActions`.
- `ScanFlash`: `ColorRect` cian al 20 % que tapa `Screen` durante 2 frames cada vez que cambia el contenido.
- `PowersHeader` (`ScreenHeader` con `// PODERES`) y `PowersRow` (4 px de separación), entre `Screen` y `ScanFooter`, con `MeteorButton`, `FreezeButton` y `OrbitalButton` (ver "Poderes").

`show_inspected(data: Resource)`: con un `InspectableData` pinta lo que da el contrato común; con null (o cualquier otra cosa), el reposo. La ficha no distingue torretas de enemigos ni sabe qué stats existen: crea una fila por cada `StatEntry` que recibe.

**`InspectableData`** (`scripts/resources/InspectableData.gd`, `Resource`): contrato de lo inspeccionable, que cumplen `TurretData` y `EnemyData` y cualquier cosa futura que se quiera enseñar (torretas colocadas, enemigos del mapa). Métodos: `get_inspect_icon()`, `get_inspect_name()`, `get_inspect_tag()` (9 caracteres como máximo), `get_inspect_accent()`, `get_stats()` y `get_inspect_description()`. Los valores por defecto están vacíos. Torretas: icono, `name`, tipo de ataque, `TurretData.ACCENT_COLOR` (cian `#40e0f0`, el mismo en todas) y `description`. Enemigos: primer frame de `up`, `name`, "ENEMIGO", `EnemyData.ACCENT_COLOR` (rojo de motor `#f0323c`), y `description`.

**`StatEntry`** (`scripts/level_ui/StatEntry.gd`, `RefCounted`): `icon: Texture2D`, `label: String` (nombre corto en mayúsculas: COSTE, DAÑO, VEL. BALA, BOTÍN…) y `value: String` ya formateado. `StatEntry.new(icon_name, label, value)` carga `assets/ui/stat_icons/<icon_name>.png`. Una fila de la ficha mide 110 px con 3 px de margen a cada lado, así que el contenido mide 104: icono de 8, hueco de 4, nombre, hueco de 4 y valor; quedan 88 px (14 caracteres de 6 px) entre nombre y valor. `MAX_LABEL_CHARS = 9` (54 px) es el nombre más largo y `MAX_VALUE_CHARS = 7` (42 px) el valor más largo, que cabe con un nombre de hasta 7 caracteres (con uno de 9 caben 5). Con las torretas y enemigos actuales la fila más larga es "CADENCIA 0.25s" (78 px). Las filas las dan `TurretData.get_stats()`, los `get_stats()` de cada tipo de ataque (ver [torretas.md](torretas.md)) y `EnemyData.get_stats()` (ver [enemigos.md](enemigos.md)).

**`StatRow`** (`scripts/level_ui/StatRow.gd`): `StatRow.create(entry, index, h_margin = 3, v_margin = 1, font_size = 16, icon_box = 8, icon_top = ICON_TOP, separation = SEPARATION)` devuelve la fila de un `StatEntry`: `PanelContainer` con fondo alterno según `index` (`#0b2132` / `#091d2c`), el icono de 8x8, el nombre en `#5a7a96` y el valor a la derecha en `#cce6ff` (se recorta si no cabe). Entre icono, nombre y valor hay `SEPARATION` (4 px). Los cuatro últimos parámetros escalan la fila (los usa `RunSummary`). El icono va 3 px por debajo del borde de arriba de la línea de texto (`ICON_TOP`) para quedar centrado con las mayúsculas. La fila y todo lo de dentro tienen `mouse_filter = IGNORE`: no recogen el ratón y la rueda llega directa al scroll de la ficha (y el clic, al `RunSummary` de debajo). La usan la ficha (márgenes por defecto: 3 px a los lados y 1 arriba y abajo) y `RunSummary`.

**`ScannerDisplay`** (`scripts/level_ui/ScannerDisplay.gd`, `Control` de 57x57): radar de reposo. Pinta 32 frames del barrido píxel a píxel en `Image` (sin antialiasing) la primera vez y los reparte entre instancias; avanza un frame cada 0,06 s (unos 1,9 s por vuelta) solo mientras es visible. Disco `#0e1626`, anillo `#1c7496` de radio 27 con marcas `#40e0f0` en los cuatro puntos cardinales, anillos interiores y cruz punteados en `#1c4a60`, línea de barrido `#befaff` y estela en dos tramos (`#1c7496` hasta 25°, `#14304a` hasta 70°). Cuatro ecos de 1 px se encienden en `#befaff` al pasar el barrido y se apagan pasando por `#40e0f0`.

**Interacción:**

- Clic derecho en un `TurretButton` (aunque no se pueda pagar y con el juego en pausa): enseña su ficha sin seleccionarla.
- Clic izquierdo: la selecciona (si se puede pagar) y enseña su ficha. Con una pantalla abierta (selección bloqueada) solo enseña la ficha, sin seleccionar ni soltar; la torreta ya seleccionada se conserva.
- Clic izquierdo o derecho en una `EnemyCell` de la pestaña Oleadas (también en pausa): enseña la ficha del enemigo sin tocar la selección de torreta.
- Deseleccionar (clic derecho en el mapa o quedarse sin dinero) no cambia la ficha.
- `TurretButton.inspect_requested` → `Sidebar.inspect_requested` (o `EnemyCell.inspect_requested` → `WaveBlock.inspect_requested` → `Sidebar.inspect_requested`) → `LevelUI` escribe `LevelState.inspected` → `LevelState.inspected_changed` → `InfoPanel.show_inspected`. Nadie más guarda qué está inspeccionado.

## TurretActions (mejorar y vender)

`scenes/level_ui/TurretActions.tscn` + `scripts/level_ui/TurretActions.gd` (clase `TurretActions`). `VBoxContainer` (3 px de separación, tema `menu_theme.tres`) dentro de `GameArea`, declarado antes de las pantallas de pausa, derrota y victoria para que ellas lo tapen. Oculto al empezar. Tiene dos botones de fuente 14 con estilos de `ClippedBoxStyle.create` (normal `#0e1626`/`#1c7496`, hover `#16243c`/`#40e0f0`, pressed `#14304a`/`#40e0f0`, disabled `#0a0f1a`/`#1c4a60` con texto al 30 %, como `NextWaveButton`; márgenes de 6 px a los lados y 2 arriba y abajo, 3 px entre icono y precio, sin ancho mínimo):

- `UpgradeButton`: icono de flecha verde (`assets/ui/upgrade.png`) y "-X€" con X = `fusion.cost`; solo se ve si la torreta tiene `fusion`. Apagado (`disabled`) mientras el dinero no llega a `fusion.cost` (icono y texto atenuados); `set_money` (conectado a `LevelState.money_changed`) lo enciende al llegar. Emite `upgrade_requested`; `LevelUI._on_upgrade_requested` lo reenvía a `LevelState.upgrade_requested` solo en `PLAYING`.
- `SellButton`: icono de papelera con la tapa cerrada (`sell_closed.png`) y "+X€" con X = `Turret.get_sell_value()` (también tras fusionar). El primer clic cambia el icono a la papelera con la tapa abierta (`sell_open.png`) y el segundo emite `sell_requested`; al cambiar de torreta o soltarla, `show_for` la vuelve a cerrar. `LevelUI._on_sell_requested` llama a `LevelState.sell_selected_turret()` solo en `PLAYING`. Ver [torretas.md](torretas.md).

`show_for(turret, money)` lo abre con la torreta colocada seleccionada (`LevelUI` lo llama con `LevelState.sellable_turret_changed` y en `setup`) y con null lo cierra (soltar la torreta, venderla o reiniciar). Tras mejorar, `BuildManager` inspecciona la torreta nueva y el recuadro se abre sobre ella. `_reposition` pasa la posición de la torreta del mapa a la de `GameArea` (`get_global_transform_with_canvas`, porque `LevelUI` es un `CanvasLayer`): centrado en x, con el borde de abajo a `TURRET_GAP` (22 px, para librar los cañones) del centro de la torreta y sin salirse del área; si arriba no cabe (torreta en el borde de arriba) sale debajo. Se recoloca al cambiar el texto (el ancho cambia). Los clics en sus botones no llegan al mapa; un clic en el espacio vacío suelta la torreta y lo cierra.

## Poderes

Tres `PowerButton` (`scripts/level_ui/PowerButton.gd`) en `InfoPanel/Content/PowersRow`, de unos 35x24 cada uno (se reparten los 110 px útiles), sin foco ni tooltip: `MeteorButton` (icono `assets/ui/power_meteor.png`, tecla Q) y `FreezeButton` (`power_freeze.png`, tecla E) y `OrbitalButton` (`power_orbital.png`, tecla R). La lógica está en `Powers` (ver [niveles.md](niveles.md)). La letra se pinta a 4 px del borde izquierdo y el icono (16 px) va alineado a la derecha con el mismo hueco, dejando unos 5 px de aire entre los dos.

- Icono de 16x16 centrado y la letra de la tecla (`key_label`) a 5 px del borde izquierdo en `#5a7a96`.
- Estilos con `ClippedBoxStyle.create`: normal fondo `#0e1626` y borde `#1c7496`; hover borde `#40e0f0`; mientras se apunta el meteorito, el normal pasa al ámbar de AUTO (fondo `#453d2b`, borde `#ecb23c`).
- En recarga el botón está `disabled` (fondo `#0a0f1a`, borde `#1c4a60`, icono al 50 %) y lleva encima un oscurecido negro al 45 % recortado a la forma del botón, anclado arriba y con alto proporcional a lo que falta, y los segundos que faltan (redondeados hacia arriba) centrados en `#cce6ff`.
- Cada botón lee `Powers` en `_process` (`get_cooldown_left`, `is_aiming`) y solo se redibuja si algo cambia. `LevelUI.setup_powers(powers)`, que `Game` llama antes de `setup` con el `Powers` del nivel, se lo pasa a los dos.
- Al pulsarlos (o con Q y E) `LevelUI._use_power(power)` llama a `Powers.use` solo en `PLAYING`. En el nivel de emergencia no se ven ni la fila de poderes ni su cabecera "PODERES" (`InfoPanel.powers_header`) y `_use_power` no hace nada (`_set_powers_enabled`). Cualquier `set_state` que no sea `PLAYING` cancela el apuntado.

## Tutorial del nivel de emergencia

`scenes/level_ui/TutorialHints.tscn` + `scripts/level_ui/TutorialHints.gd` (clase `TutorialHints`): un `Control` a pantalla completa que ignora el ratón, con un recuadro (`Box`, un `OverlayFrame` cian sin decoración) donde habla NOVA, el astronauta de la sala de control de la estación atacada, que da instrucciones en el contexto del ataque (tutea al comandante). Solo sale en el nivel de emergencia (ver [niveles.md](niveles.md) › "Nivel de emergencia"): `LevelUI.setup` llama siempre a `stop()` y `Game` llama después a `LevelUI.start_emergency(level)`, que pone el rótulo "SECTOR 0" en `LevelIndicator` (`set_title`), esconde la fila de poderes (y `_use_power` no hace nada: el nivel de emergencia no enseña poderes) y llama a `start(level)`. Al reiniciar vuelve a empezar desde el primer paso (las señales del nivel anterior se liberan con él).

- **Recuadro:** tamaño fijo de 528x93 px, centrado abajo del área de juego a 12 px del borde, con 12 px de margen a la izquierda, 10 a la derecha y 8 arriba y abajo; no cambia con el texto (`max_lines_visible` = 2). A la izquierda, el retrato `assets/ui/guide_portrait.png` (32x32 a ×2) en un marco propio (`PortraitFrame`: fondo `#0e1626`, borde de 1 px `#1c7496` y 2 px de aire) centrado en vertical y separado 12 px del texto; a la derecha, el nombre "NOVA" a 32 px en ámbar `#ecb23c` y justo debajo (separación de 0 px: la línea del nombre ya deja aire bajo las letras), el mensaje a 24 px en `#cce6ff` (418 px de ancho, interlineado -1 para que las líneas vayan juntas), que aparece letra a letra (0,02 s por carácter, como si hablara).
- **Páginas:** cada mensaje se reparte en páginas de 2 líneas (`LINES_PER_PAGE`, `_paginate`), frase a frase: una frase entra en la página si cabe entera; si no, empieza página nueva, así que la página corta en el punto aunque haya más texto detrás. Solo una frase más larga que una página se parte por líneas, y esa página acaba en " -" (`PAGE_CONTINUES`; se parte con el ancho menos lo que ocupa, para que siempre quepa). Las líneas se parten solo por los espacios (`_wrap`), así que nunca se corta una palabra, tampoco por un guion suyo. Un `|` (`PAGE_BREAK`) en el texto del CSV fuerza un corte. Al acabar una página que no es la última sale la flecha y un clic sigue con la siguiente.
- **Señalado en la última página, acciones al acabar:** mientras al mensaje le quedan páginas por pasar todo está oscuro, sin nada señalado; lo señalado aparece nada más empezar la última página (en `HIGHLIGHT_NOW_STEPS`, `ENEMY_INFO`, desde la primera: la ficha es lo que el jugador acaba de abrir). Huecos y sprites señalados se calculan en `_process` y se pintan en `_draw`. Lo que pide hacer, en cambio, no responde hasta que NOVA acaba (`_waiting_for_talk()`: escribe o le quedan páginas): mientras, `allows()` no deja nada. En `NO_WAIT_STEPS` (`UPGRADE_PRESS`) no espera: al elegir la torreta, Mejorar responde al momento, mientras NOVA dice que lo pulse.
- **Pasar mensajes:** no hay botón: al acabar de escribirse una página que se puede pasar (no es la última, o es un paso informativo de `INFO_STEPS`) sale abajo a la derecha del recuadro una flecha ámbar hacia abajo (`ContinueArrow`, triángulo de 7 px dibujado con su señal `draw`) que sube y baja 2 px cada 0,8 s. Un clic en cualquier sitio (o Intro/Espacio, `ui_accept`) la pasa: si el texto aún se escribe, lo completa; si no, pasa de página o, en la última de un informativo, de paso. `_input` se come ese clic, para que no construya ni pulse nada debajo. Cuando NOVA acaba de hablar en un paso que pide hacer algo, el clic ya no se come: va al juego.
- **Saltar:** no hay botón propio. En el nivel de emergencia la opción "Salir" de la pausa pasa a ser "Saltar" (`LevelUI.start_emergency` llama a `pause_menu.set_option_text(QUIT, "TUTORIAL_SKIP")` y `setup` la devuelve a "BTN_QUIT"): sale del nivel de emergencia y `Game._quit_to_menu` lo da por hecho.
- **Foco:** en los pasos con foco (`FOCUS_STEPS`) todo se oscurece (negro al 60 %, `DIM_ALPHA`, con un fundido de 0,2 s) menos lo señalado y el recuadro de NOVA, que es hijo y se pinta encima. Lo señalado puede ser:
  - **De la interfaz** (`_focus_holes()`): un hueco en el oscurecido (se pinta por franjas horizontales que saltan los huecos) con un borde ámbar `#ecb23c` de 1 px a 2 px que parpadea (0,4 s encendido, 0,4 s apagado). La ficha de la izquierda entera no lleva borde: solo queda sin oscurecer.
  - **Del mapa** (`_focus_spotlights()`): la estación, los asteroides con plataforma de las casillas libres y las torretas (con su asteroide). No se abre un hueco: se vuelven a dibujar encima del oscurecido con su forma exacta (el frame actual de su `AnimatedSprite2D`, o la pieza de `TurretSlots` del tileset) y parpadea a su alrededor un contorno ámbar de 1 px que sigue sus píxeles (de la torreta y su asteroide juntos, la silueta de los dos). El contorno se calcula una vez por textura y región (`_outline_texture`, una imagen blanca 2 px mayor con un píxel en cada transparente que toca uno opaco, teñida al dibujar); cada frame de una animación es su propia textura, así que el contorno sigue la animación (el anillo que gira de la estación). Un sprite que en el mapa lleva material (el holograma de construir de una torreta recién puesta) se dibuja en una capa hija (`Node2D`) con ese mismo material, una por material (`_sync_material_layers`), para que la animación de construir se vea igual sobre el oscurecido. En `UPGRADE_PRESS` la torreta seleccionada se ve con su contorno fijo de selección, sin parpadear: lo que parpadea es Mejorar.
- **Tiempo real:** el texto, el fundido, el parpadeo y la flecha no siguen la velocidad ×2 (tweens con `set_ignore_time_scale()` y `_process` con el `delta` deshecho).
- **Entre peticiones se juega libre:** en los pasos sin foco no hay oscurecido ni bloqueo, y en `FIRST_WAVE` y `FREE` no se ve el recuadro.
- Pasos (`Step`):
  1. `STATION`: NOVA se presenta y cuenta que les atacan; todo oscuro, sin nada señalado. Informativo.
  2. `STATION_BASE`: la estación del mapa ("si sus naves alcanzan la estación..."). Informativo.
  3. `STATION_HEALTH`: su vida en la barra (`Sidebar.station_header`). Informativo.
  4. `PREPARE`: "hay que preparar las defensas"; sin nada señalado. Informativo.
  5. `PLACE_TURRETS`: los créditos (`Sidebar.credits_header`), el botón del Cañón doble (o la pestaña Torretas si no está abierta), las casillas de torreta libres y las torretas ya colocadas (siguen a la vista, sin borde, hasta que están las 3). Acaba cuando no queda ninguna libre (`LevelState.turret_placed`; el dinero da justo para las 3).
  6. `OPEN_WAVES`: la pestaña Oleadas (se mira en `_process`, porque cambiar de pestaña no emite nada).
  7. `INSPECT_ENEMY`: el bloque de la oleada que se ve (`Sidebar.get_viewed_wave_block()`); acaba al inspeccionar una nave (`LevelState.inspected_changed` con un `EnemyData`).
  8. `ENEMY_INFO`: la ficha de la izquierda (`InfoPanel`). Informativo.
  9. `START_WAVE`: el botón INICIAR (`Spawner.wave_started`).
  10. `FIRST_WAVE`: sin recuadro, se juega la oleada 1.
  11. `UPGRADE_PICK` (al acabar la oleada 1, `Spawner.wave_cleared`): tus torretas del mapa; acaba al seleccionar una (`LevelState.sellable_turret_changed`). Si no llega el dinero para la mejora, NOVA pone lo que falta (`add_money`) y lo dice con otro texto (`TUTORIAL_UPGRADE_GIFT`). Apaga AUTO, para que la oleada 2 no llegue en plena explicación.
  12. `UPGRADE_PRESS`: la torreta y el botón Mejorar de `TurretActions`; soltar la torreta vuelve al paso anterior. Acaba con `LevelState.upgrade_requested` (`BuildManager` ya ha mejorado, porque se conectó antes) si hay una torreta mejorada. Vender no se explica: el botón se ve al mejorar.
  13. `DONE`: despedida sin foco; se pasa con un clic o sola a los 5 s (`AUTO_CLOSE_TIME`) y pasa a `FREE` (oleadas 2 y 3 libres). Si al acabar la oleada 1 ya había alguna torreta mejorada, se salta aquí desde `FIRST_WAVE`.
- Al ganar sale la pantalla de victoria normal (ver niveles.md › "Nivel de emergencia").
- **Bloqueo de acciones:** `TutorialHints.allows(action)` (enum `Action`, tabla `ALLOWED_ACTIONS` por paso) dice si el paso actual deja hacer algo; sin tutorial en marcha o en un paso sin foco todo está permitido. Cada sitio donde entra una acción pregunta antes y, si no se permite, no hace nada (los botones y pestañas vuelven a su estado sin emitir): `LevelUI` (elegir torreta de la tienda, poderes: ratón y teclado), `BuildManager` (construir, clic derecho y clic en el vacío para soltar, seleccionar torreta del mapa), `Sidebar` (pestañas, Siguiente oleada, AUTO, velocidad, flechas de oleada) y `TurretActions` (Mejorar y Vender). Referencia `tutorial_hints` puesta por `LevelUI` (`Sidebar`, `TurretActions`) y `Game` (`BuildManager`). Por paso: colocar, elegir, construir, soltar y la pestaña Torretas; pestaña Oleadas; INICIAR (mientras el tutorial guía con foco, `TutorialHints.is_running()`, el botón del pie solo responde con la pestaña Oleadas abierta; fuera de eso, y el atajo `next_wave` siempre, vale desde cualquier pestaña); mejorar: seleccionar y soltar torreta del mapa (y Mejorar en el segundo); los informativos con foco, nada. Inspeccionar naves de la pestaña Oleadas nunca se bloquea. La pausa (Escape) tampoco.
- `LevelUI.set_state` lo esconde fuera de `PLAYING`: la pausa oscurece ya toda la pantalla igual (ver "PauseMenu"). `TutorialHints` tiene `z_index` 1 y las pantallas de pausa, derrota y victoria 2, para que queden siempre por encima.

## BossAlert

`scripts/level_ui/BossAlert.gd` (clase `BossAlert`), `Control` a pantalla completa dentro de `GameArea` (declarado antes que las pantallas, ignora el ratón, oculto hasta que se usa). `LevelUI._on_wave_started` llama a `show_alert("Nodriza")` cuando `Spawner.wave_has_boss(index)` es true (la oleada tiene algún grupo con la Nodriza). Dura 2 s en tiempo real, sin pausar el juego ni tapar las barras. Todo se pinta en `_draw`, sin antialiasing:

- Tinte rojo `#f0323c` sobre el área (hasta 35 % de opacidad) que late 4 veces, y borde rojo de 12 px que late con él.
- Franja de lado a lado del área, centrada en vertical, de 120 px (`#7a0f18`), con rayas diagonales rojas y negras de 14 px arriba y abajo.
- En el centro, "ALERTA" a 48 px y debajo "NODRIZA ACERCÁNDOSE" a 32 px (Monogram), en un `CenterContainer`.
- Sin sonido (se quitó la sirena a petición del usuario).

El `Portal` de un camino que saca la Nodriza tiembla con más fuerza (`Portal.BOSS_SHAKE`, 3 px frente a 1).

## WaveAnnouncer

`scripts/level_ui/WaveAnnouncer.gd` (clase `WaveAnnouncer`), `Control` a pantalla completa dentro de `GameArea` junto a `BossAlert`, ignora el ratón. `LevelUI._on_wave_started` llama a `show_wave(número, total)` al lanzar cada oleada, salvo las que llevan Nodriza (esas enseñan solo `BossAlert`). Centro del área: "OLEADA N" a 48 px en `#40e0f0` y debajo "N / TOTAL" a 16 px en `#cce6ff`; en la última, "ÚLTIMA OLEADA". Entra en 0,25 s, se queda 1,5 s y se desvanece en 0,4 s, en tiempo real, sin pausar ni tapar las barras.

## LevelIndicator

`scenes/level_ui/LevelIndicator.tscn` + `scripts/level_ui/LevelIndicator.gd` (clase `LevelIndicator`). `MarginContainer` (sin marco ni fondo) anclado arriba en el centro de `GameArea` (3 px de margen superior) con el `Label` "SECTOR N" a 32 px (el doble del texto normal), en `#cce6ff` sin contorno, y debajo "OLEADA X/Y" a 16 px (`set_wave`, que llama `LevelUI._refresh_wave_controls` con el mismo número que el pie de la barra: antes de empezar, 1/Y). `mouse_filter = IGNORE` en el contenedor y en el `Label`; el área de desvanecido se ajusta sola a su tamaño.

- Número: `Game` lo calcula como la posición de `level_data` en `GameData.levels` más 1 y lo pasa por `LevelUI.setup`. Si el nivel no está en la lista (0), el indicador se oculta. El nivel de emergencia pone en su lugar "SECTOR 0" con `set_title(text)` (`HUD_EMERGENCY`).
- Se ve con opacidad 0,7. Si el cursor o algún nodo del grupo `enemies` está dentro de su rectángulo (con 4 px de margen), baja a 0,15 con un tween de 0,15 s; al salir, vuelve a 0,7. Se comprueba en `_process`, que sigue activo con el juego en pausa.

## Sidebar

`scenes/level_ui/Sidebar.tscn` + `scripts/level_ui/Sidebar.gd` (clase `Sidebar`). Estilo de tablet compartido con `InfoPanel`: quedan 110 px de ancho útil. Lo que se estira con los contenedores (pestañas, cabecera de créditos, cabeceras `//`, título de oleada) ocupa todo ese ancho; lo de ancho fijo (controles de oleada, rejilla de torretas y rejilla de enemigos) va centrado en horizontal.

- **Pestañas:** `TabBar` con dos botones de icono de 16x16 (`TurretsTab` y `WavesTab`, 24 px de alto, en un `ButtonGroup`, 4 px de separación) que se reparten todo el ancho a partes iguales (53 px cada uno), y una página por pestaña (`TurretsPage`, `WavesPage`) de las que solo una es visible. No hay texto ni tooltip. Torretas está activa al empezar. Los iconos son `assets/ui/tab_turrets.png` y `tab_waves.png`. Los estilos de pestaña se crean en `_ready` con `ClippedBoxStyle.create` (forma recortada, ver "Botones"): la inactiva tiene borde `#1c4a60` e icono atenuado; la activa, fondo `#14304a`, borde `#40e0f0` e icono a plena luz. Ver "Pestaña Oleadas" para `WavesPage`.
- **`StationHeader`** (hijo directo de `Content`, justo debajo de `TabBar` y encima de `CreditsHeader`: se ve con cualquier pestaña): la vida de la estación, con el mismo recuadro que `CreditsHeader` pero en cian. Ver "Vida de la estación". Los dos recuadros se estiran al mismo ancho y van a 4 px uno del otro, como un solo bloque.
- **`CreditsHeader`** (hijo directo de `Content`, justo debajo de `StationHeader`: se ve con cualquier pestaña): `PanelContainer` con un `StyleBoxFlat` propio de la escena (fondo `#221e19`, borde de 1 px `#96641e`, margen de 4 px a los lados y 2 arriba y abajo). Dentro, `CreditsRow` con 4 px de separación: a la izquierda la moneda (`stat_icons/credits.png`, versión de 7x7 de la moneda de `cost.png`, redonda y con la altura del corazón de `StationHeader`, bajada 3 px como él) y "CRÉDITOS" en `#ecb23c`; a la derecha `MoneyLabel` con la cantidad en `#ffe082`, formato `UiFormat.money`.
- **`TurretsPage`**, de arriba abajo: `TurretsHeader` (`ScreenHeader` con `// TORRETAS`) y `TurretScroll` (`ScrollContainer`, scroll vertical sin barra visible, horizontal desactivado) con `TurretMargin` (`MarginContainer` con 1 px arriba y abajo, para que los corchetes de la torreta seleccionada no se recorten) y dentro `TurretButtons`, un `GridContainer` de 2 columnas con 4 px de separación (2 x 52 + 4 = 108 px de ancho), centrado. Los créditos y la cabecera no entran en el scroll, así que no se mueven.
- `build_buttons(unlocked)`: borra los botones anteriores y crea siempre un `TurretButton` por cada torreta de `GameData.turret_order` (las 10, en ese orden). Las que no están en `unlocked` (las `LevelData.turrets` del nivel) salen bloqueadas.
- `set_money(amount)`: actualiza la etiqueta y avisa a cada botón.
- Señal `turret_selected(data)`: petición de cambio, con la torreta al pulsar un botón y con `null` al soltarla. No guarda la selección.
- Señal `inspect_requested(data)`: reenvía la de cada `TurretButton`; petición de enseñar algo en la ficha.
- `set_selection_locked(locked)`: guarda el bloqueo, atenúa `TurretButtons` al 50 % (la cabecera de créditos no cambia) y se lo pasa a cada `TurretButton` (también a los que cree `build_buttons`). Solo lo llama `LevelUI.set_state`.
- `show_selected(data)`: marca el botón de esa torreta y desmarca los demás (todos con `null`). No emite nada.

## TurretButton

`scenes/level_ui/TurretButton.tscn` + `scripts/level_ui/TurretButton.gd` (clase `TurretButton`). `Button` de 52x56 sin `toggle_mode` ni `ButtonGroup`, sin foco: el estado seleccionado es solo visual y lo dicta `Sidebar.show_selected` mediante `set_selected`.

- Contenido: la torreta en reposo en un hueco de 32x32 (`IconRect`, un `Control` con dos `AnimatedSprite2D`: `BaseSprite` con `data.sprite_frames` y `CannonSprite` con `data.cannon`, centrados, escala 1, mirando hacia arriba) centrada arriba, con 3 px de hueco hasta el borde de arriba y 9 a cada lado, y debajo (2 px más abajo) el coste centrado, a 16 px. Cada sprite reproduce en bucle su `default` (o `spin` en la Minigun, a velocidad 1); sin cañón o sin esas animaciones se queda en el primer frame. La ficha sigue usando `data.icon`. El coste va con `UiFormat.money` (siempre con `€`); con 52 px caben sus 7 caracteres, así que no se limita. Sin tooltip: el nombre se ve en la ficha.
- Estados (cajas recortadas de `ClippedBoxStyle.create`, borde de 1 px, creadas en `_refresh`):
  - Normal: fondo `#0e1626`, borde `#1c7496`.
  - Hover: fondo `#16243c`, borde `#40e0f0`.
  - Seleccionada: borde ámbar `#ecb23c` y fondo mezclado con el ámbar (25 %); con el ratón encima, 40 % y borde `#ffe082`. Además, corchetes en L de 4 px en `#ecb23c` justo por fuera de las cuatro esquinas, pintados en `_draw`.
  - Sin dinero: icono al 35 % de opacidad y coste en rojo `#ff3c5a` (con dinero, ámbar `#ecb23c`); sin resalte al pasar el ratón. El botón no está `disabled`, así que recibe todos los eventos de ratón (para el clic derecho de la ficha), pero el clic izquierdo no hace nada.
- **Bloqueado** (`setup(data, money, locked)`): la torreta aún no se ha desbloqueado en el nivel. Sin icono (`icon_rect` transparente, conserva su hueco), plano oculto de la torreta: caja apagada (fondo `#0a1220`, borde `#1c4a60`, sin resalte) con una rejilla de puntos cada 4 px (`#16283c`; los dos puntos más cercanos al centro, a 2 px de él por cada lado), la silueta de una torreta centrada en el botón (un octógono de 30x30 con 9 px recortados en cada esquina, la forma de la base de las torretas, igual en todas las bloqueadas: las siluetas reales de cada torreta salían con trozos de cañón asomando), rayada por filas (`#122a40`/`#0e2034`) y con contorno punteado en `#2a6a88` (las cuatro diagonales enteras y los tramos rectos un píxel sí y otro no, con dos puntos seguidos en el centro de cada lado), y en su centro un candado de 10x12 (`LOCK_PIXELS`; silueta y candado tienen medidas pares, como el botón, para quedar centrados al píxel, colores en `LOCK_COLORS`: contorno cian `#40e0f0`, cuerpo, brillo, sombra y ojo de cerradura) con un halo de 1 px del color de fondo. Todo va en una imagen transparente que se genera en código y se pinta en `_draw` sobre la caja (`_build_locked_image`, cacheada por tamaño de botón en `_locked_textures`). Rejilla y punteado se cuentan desde el borde más cercano del botón, así que el plano es simétrico en los dos ejes: con un contorno descompensado el candado parecía descentrado aunque no lo estaba. Sin texto, y sin coste (etiqueta vacía). No cambia con el dinero y no hace nada: ni selecciona, ni enseña ficha (ni con clic izquierdo ni derecho). Las teclas 1-7 siguen el orden de la rejilla, así que sobre una bloqueada tampoco hacen nada.
- Señal `selection_changed(data, on)`: petición, no estado. Con `set_selection_locked(true)` no se emite (ni por clic ni por quedarse sin dinero; al desbloquear, si la torreta seleccionada ya no se puede pagar, pide soltarla). El clic izquierdo pide seleccionar (`on = true`) o, si ya estaba seleccionada, soltar. Si estando seleccionada deja de llegarle el dinero, pide soltarla.
- Señal `inspect_requested(data)`: petición de enseñar la torreta en la ficha. La emiten el clic izquierdo (antes de comprobar el dinero) y el clic derecho, que se recoge en `_gui_input` y se marca como gestionado.

## Pestaña Oleadas

`WavesPage` (dentro de `Sidebar`), de arriba abajo: `WavesHeader` (`ScreenHeader` con `// OLEADAS`), `WaveNav` y `WaveScroll` (`ScrollContainer` vertical sin barra, horizontal desactivado) con `WaveBlocks` dentro. Enseña **una sola oleada** a la vez; si tiene tantos tipos que no caben (hasta 11, es decir 6 filas), la rejilla hace scroll. Los controles no están en la página, sino en `Content`. El pie con el estado no está en la página, sino en `Content` (ver "Pie de la barra").

- **`WaveNav`** (fila de 110 px): `PrevWaveArrow` (`<`, 16x18), `WaveTitlePanel` con `WaveTitleLabel` ("OLEADA N", ocupa el resto) y `NextWaveArrow` (`>`). Las flechas no tienen foco, funcionan con el juego parado en la derrota y la victoria (en la pausa, no: la pausa deshabilita las barras) y se desactivan en la primera y la última oleada (borde `#1c4a60`, texto al 30 %). Son `<` y `>` en vez de ◀ ▶ porque son glifos seguros en Monogram.
- **`WaveBlocks`** (dentro de `WaveScroll`): contenedor con un `WaveBlock` por oleada, de los que solo es visible el que se mira (`Sidebar.view_wave`).
- **`Sidebar.view_wave(index)`**: enseña esa oleada, colorea el título según su estado respecto a la oleada en curso y actualiza las flechas. `Sidebar.set_current_wave(index)` guarda la oleada en curso (-1 si ninguna) y pasa a ver `max(index, 0)`.
- **Cuándo vuelve sola la vista** (`LevelUI`): al empezar un nivel (la 1), al empezar una oleada (`set_current_wave`: la que acaba de empezar) y al limpiar una (`view_wave(index + 1)` si quedan más: la que se va a lanzar). Si el jugador miraba otra con las flechas, la vista se la lleva.
- **Controles** (`WaveControls`, `VBoxContainer` hijo directo de `Content`, debajo de las páginas y encima del pie, visible con cualquier pestaña, con 4 px de separación y texto a 16): los tres botones uno encima del otro, `NextWaveButton`, `AutoWaveButton` y `SpeedButton`, de 108x24 cada uno (el ancho de la rejilla y el alto de las pestañas), centrados en los 110 útiles. Ninguno tiene tooltip. Los estilos se crean en `Sidebar._style_wave_controls()` con `ClippedBoxStyle.create` (forma recortada y bordes de 1 px; también los de las flechas):
  - `NextWaveButton` ("INICIAR"). Activo: fondo `#0e1626`, borde `#1c7496`; hover con borde `#40e0f0`. Cuando no se puede lanzar (quedan enemigos de la oleada actual por salir o vivos, o no quedan oleadas) está `disabled`: fondo `#0a0f1a`, borde `#1c4a60` y texto al 30 %. Antes de la primera oleada, si se puede pulsar, su borde parpadea entre `#1c7496` y `#befaff` (0,5 s cada medio ciclo) para invitar a empezar. Emite `Sidebar.next_wave_requested`.
  - `AutoWaveButton` ("AUTO", `toggle_mode`). Apagado: borde `#1c4a60` y texto al 30 %; encendido: fondo `#453d2b` (fondo mezclado al 25 % con ámbar), borde `#ecb23c` y texto a plena luz. Emite `Sidebar.auto_waves_toggled(enabled)`, que es una petición: el estado lo guarda `Spawner.auto_waves` y la barra lo refleja con `show_auto_waves(enabled)` (sin volver a emitir).
  - `SpeedButton` ("×1" / "×2", `toggle_mode`). Mismo estilo que AUTO (ámbar al estar activo, es decir, a ×2). Emite `Sidebar.fast_speed_toggled(enabled)`, una petición: el estado lo guarda `LevelUI._fast_speed` y la barra lo refleja con `show_fast_speed(enabled)` (sin volver a emitir, y cambia el texto).
  - `Sidebar.set_next_wave_available(available, inviting)` activa o atenúa el botón y arranca o para el parpadeo.
- `Sidebar.build_waves(waves)`: borra los bloques anteriores y crea uno por `WaveData`.
- **`WaveBlock`** (`scenes/level_ui/WaveBlock.tscn` + `scripts/level_ui/WaveBlock.gd`): solo la rejilla `Cells` de 2 columnas (52 px, 4 px de separación: 108 px, alineada con la de torretas) de `EnemyCell`, centrada en horizontal. Agrupa las entradas por `EnemyData`, con el total de cada tipo, ordenadas de menos a más vida máxima (`hp`; a igualdad, por nombre), siempre igual aunque cambie el orden en que salen (el ticket `id-naves` lo cambiará por un id propio). No hay datos de enemigos en la UI. El título vive en `WaveNav`; `WaveBlock.apply_title_style(panel, label, state)` (estático) lo pinta.
- **Estados:** `WaveBlock.State`, respecto a la oleada en curso (la última lanzada). En curso: título con fondo `#14304a`, borde y texto `#40e0f0`. Pasada: todo atenuado al 40 % de opacidad (bloque y título). Próxima (la siguiente a la en curso; antes de empezar, la primera): fondo `#0e1626`, borde `#96641e` y texto `#ecb23c`. Futura: fondo `#0e1626`, borde `#1c4a60` y texto `#7fa6b8`.
- **`EnemyCell`** (`scenes/level_ui/EnemyCell.tscn` + `scripts/level_ui/EnemyCell.gd`): `Button` de 52x44 (el ancho de `TurretButton`; en la barra `WaveBlock` lo sube a 56 de alto con `CELL_HEIGHT`, como `TurretButton`; en el Navedex se queda en 44) con la forma recortada (`ClippedBoxStyle.create`) y los colores de `TurretButton`. Sprite = primer frame de `up` a escala 1, centrado en horizontal en un área de todo el ancho y 34 de alto, y debajo `"×N"` a 16 px (el conjunto, centrado en vertical dentro de la celda) (abreviado con `UiFormat`). Sin tooltip: el nombre se ve en la ficha. Emite `inspect_requested(data)` con el clic izquierdo y con el derecho (este se recoge en `_gui_input`); `WaveBlock` y `Sidebar` lo reenvían.
- `LevelUI.setup(..., spawner)` llama a `_connect_spawner`: desconecta el `Spawner` anterior si lo había, construye los bloques con `spawner.waves`, refleja la oleada (`get_wave_index()`) y AUTO, y conecta `wave_started`, `wave_cleared` y `auto_waves_changed`. `next_wave_requested` llama a `spawner.start_next_wave()` y `auto_waves_toggled` escribe `spawner.auto_waves`.

### Pie de la barra

`WaveFooter` (`MarginContainer` con 4 px a cada lado al final de `Content`, fuera de las páginas, así que se ve en Torretas y en Oleadas) con la fila `FooterRow` y texto a 16: a la izquierda `FooterWaveLabel` "OL. X/Y" y a la derecha `FooterStatusLabel`. X es la oleada en curso o, si no hay ninguna, la siguiente que se va a lanzar (antes de empezar, "OL. 1/Y"; nunca 0).

| `Sidebar.WaveStatus` | Texto | Color | Cuándo |
|---|---|---|---|
| `IN_PROGRESS` | EN CURSO | `#40e0f0` | Hay una oleada lanzada con enemigos por salir o vivos |
| `READY` | LISTA | `#ecb23c` | No hay oleada en curso y se puede lanzar la siguiente (también antes de la primera) |
| `COMPLETE` | COMPLETA | `#7fa6b8` | No quedan oleadas por lanzar y la última está limpia |

**Quién decide:** `LevelUI._refresh_wave_controls()` calcula el estado y el número a partir del `Spawner` (`is_clear()`, `has_waves_left()`, `get_wave_index()`) y llama a `Sidebar.set_wave_status(status, wave_number, total)`; la barra solo lo enseña. Se llama al conectar el `Spawner`, en `wave_started` y en `wave_cleared`.

## Vida de la estación

`StationHeader` (`PanelContainer` hijo directo de `Content`, justo encima de `CreditsHeader`, así que se ve en Torretas y en Oleadas) con un `StyleBoxFlat` propio de la escena (fondo `#111e22`, borde de 1 px `#1c7496`, margen de 4 px a los lados, 2 arriba y 4 abajo para que la barra no pegue con el borde; los de `CreditsHeader` salvo el de abajo). Dentro, `StationBox` (`VBoxContainer`, 2 px de separación): `StationRow` con, a la izquierda, el icono `stat_icons/station.png` (corazón cian, bajado 3 px como la moneda) y "ESTACIÓN" a 16 en `#40e0f0`, y a la derecha `StationValueLabel` con la vida actual a 16 en `#befaff` (solo el número: `actual/máximo` mide 42 px y no cabe en los 36 que quedan; el máximo lo da la barra); debajo, `StationBar` (`ProgressBar` de 8 px de alto, sin porcentaje) a todo el ancho. Fondo de la barra `#0e1626` con borde `#1c4a60`; relleno `#40e0f0`. Con menos del 30 % de vida (`Sidebar.STATION_DANGER_FRACTION`) relleno y número pasan al rojo de peligro `#ff3c5a`.

- `Sidebar.set_station_health(current, maximum)`: lo único que toca la barra. Si la vida baja respecto a la anterior (la primera llamada no cuenta), relleno y número parten del rojo de peligro y vuelven a su color en `STATION_HIT_TIME` (0,3 s).
- Alarma de vida baja: `LowHealthVignette` (`ColorRect` con shader, en `GameArea`, bajo las pantallas) es una viñeta roja en los bordes que late (`VIGNETTE_MIN/MAX_INTENSITY`, `VIGNETTE_PULSE_TIME`) con menos del 25 % de vida (`LevelUI.LOW_HEALTH_FRACTION`). Se apaga si la vida sube y al perder o ganar.
- `LevelUI.setup(..., base)` conecta `Base.health_changed` a `set_station_health` y la pone con la vida inicial. `Game` pasa `level.base`; como la base es nueva en cada nivel o reinicio, no hay conexión anterior que quitar.

## UiFormat

`scripts/level_ui/UiFormat.gd` (clase `UiFormat`). `UiFormat.abbreviate(amount: int) -> String`: hasta 999 tal cual; desde 1000 en K (desde un millón M, desde mil millones B) con un decimal sin ".0": `1K`, `1.1K`, `5K`, `12.3K`, `999.9K`, `1M`, `1.2M`, `1B`. Como mucho 6 caracteres. Trunca en vez de redondear (1099 es `1K`, 999999 es `999.9K`).

- `UiFormat.money(amount: int)`: `abbreviate` más `€` (`999€`, `1K€`, `1.1K€`). Todo el dinero de la UI (cabecera, costes, recompensa, dinero gastado) pasa por aquí; nadie añade el `€` a mano. También lo usa el `+X€` flotante (`FloatingText`) de matar y vender.

- `UiFormat.number(value: float)`: para stats. Por debajo de 100 y con decimales, uno como mucho (`2.5`); si no, `abbreviate` del valor redondeado.
- `UiFormat.seconds(value: float)`: segundos con 2 decimales como mucho, sin ceros sobrantes y en 5 caracteres como máximo (`0.25s`, `1.5s`, `5s`, `123s`).

## Botones

Todos los botones del juego son una **caja con esquinas recortadas**: la esquina de arriba a la izquierda y la de abajo a la derecha cortadas en diagonal, fondo y borde de 1 px. Sin corchetes ni `>` en ningún estado.

**`ClippedBoxStyle`** (`scripts/level_ui/ClippedBoxStyle.gd`, `StyleBox` propio con `@tool`): dibuja esa caja en `_draw` con rectángulos de píxeles enteros, sin antialiasing; cada diagonal es una escalera de 1 px por fila. Propiedades: `bg_color`, `border_color` y `clip` (píxeles recortados, 3 en los botones, `BUTTON_CLIP`); al cambiarlas emite `changed`, así que se pueden animar con un tween (el parpadeo de INICIAR). Márgenes de contenido por defecto: 4 px a los lados y 1 arriba y abajo.

- `ClippedBoxStyle.create(bg, border, clip = 3)`: caja nueva. Es el sitio común donde se crean los estilos de los botones de las barras.
- `recolored(bg, border)`: copia con la misma forma y márgenes y otros colores (la usa `OverlayOptionButton`).
- `row_span`, `draw_outline` y `fill_inside` (estáticas): las piezas de dibujo, que también usa el panel holograma de `OverlayFrame`.

**Tema** (`assets/ui/menu_theme.tres`): los estilos de `Button` son `ClippedBoxStyle` con recorte de 3 px. Los usan el menú principal, la selección de nivel, `OptionsMenu` (también sus interruptores ON/OFF de 30x16) y, recoloreados, las opciones de las pantallas superpuestas.

| Estado | Fondo | Borde | Texto |
|---|---|---|---|
| `normal` | `#081626` | `#1c7496` | `#cce6ff` |
| `hover` y `hover_pressed` | `#1c5d6d` (`#081626` mezclado al 35 % con `#40e0f0`) | `#40e0f0` | `#befaff` |
| `pressed` (y un interruptor en ON) | `#144252` (mezclado al 22 %) | `#40e0f0` | `#befaff` |
| `disabled` | `#060b14` | `#1c4a60` | `#5a7a96` |
| `focus` | `StyleBoxEmpty`: sin marca, el juego es de ratón | | |

**Botones de las barras** (pestañas, INICIAR, AUTO, flechas `<` `>`, `TurretButton` y `EnemyCell`): crean sus estilos por código con `ClippedBoxStyle.create`, con sus propios colores y estados (ver cada uno). `FoldButton` (plegar la pausa) es un botón de icono sin caja.

## OverlayScreen

`scenes/level_ui/OverlayScreen.tscn` + `scripts/level_ui/OverlayScreen.gd` (clase `OverlayScreen`). Escena base de las pantallas que tapan el área de juego, con el tema `menu_theme.tres`. Contiene lo común:

- `Background`: `ColorRect` que oscurece el área de juego (color `dim_color`, negro por defecto, con opacidad `dim_opacity`).
- `Center` (`CenterContainer`) → `Frame` (`OverlayFrame`, ver abajo) → `Margin` (24 px a los lados, 21 arriba y 21 abajo, dentro de los 4 px del marco) → `Box` (`VBoxContainer`, 18 px de separación):
  - `Title` (`%Title`, `title_label`): fuente de 72 px en `#cce6ff` con contorno negro de 4 px, centrado. En la base no tiene texto; cada pantalla lo pinta en su acento.
  - `Options` (`%Options`, `options`): `VBoxContainer` con 9 px de separación, vacío en la base.

**`OverlayFrame`** (`scripts/level_ui/OverlayFrame.gd`, `PanelContainer`): el **panel holograma**. Su estilo `panel` es un `StyleBoxEmpty` que solo deja 4 px de margen (`FRAME_THICKNESS`); todo se pinta en `_draw` en píxeles enteros a partir de `accent_color`. De fuera hacia dentro:

1. **Brillo:** contorno de 1 px en `#0a0f1a` mezclado al 25 % con el acento.
2. **Borde exterior:** 1 px en el acento.
3. **Hueco:** 1 px en el color del fondo.
4. **Borde interior:** 1 px en `#0a0f1a` mezclado al 35 %.
5. **Fondo:** `#0a0f1a` mezclado al 15 % con el acento, al 85 % de opacidad (se intuye el mapa detrás), con **líneas de barrido**: una fila de cada dos un 25 % más oscura.

Las esquinas de arriba a la izquierda y de abajo a la derecha van **recortadas en diagonal**: `corner_clip` px en el borde exterior (6 por defecto). Cada capa está 1 px más adentro y con 1 px menos de recorte, así las diagonales de las capas se tocan como los bordes rectos. Se dibujan con las funciones estáticas de `ClippedBoxStyle` (ver "Botones").

Con `decorated` (por defecto), además:

- **Regla de marcas** arriba, a 7 px del borde y 8 de los lados, en `#0a0f1a` mezclado al 50 %. Es la de `ScreenHeader` (`ScreenHeader.draw_ruler`).
- **Corchetes** en L de 6 px por fuera de las cuatro esquinas, separados 3 px del panel, en `accent_light_color`. Sobresalen `OUTSIDE_MARGIN` (4 px) del panel.

`FoldedTag` (la etiqueta plegada de la pausa) es otro `OverlayFrame` con `corner_clip = 3` y `decorated = false`: mismo doble borde, recortes y barrido, sin regla ni corchetes.

Cuatro `@export` en la base, que cada escena heredada fija en su `.tscn`:

| Pantalla | `accent_color` | `accent_light_color` | `dim_color` | `dim_opacity` |
|---|---|---|---|---|
| Pausa | cian `#40e0f0` | `#befaff` | negro | 0,6 (toda la pantalla, ver "PauseMenu") |
| Derrota | rojo `#ff3c5a` | `#ffaabe` | rojo muy oscuro `#1a0509` | 0,6 |
| Victoria | ámbar `#ecb23c` | `#ffe082` | negro | 0,45 |

`_ready` aplica el acento y su tono claro al marco y a los botones, el oscurecido al fondo, y conecta el `pressed` de cada `OverlayOptionButton` de `Options`. Enum `Option { RESUME, RESTART, QUIT, NEXT_LEVEL, SETTINGS }` y una sola señal, `option_chosen(option)`.

La pantalla no toca su visibilidad: la decide `LevelUI.set_state()`. Una pantalla con comportamiento propio extiende `OverlayScreen` con un script (como `PauseScreen` y `GameOverScreen`).

**`OverlayOptionButton`** (`scripts/level_ui/OverlayOptionButton.gd`, `Button`): `@export var option`, `@export var accent_color` y `@export var accent_light_color` (se los pasa la pantalla). Es un juego de ratón: `focus_mode = NONE`, sin teclado salvo Escape (lo gestiona `LevelUI`). Es el botón recortado del tema en el acento de su pantalla: toma cada estilo del tema (`normal`, `hover`, `pressed`, `hover_pressed`, `disabled`) y lo copia con `ClippedBoxStyle.recolored`, así que la forma y los márgenes son los del tema y solo cambian los colores, que salen de `#060b14` mezclado con el acento:

| Estado | Fondo | Borde | Texto |
|---|---|---|---|
| Normal | base mezclada al 7 % | base mezclada al 45 % | `#cce6ff` |
| Ratón encima | fondo normal mezclado al 35 % (relleno con el acento) | acento | `accent_light_color` |
| Pulsado | fondo normal mezclado al 22 % | acento | `accent_light_color` |
| Desactivado | `#060b14` | base mezclada al 25 % | `#5a7a96` |

No dibuja nada propio en `_draw`. Miden 204x36 (texto a 24) con 9 px de separación y van centrados en horizontal.

## PauseMenu

`scenes/level_ui/PauseMenu.tscn`, escena heredada de `OverlayScreen.tscn` con el script `scripts/level_ui/PauseScreen.gd` (clase `PauseScreen`). Título "PAUSA" y opciones "Continuar" (`RESUME`), "Opciones" (`SETTINGS`, ver abajo), "Reiniciar" (`RESTART`) y "Salir" (`QUIT`). Aparece al instante, sin animación de entrada.

- **Cursor:** el título es "PAUSA" en cian y a su derecha hay un `Label` "_" (creado en `_add_cursor`, en un `HBoxContainer` con el título) que parpadea cada 0,5 s con la opacidad, así el panel no cambia de tamaño. Se enciende cada vez que se abre la pausa.
- **Plegado:** `FoldButton` (12x12, icono `assets/ui/fold.png`, sin tooltip ni foco) arriba a la derecha dentro del marco, debajo de la regla. Es un botón de icono sin caja (todos sus estilos son `StyleBoxEmpty`): el icono se ve al 60 % y a plena luz con el ratón encima. Al pulsarlo se ocultan `Background` y `Frame` y se enseña `FoldedTag`, un `OverlayFrame` pequeño (ver `OverlayFrame`) con "PAUSA" a 16 px en cian, a 3 px de la esquina superior izquierda del área de juego. Plegada no hay oscurecido y el mapa se ve limpio; el juego sigue en pausa. Clic izquierdo en la etiqueta: se despliega. Escape, plegada o no, quita la pausa (lo gestiona `LevelUI`). Al volver a pausar, `_on_shown` la despliega siempre.
- Plegar y desplegar es solo cosa de `PauseScreen`: `LevelUI` sigue en `PAUSED`.
- **Oscurecido:** negro al 60 % (`dim_opacity` 0,6, el mismo que el foco del tutorial) sobre **toda la pantalla**, barras incluidas: `PauseScreen._ready` pone su `Background` en `top_level` y a pantalla completa (la pausa vive en `GameArea`) e ignorando el ratón (los controles `top_level` se miran antes al buscar dónde cae el ratón y si no taparía los botones de la pausa), y `PauseMenu` tiene `z_index` 2 para pintarse encima de las barras. Plegada, el oscurecido se quita.
- **Deshabilita todo:** con la pausa, `LevelUI.set_state` pone `mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED` en `Sidebar` e `InfoPanel` (no reciben el ratón, ni el hover) y lo devuelve a `INHERITED` al salir; siguen procesando, así que sus animaciones constantes (botones de torreta, escáner) no se paran. El mapa ya está parado (salvo la estación, que sigue girando). Solo responde la propia pausa.
- **Opciones:** `PauseScreen` escucha su propio `option_chosen` y, con `SETTINGS`, abre la instancia de `scenes/OptionsMenu.tscn` que cuelga de `PauseMenu` (`%OptionsMenu`, ver [menu.md](menu.md)) con `open_from(Center)`: el marco de la pausa se funde a las opciones sobre el mismo oscurecido y "Volver" regresa a él. `LevelUI` ignora `SETTINGS`. El juego sigue en pausa todo el rato; las opciones funcionan porque heredan `process_mode = ALWAYS` de `LevelUI`. Si la pausa se cierra con las opciones abiertas (Escape), `PauseScreen` llama a `close()` para que la siguiente pausa empiece por el marco.

## GameOverScreen

`scenes/level_ui/GameOver.tscn` (nodo `GameOverScreen`), escena heredada de `OverlayScreen.tscn` con el script `scripts/level_ui/GameOverScreen.gd` (clase `GameOverScreen`). Es la derrota, con personalidad de "señal perdida" en rojo `#ff3c5a`. Entra tras la cámara lenta (ver "Secuencia de derrota" en `LevelUI`).

- **Aspecto:** título "SEÑAL" / "PERDIDA" (dos líneas) en el rojo del acento. Oscurecido con `dim_color` `#1a0509` (rojo muy oscuro) al 60 %. Entre el título y las opciones va `RunSummary` (`%RunSummary`) con el acento rojo. Opciones "Reintentar" (`RESTART`) y "Menú" (`QUIT`). No conecta botones a mano: lo hace la base.
- **`GlitchLayer`** (`%GlitchLayer`): `ColorRect` entre `Background` y `Center` que tapa el área de juego, con `mouse_filter = IGNORE` y un `ShaderMaterial` con `resources/shaders/defeat_glitch.gdshader`. El shader lee la pantalla ya dibujada (`hint_screen_texture`, filtro nearest), así que trabaja sobre el mapa oscurecido pero no sobre el panel, que se dibuja después. Todo va sobre la rejilla de píxeles de juego (1 px de juego = 1 px del viewport de 960x540), sin desenfoque:
  - Bandas horizontales de 2, 4, 6 u 8 px; con probabilidad `0,4 × intensity` cada banda se desplaza un número entero de píxeles (hasta 40 × `intensity`) y se tiñe un poco de rojo. Las lecturas se limitan al área de juego, así que no entran trozos de las barras.
  - Estática: un `8 % × intensity` de los píxeles pasa a `#ffaabe`.
  - Estática residual (`residual`): algunas filas sueltas con píxeles tenues.
  - Líneas de barrido: una fila de cada dos algo más oscura.
  - El patrón cambia con el uniforme `seed`, que pone el script a saltos.
- **Glitch de entrada** (en `GameOverScreen`, con `delta` real porque la pantalla corre con el árbol en pausa y `time_scale` ya está en 1): cada `GLITCH_STEP_TIME` (0,05 s) cambia `seed`. Durante `INTRO_TIME` (0,5 s) la intensidad baja de 1 a 0,5 con ruido, el marco se ve u oculta al azar (cada vez más probable que se vea) y el título alterna entre visible y tenue. Después la intensidad es 0, `residual` = `RESIDUAL_STATIC` (0,12) y el panel queda estable; cada 2,5 a 5 s el título parpadea durante `TITLE_FLICKER_TIME` (0,15 s). Durante `INTRO_TIME` los botones tienen `mouse_filter = IGNORE` (no `disabled`, para que no cambien de aspecto) y pasan a `STOP` al acabar, así que no se pueden pulsar invisibles. Cada vez que se abre la pantalla, la entrada vuelve a empezar.
- Las barras no se tocan: el glitch solo cubre `GameArea` y las barras siguen activas para inspeccionar.
- `show_run_stats(stats)`: pasa el `RunStats` al `RunSummary`.

## RunSummary

`scenes/level_ui/RunSummary.tscn` + `scripts/level_ui/RunSummary.gd` (clase `RunSummary`). Resumen de partida reutilizable; no sabe en qué pantalla está. `PanelContainer` de 204 px de ancho (lo mismo que los botones), fondo `#0a0f1a`, borde de 1 px en el acento mezclado al 50 % y 3 px de margen. Dentro, el rótulo "RESUMEN" a 24 px en el acento y las filas. Las filas (`StatRow.create` con `font_size` 24, hueco de icono de 12, márgenes de 6 y 3 y separación de 6, la de la ficha a ×1,5) también van a 24 px.

- `@export var accent_color`: color del rótulo y del borde. La derrota lo pone en rojo y la victoria en ámbar.
- `show_stats(stats: RunStats)`: sustituye las filas por tres `StatRow` con los valores finales de golpe (así los enseña la derrota). Corta un conteo en curso:

| Icono | Nombre | Valor |
|---|---|---|
| `wave.png` | OLEADA | `"X/Y"` (oleada alcanzada / total) |
| `kills.png` | BAJAS (enemigos destruidos) | `UiFormat.abbreviate` |
| `cost.png` | GASTADO (dinero gastado) | `UiFormat.money` |

- `count_up(duration, delay = 0.0)`: opcional, después de `show_stats`. Pone enemigos destruidos y dinero gastado a 0 y, tras `delay` segundos, los hace contar hasta su valor en `duration` segundos (tween de tiempo real, curva cuártica que frena al final). Cada paso pasa por `UiFormat.abbreviate` o `UiFormat.money`, así que el texto tiene el formato del valor final y las filas (de ancho fijo) no saltan. La oleada no cuenta. `finish_count()` corta el conteo y deja los valores finales; `is_counting()` dice si hay uno en curso. Lo usa la victoria.
- `StatRow.get_value_label(row)` da la etiqueta del valor de una fila para cambiar su texto sin rehacerla.

Si alguna torreta ha matado, añade dos filas: TORRETA (nombre de la mejor, en mayúsculas) y SUS BAJAS.

`RunStats` está en [niveles.md](niveles.md).

## VictoryScreen

`scenes/level_ui/VictoryScreen.tscn` (heredada de `OverlayScreen.tscn`) + `scripts/level_ui/VictoryScreen.gd` (clase `VictoryScreen`, extiende `OverlayScreen`). Pantalla de celebración, contraparte de la derrota. Corre con el árbol en pausa (hereda `process_mode` ALWAYS de `LevelUI`), así que sus tweens y su `delta` son tiempo real.

- **Aspecto:** título "SECTOR" / "ASEGURADO" (dos líneas, sin tildes ni Ñ) en el ámbar del acento `#ecb23c`. Oscurecido negro al 45 %, más ligero que la derrota para que se vea el mapa ganado. Entre el título y las opciones va `RunSummary` (`%RunSummary`) con el acento ámbar. No conecta botones a mano: lo hace la base.
- **Entrada:** cada vez que se abre (`visibility_changed`), el nodo `Center` (que centra el marco) se coloca justo encima del área de juego (con los corchetes del marco, `OverlayFrame.OUTSIDE_MARGIN`, también fuera) y baja hasta su sitio en `SLIDE_TIME` (0,35 s): curva cúbica que frena hasta pasarse `SLIDE_OVERSHOOT_PX` (2 px) y vuelve a su sitio en los últimos `SLIDE_SETTLE_TIME` (0,08 s). La posición se redondea a píxeles enteros en cada paso. A la vez, el oscurecido se funde de 0 a su opacidad en `DIM_FADE_TIME` (0,2 s, con el `modulate` de `Background`).
- **Conteo:** al abrirse llama a `run_summary.count_up(COUNT_TIME, SLIDE_TIME)`: los números se ven a 0 mientras baja el marco y cuentan en `COUNT_TIME` (0,8 s) cuando llega. La oleada sale directamente ("Y/Y").
- **Saltar:** clic izquierdo en el oscurecido, el marco o el resumen (no en los botones) durante la entrada o el conteo: lo corta todo y deja el marco en su sitio, el oscurecido entero y los valores finales. Las opciones se pueden pulsar desde el principio. Al cerrarse la pantalla también se deja en su estado final.
- **Destellos:** tres destellos de cuatro puntas junto al título (a la izquierda y arriba a la derecha de "SECTOR" y a la derecha de "ASEGURADO"), pintados sobre el título con su señal `draw` y colocados según el ancho de cada línea. Son píxeles enteros con `draw_rect`, sin antialiasing: cruz de 1 px en `#ecb23c`, centro de 3x3 en cruz en `#ffe082` y, al tamaño máximo de 4 o más, cuatro píxeles en diagonal en `#96641e`. El largo de las puntas sube y baja en pasos de 1 px con un seno de ritmo y fase propios (máximos de 5, 3 y 4 px). No se reutiliza `_draw_sparkle` del menú porque usa polígonos y un halo suave.
- `show_run_stats(stats)`: pasa el `RunStats` al `RunSummary`.

Opciones "Siguiente sector" (`NEXT_LEVEL`) y "Menú" (`QUIT`, la misma opción que "Salir": lleva a la selección de nivel). `OverlayScreen.set_option_visible(option, visible)` oculta el botón de una opción y `set_option_text(option, text_key)` le cambia el texto; `LevelUI.setup` lo usa para quitar "Siguiente sector" cuando es el último nivel o el nivel no está en la lista.

## Comunicación con el resto

| Origen | Señal | Destino |
|---|---|---|
| `LevelState` | `money_changed` | `Sidebar.set_money` |
| `LevelState` | `selected_turret_changed` | `Sidebar.show_selected` |
| `LevelState` | `inspected_changed` | `InfoPanel.show_inspected` |
| `LevelState` | `sellable_turret_changed` | `InfoPanel.show_sellable` |
| `LevelState` | `sellable_turret_changed` | `LevelUI._on_sellable_turret_changed` (`TurretActions.show_for`) |
| `LevelState` | `money_changed` | `TurretActions.set_money` |
| `TurretActions` | `sell_requested` | `LevelUI._on_sell_requested` (`LevelState.sell_selected_turret`, solo en `PLAYING`) |
| `TurretActions` | `upgrade_requested` | `LevelUI._on_upgrade_requested` (`LevelState.upgrade_requested`, solo en `PLAYING`) |
| `Spawner` | `wave_started` | `LevelUI._on_wave_started` (`Sidebar.set_current_wave`, controles y pie) |
| `Spawner` | `wave_cleared` | `LevelUI._on_wave_cleared` (`Sidebar.view_wave` a la siguiente, controles y pie) |
| `Spawner` | `auto_waves_changed` | `Sidebar.show_auto_waves` |
| `Sidebar` | `turret_selected` | `LevelUI._on_turret_selected` (escribe en `LevelState`) |
| `Sidebar` | `inspect_requested` | `LevelUI._on_inspect_requested` (escribe `LevelState.inspected`) |
| `Sidebar` | `next_wave_requested` | `LevelUI._on_next_wave_requested` (`Spawner.start_next_wave`) |
| `Sidebar` | `auto_waves_toggled` | `LevelUI._on_auto_waves_toggled` (escribe `Spawner.auto_waves`) |
| `LevelState`, `Spawner` | `turret_placed`, `inspected_changed`, `sellable_turret_changed`, `upgrade_requested`, `wave_started`, `wave_cleared` | `TutorialHints` (solo en el nivel de emergencia) |
| `MeteorButton`, `FreezeButton` | `pressed` | `LevelUI._use_power` (`Powers.use`, solo en `PLAYING`) |
| `Sidebar` | `fast_speed_toggled` | `LevelUI._on_fast_speed_toggled` (cambia `_fast_speed` y reaplica `time_scale`) |
| `PauseMenu`, `GameOverScreen`, `VictoryScreen` | `option_chosen` | `LevelUI._on_option_chosen` (`RESUME` lo resuelve ella) |
| `LevelUI` | `action_requested` | `Game._on_action_requested` (reiniciar, volver al menú o pasar al siguiente nivel) |
| `LevelUI` | llamada directa | `Sidebar.set_selection_locked` (en cada `set_state`) |
| `LevelUI` | llamada directa | `Sidebar.set_wave_status` (pie "OL. X/Y" y estado, desde `_refresh_wave_controls`) |
| `LevelUI` | llamada directa | `GameOverScreen.show_run_stats` y `VictoryScreen.show_run_stats` (desde `show_run_stats`) |
| `GameOverScreen` | llamada directa | `RunSummary.show_stats` |
| `VictoryScreen` | llamada directa | `RunSummary.show_stats`, `count_up` y `finish_count` |
| `Game` | llamada directa | `LevelUI.show_run_stats(level.get_run_stats())` y después `LevelUI.set_state(LOST)` en la derrota o `set_state(WON)` en la victoria |

- **`_process` dormido:** las pantallas que animan (`GameOverScreen`, `PauseScreen`, `VictoryScreen`, `ScannerDisplay`, `SectorRadar`) solo procesan mientras se ven (`visibility_changed` → `set_process`). `Powers` duerme hasta que se usa un poder y vuelve a dormir al acabar recargas y rayo; `HeatGlow` duerme sin calor ni chispas y lo despierta el setter de `heat`/`overheated`.
