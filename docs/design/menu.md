# Menú principal, opciones y música

## Escena y script

`scenes/MainMenu.tscn` + `scripts/screens/MainMenu.gd`. Es la escena inicial del proyecto.

Nodos, de fondo a frente:

- `Background`: `ColorRect` negro.
- `MenuBackground`: el fondo propio del menú (ver "Fondo").
- `StarField`: estrellas que parpadean (ver "Decoración").
- `RingedPlanet`: el gigante gaseoso con anillos (ver "Fondo"). Va detrás de `StarField` para que ninguna estrella se pinte encima.
- `Comets`, `Asteroids`, `Satellites`, `Planets`, `Outpost`, `Skirmish`: decoración (ver "Decoración").
- `Vignette`: `Sprite2D` con `menu_vignette.png`, que oscurece los bordes en tramado por encima de la decoración y por debajo de los paneles, para centrar la vista en el título.
- `TitleScreen`: título "ASTRO ARTILLERY" y debajo el subtítulo "TOWER DEFENSE" (24 px, `#40e0f0`), flotando sin panel; debajo, `ButtonsPanel`, un panel holograma cian (`OverlayFrame`) con "Jugar", "Archivo", "Estadísticas", "Opciones" y "Salir" (204x36 todos, texto a 24). Márgenes del panel de 24 a los lados y 21 arriba y abajo, 18 de separación en `Content` y 9 entre botones.
- `LevelSelectionScreen` (oculto al empezar): `LevelsPanel`, un panel holograma cian con la cabecera `// SECTORES DISPONIBLES` (`ScreenHeader`), `LevelButtonsContainer` (`GridContainer` de 5 columnas, 12 px de separación) y el botón "Volver" (204x36). Cabecera y botones a 24 px. Mismos márgenes y separación que `ButtonsPanel`.
- `StatsScreen` (oculto al empezar): panel holograma con la cabecera `// ESTADÍSTICAS`, `StatsLabel` (24 px) y "Volver". Al abrirse (`_on_stats_button_pressed`) rellena cinco líneas con los totales de `GameState`: naves destruidas (`stats.kills`), dinero gastado (`stats.spent`, con `UiFormat.money`), tiempo jugado (`play_time`, en h y min), torreta favorita (la de mayor `stats.built_<torreta>`, "-" si no hay) y niveles ganados (`stats.wins`).
- `Navedex` (oculto al empezar): instancia de `scenes/Navedex.tscn` (ver "Navedex").
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

## Fondo

`scenes/MenuBackground.tscn` y el nodo `RingedPlanet`. Siguen el estilo del fondo de los niveles (`SpaceBackground`, ver [niveles.md](niveles.md)): tonos planos muy oscuros, transiciones en tramado de píxeles y cuerpos con bandas onduladas. Pero no es el mismo, para que el menú tenga identidad propia: otra paleta (verde azulado en vez de morado) y otra composición.

- `Nebula`: `Parallax2D` a -2 px/s, repetida en horizontal cada 960 px, con `menu_nebula.png`: nubes verde azuladas y una banda de estrellas ondulada que cruza la pantalla, con una franja de polvo oscuro rota por dentro. Las estrellas van pintadas en la imagen, más juntas en la banda.
- `RingedPlanet` (nodo de `MainMenu`, no de esta escena, para quedar delante de `StarField`): gigante gaseoso ámbar con dos anillos (`menu_planet.png`), en (820, 446), iluminado desde arriba a la izquierda y con la sombra de los anillos sobre el planeta.
- `Comet`: el cometa de los niveles (`Comet.gd`), cruzando toda la pantalla (`width` = 990) por detrás del planeta.

Las tres imágenes (`assets/sprites/backgrounds/menu/`) no se dibujan a mano: las genera `scripts/tools/make_menu_background.gd` (`godot --headless --path . -s scripts/tools/make_menu_background.gd`). Paletas, forma de la banda, tamaño y anillos del planeta y viñeta son constantes del script: para retocarlos se cambian y se vuelve a lanzar.

## Decoración

Todos son `Node2D` que dibujan o crean sprites por código, con posiciones y tiempos al azar.

