# Menú principal, opciones y música

## Escena y script

`scenes/MainMenu.tscn` + `scripts/screens/MainMenu.gd`. Es la escena inicial del proyecto.

Nodos, de fondo a frente:

- `Background`: `ColorRect` negro.
- `StarField`, `Comets`, `Asteroids`, `Satellites`, `Planets`: decoración (ver abajo).
- `TitleScreen`: título "ASTRO ARTILLERY" y debajo el subtítulo "TOWER DEFENSE" (24 px, `#40e0f0`), flotando sin panel; debajo, `ButtonsPanel`, un panel holograma cian (`OverlayFrame`) con "Jugar", "Opciones" y "Salir" (204x36 todos, texto a 24). Márgenes del panel de 24 a los lados y 21 arriba y abajo, 18 de separación en `Content` y 9 entre botones.
- `LevelSelectionScreen` (oculto al empezar): `LevelsPanel`, un panel holograma cian con la cabecera `// SECTORES DISPONIBLES` (`ScreenHeader`), `LevelButtonsContainer` (`GridContainer` de 5 columnas, 12 px de separación) y el botón "Volver" (204x36). Cabecera y botones a 24 px. Mismos márgenes y separación que `ButtonsPanel`.
- `OptionsMenu` (oculto al empezar): instancia de `scenes/OptionsMenu.tscn` (ver "Opciones").

Textos en Monogram (ver [art.md](art.md)): el título "ASTRO ARTILLERY" a 72 px, "OPCIONES" a 48 px (en `#40e0f0`) y el resto (botones, rótulos, interruptores) a 24 px (todo ×1,5 sobre el tamaño base de 16, 32 y 48).

## Comportamiento

- "Jugar" y "Volver" cambian entre el título y la selección de nivel con un fundido de 0,25 s de salida y otro de entrada.
- "Opciones" llama a `OptionsMenu.open_from(TitleScreen)`, que hace el mismo fundido; "Volver" regresa al título.
- "Salir" cierra el juego.
- Si `start_on_level_selection` es `true` (lo pone `Game` al volver de un nivel), el menú abre directamente en la selección de nivel.
- `_build_level_buttons()` crea un `LevelButton` de 60x60 (número a 24) por cada entrada de `GameData.levels`, numerado desde 1 y desactivado si `GameState.is_unlocked(i)` es `false`.
- `LevelButton` (`scripts/level_ui/LevelButton.gd`) emite `level_selected(data)` al pulsarse.
- `_open_level(data)` instancia `scenes/Game.tscn`, le asigna `level_data` y la pone como escena actual.

## Decoración

Todos son `Node2D` que dibujan o crean sprites por código, con posiciones y tiempos al azar.

| Nodo | Script | Qué hace |
|---|---|---|
| `StarField` | `scripts/main_menu/Starfield.gd` | 77 estrellas de 1 px en tres brillos (un 30 % parpadea) y 6 destellos de cuatro puntas en blanco, cian, morado o naranja |
| `Comets` | `scripts/main_menu/Comets.gd` | Cada 1,5 a 4 s cruza un cometa en diagonal suave por la franja superior o inferior, a 220 px/s, con estela |
| `Asteroids` | `scripts/main_menu/Asteroids.gd` | Hasta 2 asteroides a la vez cruzan de un borde al opuesto a 60 px/s, con estela; aparece uno cada 3 a 7 s |
| `Satellites` | `scripts/main_menu/Satellites.gd` | Un satélite cada vez, a 20-30 px/s y girando despacio; el siguiente sale entre 8 y 15 s después de irse el anterior |
| `Planets` | instancias de `scenes/SpaceBody.tscn` | 6 planetas animados fijos, repartidos por los 960x540 (posiciones proporcionales a las que tenían en 640x272, con sus escalas), y un asteroide oculto |

`scripts/main_menu/SpaceBody.gd` (clase `SpaceBody`) es un `AnimatedSprite2D` con `@tool` que construye su `SpriteFrames` a partir de `sheet`, una tira horizontal de frames cuadrados (lado = alto de la imagen), a la velocidad `fps`. Lo usan los planetas del menú y los asteroides.

## Música

`scripts/autoloads/MusicManager.gd`, autoload de tipo `AudioStreamPlayer`.

- Carga `assets/audio/music/theme.mp3`, la pone en bucle y la reproduce al arrancar. Si el archivo no existe, avisa y no suena nada.
- `process_mode = ALWAYS`: sigue sonando con el juego en pausa. Al ser autoload no se corta al cambiar de escena.
- Suena por el bus `Music`. No guarda volumen ni silencio: eso lo lleva `Settings` a través de los buses.

Es el único audio del juego: todavía no hay efectos de sonido, así que nada suena por el bus `SFX`.