| Nodo | Script | Qué hace |
|---|---|---|
| `StarField` | `scripts/main_menu/Starfield.gd` | 77 estrellas de 1 px en tres brillos (un 30 % parpadea) y 6 destellos de cuatro puntas en blanco, cian, morado o naranja. `warp(duration)` los estira en líneas de 1 px (sin antialiasing, mismos colores) desde el centro hacia fuera |
| `Comets` | `scripts/main_menu/Comets.gd` | Cada 1,5 a 4 s cruza un cometa en diagonal suave por la franja superior o inferior, a 220 px/s, con estela |
| `Asteroids` | `scripts/main_menu/Asteroids.gd` | Hasta 2 asteroides a la vez cruzan de un borde al opuesto a 60 px/s, con estela; aparece uno cada 3 a 7 s |
| `Satellites` | `scripts/main_menu/Satellites.gd` | Un satélite cada vez, a 20-30 px/s y girando despacio; el siguiente sale entre 8 y 15 s después de irse el anterior |
| `Planets` | instancias de `scenes/SpaceBody.tscn` | Solo un asteroide oculto: el único planeta del menú es `RingedPlanet` |
| `Outpost` | `scripts/main_menu/Outpost.gd` (clase `Outpost`) | En (120, 286), a ×0,5 y con el tono de las naves de `Skirmish` (`modulate` opaco), como parte del fondo. La estación del jugador (`estacion.tres`, animación `fase_0`) con tres torretas alrededor (Cañón doble, Láser y otro Cañón doble), con los sprites de base y cañón de sus `TurretData`. `fire_at(target)` gira hacia `target` el cañón más cercano, le pone su animación de disparo si la tiene y devuelve la posición de la boca |
| `Skirmish` | `scripts/main_menu/Skirmish.gd` | Entre `Outpost` y el panel. Cada 6-12 s cruza un grupo de 2-4 naves enemigas en V (mismo sprite, ×0,5, oscurecidas con `SHIP_TINT` pero opacas, para que no transparenten lo que tengan detrás, 60 px/s, siempre en horizontal y giradas hacia donde avanzan igual que `Enemy._update_animation`) por las franjas de arriba o abajo, lejos de los botones. Cada 1,5-4 s un disparo (línea cian de 1 px) apuntando a una nave: si tiene `outpost`, sale de la boca de una torreta del puesto (`Outpost.fire_at`); si no, desde fuera de la pantalla por arriba o abajo; siempre hace un impacto (`laser_impact`) y el 40 % de las veces la nave se destruye |

`scripts/main_menu/SpaceBody.gd` (clase `SpaceBody`) es un `AnimatedSprite2D` con `@tool` que construye su `SpriteFrames` a partir de `sheet`, una tira horizontal de frames cuadrados (lado = alto de la imagen), a la velocidad `fps`. Lo usan los planetas del menú y los asteroides.

## Salto al hiperespacio

`MainMenu._open_level` (una sola vez, ignora más pulsaciones) llama a `_hyperspace_jump()`: `StarField.warp(0.5)` y un `ColorRect` blanco que cubre el menú en 0,1 s; después carga el nivel. Solo desde el menú ("Siguiente nivel" no hace el salto).

## Navedex

`scenes/Navedex.tscn` + `scripts/screens/Navedex.gd` (clase `Navedex`). Archivo de naves y torretas, accesible con "Archivo" en el título (mismo fundido de 0,25 s que Jugar/Opciones; emite `back_pressed` con "Volver"). Panel holograma (`OverlayFrame`) con cabecera `// ARCHIVO`, una `TabBar` NAVES / TORRETAS, a la izquierda una cuadrícula de 4 columnas (celdas `EnemyCell` sin contador, que valen para cualquier `InspectableData`) y a la derecha el detalle: sprite (animado `up` en las naves, `icon` en las torretas) a ×2, nombre, `description` y stats (`get_stats()` con `StatRow` a 24 px). En las torretas base se añade una línea "MEJORA: nombre".

- Un enemigo es "visto" si `GameState.has_seen_enemy(data)`. Los no vistos salen en silueta negra (`modulate` negro) y su detalle dice "???" sin stats.
- Al mostrarse se refrescan las siluetas y se elige el primer enemigo.
- Las torretas (`TURRET_FILES`, cada base seguida de su fusión) siempre se ven completas.
- Si se añade un enemigo o torreta nuevos, hay que añadirlo a `ENEMY_FILES` / `TURRET_FILES`.

### Logros

Tercera pestaña de la Navedex, LOGROS: oculta cuadrícula y detalle y muestra `AchievementsList`, una línea `[X] nombre - descripción` por logro. Los 12 logros están en `GameState.ACHIEVEMENTS` (id -> nombre y descripción) y cómo se cumple cada uno en `GameState._is_done()`. Se guardan en `progress.cfg` (`unlocked`, más los contadores `stats` y `fused_turrets`) y "Borrar progreso" los borra. `GameState._ready` migra una vez los nombres antiguos de ese archivo (`fused_towers`, contador `towers` y logro `towers_50`) a `fused_turrets`, `turrets` y `turrets_50`.

- Contadores (`GameState.add_stat`): bajas (`Level`, por `enemy_died`), torretas construidas, poderes usados, oleadas perfectas y niveles ganados. `register_fusion` lo llama `BuildManager.upgrade_selected`; `register_win(número, intacto)` lo llama `Game` al ganar (intacto = la estación con toda la vida).
- Los contadores se guardan con `flush()` al limpiar una oleada y al ganar o perder, no a cada baja; al desbloquear un logro se guarda al momento.
- Al conseguir uno sale `LOGRO: nombre` arriba a la derecha 3 s y se desvanece (capa propia de `GameState`, también en pausa y victoria).

## Música

`scripts/autoloads/MusicManager.gd`, autoload de tipo `AudioStreamPlayer`.