## Opciones

`scenes/OptionsMenu.tscn` + `scripts/screens/OptionsMenu.gd` (clase `OptionsMenu`). Un panel holograma cian (`OverlayFrame`) centrado, con los mismos márgenes que el menú principal (24 / 21), con el título "OPCIONES", dos columnas de secciones con cabeceras `// AUDIO`, `// PANTALLA` y `// JUEGO`, y el botón "Volver" (204x36). Etiquetas, cabeceras y botones a 24 px. Columnas separadas 36 px. La misma escena está instanciada en el menú principal y en el menú de pausa (ver [ui.md](ui.md)).

- `open_from(opener)`: funde de `opener` (el panel que la abre) a las opciones, 0,25 s de salida y 0,25 s de entrada, y recuerda `opener`.
- "Volver" hace el fundido inverso hacia ese mismo panel.
- `close()`: oculta las opciones y vuelve a mostrar el panel de origen sin fundido.

| Sección | Control | Opción de `Settings` |
|---|---|---|
| AUDIO | Deslizador "General" | `master_volume` |
| AUDIO | Deslizador "Música" | `music_volume` |
| AUDIO | Deslizador "Efectos" | `sfx_volume` |
| AUDIO | Botón "Silenciar" | `muted` |
| PANTALLA | Botón "Pantalla completa" | `fullscreen` |
| PANTALLA | Botón "VSync" | `vsync` |
| PANTALLA | Botón "Mostrar FPS" | `show_fps` |
| JUEGO | Botón "Rango de torres" | `show_tower_range` |

"Borrar progreso" no es un ajuste: es un botón propio (204x30, variación de tema `DangerButton`: borde y texto `#ff3c5a`, y en hover relleno `#961432` con texto `#ffaabe`), centrado debajo de las columnas y encima de "Volver". No guarda ninguna opción: llama a `GameState.reset_progress()`. La primera pulsación cambia su texto a "¿Seguro?" y lo deja relleno de rojo (armado) durante `CONFIRM_TIME` (3 s); el ancho es fijo, así que ni el botón ni el panel cambian de tamaño. Si se pulsa de nuevo en ese tiempo (cada aviso lleva un número, así que el temporizador de un aviso anterior no cancela el nuevo), `GameState.reset_progress()` vuelve `current_level` a 1, guarda y emite `progress_reset`, y el menú principal reconstruye los botones de nivel. Pasados los 3 s sin pulsar, vuelve a "Borrar progreso". Se oculta cuando Opciones se abre desde la pausa (`open_from(opener, allow_reset = false)`).

Los deslizadores (96x12, tirador de 5x11) van de 0 a 1 en pasos de 0,05 (colores de la paleta en `menu_theme.tres`, ver [art.md](art.md)). Los botones son interruptores de 54x24 (texto a 24) con la variación de tema `ToggleButton`: en ON van rellenos de cian (como el ratón encima) y muestran "ON"; en OFF van con el estilo normal y muestran "OFF". Al abrirse, cada control toma su valor de `Settings`; cada cambio llama a `Settings.set_value`.

### Settings

`scripts/autoloads/Settings.gd`, autoload. Guarda las opciones en `user://settings.cfg` (sección `settings`) con `ConfigFile`.

- Al arrancar carga el archivo y aplica todas las opciones. Si el archivo no existe, falta una clave o su valor no es del tipo esperado, vale el valor por defecto: volúmenes a 1, `vsync` activado y el resto desactivado. Las claves que no conoce (por ejemplo la antigua `ambient_volume`) se ignoran y desaparecen del archivo en el siguiente guardado.
- `get_value(key)` y `set_value(key, value)`. `set_value` aplica el cambio, guarda el archivo y emite `changed(key)`.
- Los tres volúmenes son lineales y se aplican a los buses `Master`, `Music` y `SFX`, definidos en `default_bus_layout.tres`. El bus `SFX` es para los sonidos de torretas, explosiones y demás efectos.
- `muted` silencia el bus `Master` sin cambiar los volúmenes, así que al quitarlo los deslizadores conservan su valor.
- `fullscreen` y `vsync` se aplican con `DisplayServer`.
- `show_fps` y `show_tower_range` no hacen nada aquí: las leen `LevelUI` (ver [ui.md](ui.md)) y `Tower` (ver [torres.md](torres.md)), que escuchan `changed` para actualizarse al momento.

## Dudas

- El fundido está escrito dos veces: en `MainMenu._transition` (título y selección de nivel) y en `OptionsMenu._fade`.
- Pantalla completa y VSync no tienen efecto si el juego se ejecuta incrustado en el editor de Godot; hay que ejecutarlo en su propia ventana.