- Carga `assets/audio/music/theme.ogg` (el bucle va activado en su import) y la reproduce al arrancar. Si el archivo no existe, avisa y no suena nada.
- `process_mode = ALWAYS`: sigue sonando con el juego en pausa. Al ser autoload no se corta al cambiar de escena.
- Suena por el bus `Music`. No guarda volumen ni silencio: eso lo lleva `Settings` a través de los buses.

Convención de formatos: los audios largos o en bucle (música, ambientes, sonidos de nave largos, GameOver y Victory) van en OGG Vorbis; los efectos cortos, en WAV. Solo `theme` y los dos ambientes (`LevelAmbience/`) tienen `loop=true` en el import.

Es el único audio del juego: todavía no hay efectos de sonido, así que nada suena por el bus `SFX`.

## Opciones

`scenes/OptionsMenu.tscn` + `scripts/screens/OptionsMenu.gd` (clase `OptionsMenu`). Un panel holograma cian (`OverlayFrame`) centrado, con los mismos márgenes que el menú principal (24 / 21), con el título "OPCIONES", dos columnas de secciones con cabeceras `// AUDIO`, `// PANTALLA` y `// JUEGO`, y debajo el bloque de botones "Borrar progreso" y "Volver" (ver más abajo). Etiquetas, cabeceras y botones a 24 px. Columnas separadas 36 px. La misma escena está instanciada en el menú principal y en el menú de pausa (ver [ui.md](ui.md)).

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
| JUEGO | Botón "Rango de torretas" | `show_turret_range` |

"Borrar progreso" no es un ajuste: es un botón propio (204x36, variación de tema `DangerButton`: borde y texto `#ff3c5a`, y en hover relleno `#961432` con texto `#ffaabe`). Va en `ButtonsBlock`, un bloque con "Volver" (ambos 204x36, separados 9 px) que queda debajo de las columnas con 9 px extra de margen (`ButtonsMargin`), así que se separa más de las secciones que los botones entre sí. No guarda ninguna opción: llama a `GameState.reset_progress()`. La primera pulsación cambia su texto a "¿Seguro?" y lo deja relleno de rojo (armado) durante `CONFIRM_TIME` (3 s); el ancho es fijo, así que ni el botón ni el panel cambian de tamaño. Si se pulsa de nuevo en ese tiempo (cada aviso lleva un número, así que el temporizador de un aviso anterior no cancela el nuevo), `GameState.reset_progress()` vuelve `current_level` a 1, guarda y emite `progress_reset`, y el menú principal reconstruye los botones de nivel. Pasados los 3 s sin pulsar, vuelve a "Borrar progreso". Se oculta cuando Opciones se abre desde la pausa (`open_from(opener, allow_reset = false)`).

Los deslizadores (96x12, tirador de 5x11) van de 0 a 1 en pasos de 0,05 (colores de la paleta en `menu_theme.tres`, ver [art.md](art.md)). Los botones son interruptores de 54x24 (texto a 24) con la variación de tema `ToggleButton`: en ON van rellenos de cian (como el ratón encima) y muestran "ON"; en OFF van con el estilo normal y muestran "OFF". Al abrirse, cada control toma su valor de `Settings`; cada cambio llama a `Settings.set_value`.

### Settings

`scripts/autoloads/Settings.gd`, autoload. Guarda las opciones en `user://settings.cfg` (sección `settings`) con `ConfigFile`.

- Al arrancar carga el archivo y aplica todas las opciones. Si el archivo no existe, falta una clave o su valor no es del tipo esperado, vale el valor por defecto: volúmenes a 1, `vsync` activado y el resto desactivado. Las claves que no conoce (por ejemplo la antigua `ambient_volume`) se ignoran y desaparecen del archivo en el siguiente guardado. La excepción es `LEGACY_KEYS`: `show_turret_range` también se lee de su nombre antiguo (`show_tower_range`) si el archivo aún no tiene la nueva.
- `get_value(key)` y `set_value(key, value)`. `set_value` aplica el cambio, guarda el archivo y emite `changed(key)`.
- Los tres volúmenes son lineales y se aplican a los buses `Master`, `Music` y `SFX`, definidos en `default_bus_layout.tres`. El bus `SFX` es para los sonidos de torretas, explosiones y demás efectos.
- `muted` silencia el bus `Master` sin cambiar los volúmenes, así que al quitarlo los deslizadores conservan su valor.
- `fullscreen` y `vsync` se aplican con `DisplayServer`.
- `show_fps` y `show_turret_range` no hacen nada aquí: las leen `LevelUI` (ver [ui.md](ui.md)) y `Turret` (ver [torretas.md](torretas.md)), que escuchan `changed` para actualizarse al momento.

## Dudas

- El fundido está escrito dos veces: en `MainMenu._transition` (título y selección de nivel) y en `OptionsMenu._fade`.
- Pantalla completa y VSync no tienen efecto si el juego se ejecuta incrustado en el editor de Godot; hay que ejecutarlo en su propia ventana.
