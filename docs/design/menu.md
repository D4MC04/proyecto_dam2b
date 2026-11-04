# Menú principal, opciones y música

## Pantalla de inicio

`scenes/StartScreen.tscn` + `scripts/screens/StartScreen.gd`. Es la escena inicial del proyecto (`run/main_scene`). De fondo, el mismo espacio que el menú: los nodos `Background`, `MenuBackground`, `StarField`, `RingedPlanet`, `Comets`, `Asteroids`, `Satellites`, `Outpost`, `Skirmish` y `Vignette`, con las mismas escenas, scripts y posiciones (ver "Fondo" y "Decoración"). Encima va la interfaz, en fases (`Phase { TITLE, SLOTS, CONFIRM, ENTERING }`):

- **Título:** `TitleBlock`, "ASTRO ARTILLERY" (72 px) y "TOWER DEFENSE" (24 px, `#40e0f0`) como en el menú, entra con un fundido de 0,6 s con su fila de arriba en y = 168. Debajo, en y = 352, `PressKeyLabel` "PULSA CUALQUIER TECLA" (24 px, `#befaff`) parpadea a golpes: 0,6 s encendido de cada segundo. Cualquier tecla, clic (izquierdo, derecho o central) o botón de mando lo hace parpadear rápido 6 veces (cada 0,05 s) y desaparecer, y a la vez el título se desvanece subiendo 16 px (0,35 s).
- **Ranuras:** `SlotsPanel`, un panel holograma cian (`OverlayFrame`, márgenes 24 / 21, 18 px de separación) centrado, con la fila de arriba en y = 104 (centrado en vertical, ya sin título), con la cabecera `// SELECCIONA PARTIDA` (24 px) y `SlotList`, las 3 ranuras en vertical separadas 12 px. Debajo, en y = 460, `HintLabel` "ESC  VOLVER" (16 px, `#5a7a96`). Al entrar, el panel funde en 0,2 s y las tarjetas llegan escalonadas (0,09 s entre una y otra): se deslizan 16 px desde la derecha mientras se descubren de arriba abajo con una línea de escaneo `#befaff` (0,24 s), y después aparecen sus textos y su botón de borrar (0,15 s). Escape funde las ranuras y el título vuelve bajando a su sitio mientras aparece, con el texto parpadeando otra vez.
- **Confirmar borrado:** el botón de borrar de una ranura abre `ConfirmLayer`: oscurece todo (negro al 70 %) y muestra un panel holograma rojo (`#ff3c5a`, corchetes `#ffaabe`) con "¿SEGURO?" (48 px, `#ffaabe`), "Se borrará la partida de la ranura N. No se puede deshacer." (24 px) y los botones "Borrar" (`DangerButton`) y "Cancelar", de 132x36 y separados 12 px. Aparece y se va con un fundido de 0,2 s. "Cancelar", Escape o un clic fuera del panel lo cierran sin hacer nada. "Borrar" llama a `GameState.delete_slot(n)`, cierra la caja y la tarjeta vuelve a entrar, ya como "NUEVA PARTIDA".
- **Entrar:** pulsar una tarjeta llama a `GameState.load_slot(n)`; si la ranura estaba vacía, además a `GameState.flush()`, para que quede ocupada desde ese momento. Después, el efecto de entrada: la cabecera, el aviso, las otras tarjetas y los botones de borrar se funden en 0,2 s mientras la tarjeta elegida destella 3 veces en `#befaff` (0,07 s por subida y por bajada) y se queda encendida; un `ScreenWipe` tapa la pantalla desde el centro de la tarjeta (0,7 s), se espera 0,15 s en oscuro, se cambia a `MainMenu` (a mano, como en "Cambio de escena" de [flujo.md](flujo.md)) y el mismo `ScreenWipe` la destapa desde el centro de la pantalla (0,6 s). No se parece al salto al hiperespacio, que es el de entrar a un nivel.

Mientras dura una animación, `InputBlocker` (un `Control` a pantalla completa) para el ratón y se ignoran las teclas. Las posiciones animadas (título y tarjetas) se redondean a píxeles enteros.

Volver de un nivel (`Game._quit_to_menu`) va directo a `MainMenu`, sin pasar por aquí.

### SlotCard

`scripts/main_menu/SlotCard.gd` (clase `SlotCard`, `Button`). Tarjeta de 432x72 de una ranura. Los estilos del tema están vacíos: todo se pinta en `_draw`, fila a fila y en píxeles enteros, con la forma de los botones (esquinas de arriba a la izquierda y de abajo a la derecha recortadas 6 px, `ClippedBoxStyle.row_span`) y las líneas de barrido del panel holograma (una fila de cada dos un 25 % más oscura). Sin foco (el juego es de ratón).

- Fondo `#081626` al 92 %, mezclado con `#40e0f0` al 18 % con el ratón encima y al 26 % pulsada. Borde de 1 px `#1c7496` (con partida), `#1c4a60` (vacía) o `#40e0f0` (ratón encima o pulsada).
- A la izquierda, una pestaña de 56 px con el número de la ranura a 48 px centrado por su tinta (alto de las mayúsculas y ancho de un número de Monogram, `GLYPH_CAP` y `DIGIT_WIDTH`, no por la caja de la línea) (`#40e0f0` con partida, `#1c7496` vacía, `#befaff` con el ratón encima) y una línea divisoria del color del borde.
- Con partida (`set_summary` con `GameState.get_slot_summary`): el texto empieza 18 px después de la pestaña y acaba 22 px antes del borde derecho. "SECTOR 07" (24 px, `#cce6ff`; el sector no pasa del número de niveles) y a la derecha "X/12" en ámbar `#ecb23c` con, 4 px a su izquierda, `assets/ui/slot_achievements.png` (moneda con estrella de 12x12, centrada en el alto de los números); debajo, a 16 px, "GUARDADO" y la fecha y hora locales del último guardado ("03/11/2026 18:42") a la izquierda y "JUGADO" y el tiempo jugado ("1h 19m") a la derecha, con los rótulos en `#5a7a96`.
- Sin partida: "+ NUEVA PARTIDA" (24 px, `#40e0f0`) y debajo "RANURA VACÍA" (16 px, `#5a7a96`).
- Con el ratón encima, una fila más clara recorre la tarjeta de arriba abajo cada 1,4 s.
- `reveal` (0..1): filas descubiertas en la entrada, con una línea `#befaff` en el borde. `content_alpha`: opacidad de los textos. `flash` (0..1): destello al elegirla, que lleva fondo y borde hacia `#befaff`.

El botón de borrar es un `Button` de 36x36 con la variación `DangerButton`, centrado en vertical a 9 px a la derecha de la tarjeta, solo en las ranuras con partida. Lleva una cruz de píxeles de 10x10 y 2 px de grueso en el color del texto (`#ff3c5a`, `#ffaabe` con el ratón encima). Como `DangerButton` no define el estado pulsado con el ratón encima, se le pone el de hover (igual que a "Borrar" de la confirmación).

### ScreenWipe

`scripts/main_menu/ScreenWipe.gd` (clase `ScreenWipe`, `CanvasLayer` en la capa 100) con el shader `resources/shaders/screen_wipe.gdshader` sobre un `ColorRect` a pantalla completa que para el ratón. Se añade a la raíz del árbol, no a la escena, para sobrevivir al cambio de escena.

- `cover(origin, duration)`: tapa la pantalla en celdas de 4x4 px que avanzan desde `origin` hacia fuera. Cada celda se tapa según su distancia a `origin` (80 %) y una matriz de Bayer 4x4 (20 %), así que el frente sale tramado. Las celdas tapadas son `#060b14`; el frente, `#40e0f0` con su borde exterior en `#befaff`.
- `uncover(origin, duration)`: lo contrario, destapando primero lo más cercano a `origin`; al acabar se libera.

## Escena y script

`scenes/MainMenu.tscn` + `scripts/screens/MainMenu.gd`. Se llega desde la pantalla de inicio, al elegir ranura, o al salir de un nivel (ver [flujo.md](flujo.md)).

Nodos, de fondo a frente:

- `Background`: `ColorRect` negro.
- `MenuBackground`: el fondo propio del menú (ver "Fondo").
- `StarField`: estrellas que parpadean (ver "Decoración").
- `RingedPlanet`: el gigante gaseoso con anillos (ver "Fondo"). Va detrás de `StarField` para que ninguna estrella se pinte encima.
- `Comets`, `Asteroids`, `Satellites`, `Planets`, `Outpost`, `Skirmish`: decoración (ver "Decoración").
- `Vignette`: `Sprite2D` con `menu_vignette.png`, que oscurece los bordes en tramado por encima de la decoración y por debajo de los paneles, para centrar la vista en el título.
- `TitleScreen`: título "ASTRO ARTILLERY" y debajo el subtítulo "TOWER DEFENSE" (24 px, `#40e0f0`), flotando sin panel; debajo, `ButtonsPanel`, un panel holograma cian (`OverlayFrame`) con "Jugar", "Archivo", "Stats", "Opciones" y "Salir" (204x36 todos, texto a 24). Márgenes del panel de 24 a los lados y 21 arriba y abajo, 18 de separación en `Content` y 9 entre botones.
- `LevelSelectionScreen` (oculto al empezar): `LevelsPanel`, un panel holograma cian con la cabecera `// SECTORES DISPONIBLES` (`ScreenHeader`), `SectorsRow` (`HBoxContainer`, 24 px de separación) con el radar `SectorRadar` (352x352) y a su derecha la ficha `SectorCard` (300 px de ancho fijo), y el botón "Volver" (204x36). Cabecera y botones a 24 px. Mismos márgenes y separación que `ButtonsPanel`. Ver "Radar de sectores".
- `StatsScreen` (oculto al empezar): panel holograma con la cabecera `// ESTADÍSTICAS`, `StatsLabel` (24 px) y "Volver". Al abrirse (`_on_stats_button_pressed`) rellena cinco líneas con los totales de `GameState`: naves destruidas (`stats.kills`), dinero gastado (`stats.spent`, con `UiFormat.money`), tiempo jugado (`play_time`, en h y min), torreta favorita (la de mayor `stats.built_<torreta>`, "-" si no hay) y niveles ganados (`stats.wins`).
- `Navedex` (oculto al empezar): instancia de `scenes/Navedex.tscn` (ver "Navedex").
- `OptionsMenu` (oculto al empezar): instancia de `scenes/OptionsMenu.tscn` (ver "Opciones").

Textos en Monogram (ver [art.md](art.md)): el título "ASTRO ARTILLERY" a 72 px, "OPCIONES" a 48 px (en `#40e0f0`) y el resto (botones, rótulos, interruptores) a 24 px (todo ×1,5 sobre el tamaño base de 16, 32 y 48).

## Comportamiento

- "Jugar" y "Volver" cambian entre el título y la selección de nivel con un fundido de 0,25 s de salida y otro de entrada.
- "Opciones" llama a `OptionsMenu.open_from(TitleScreen)`, que hace el mismo fundido; "Volver" regresa al título.
- "Salir" cierra el juego.
- Si `start_on_level_selection` es `true` (lo pone `Game` al volver de un nivel), el menú abre directamente en la selección de nivel.
- `_refresh_sectors()` (al abrir el menú, al pulsar "Jugar" y con `GameState.progress_reset`) vuelve a leer el progreso en el radar y la ficha.
- Clic en un contacto del radar = seleccionarlo (`sector_selected` → la ficha lo enseña). Para jugar: el botón DESPLEGAR / REPETIR de la ficha (`deploy_pressed`) o doble clic en el contacto (`sector_launched`); los dos llaman a `_open_level`.
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
| `Outpost` | `scripts/main_menu/Outpost.gd` (clase `Outpost`) | En (120, 286), a ×0,5 y con el tono de las naves de `Skirmish` (`modulate` opaco), como parte del fondo. La estación del jugador (`estacion.tres`, animación `fase_0`) con tres torretas alrededor (Cañón doble, Minigun y otro Cañón doble), con los sprites de base y cañón de sus `TurretData`. `fire_at(target)` gira hacia `target` el cañón más cercano, le pone su animación de disparo si la tiene (si tiene `spin`, los tubos arrancan a ×4 y frenan hasta pararse en 1 s) y devuelve la posición de la boca |
| `Skirmish` | `scripts/main_menu/Skirmish.gd` | Entre `Outpost` y el panel. Cada 6-12 s cruza un grupo de 2-4 naves enemigas en V (mismo sprite, ×0,5, oscurecidas con `SHIP_TINT` pero opacas, para que no transparenten lo que tengan detrás, 60 px/s, siempre en horizontal y giradas hacia donde avanzan igual que `Enemy._update_animation`) por las franjas de arriba o abajo, lejos de los botones. Cada 1,5-4 s un disparo (línea cian de 1 px) apuntando a una nave: si tiene `outpost`, sale de la boca de una torreta del puesto (`Outpost.fire_at`); si no, desde fuera de la pantalla por arriba o abajo; siempre hace un impacto (`minigun_impact`) y el 40 % de las veces la nave se destruye |

`scripts/main_menu/SpaceBody.gd` (clase `SpaceBody`) es un `AnimatedSprite2D` con `@tool` que construye su `SpriteFrames` a partir de `sheet`, una tira horizontal de frames cuadrados (lado = alto de la imagen), a la velocidad `fps`. Lo usan los planetas del menú y los asteroides.

## Radar de sectores

`SectorRadar` (`scripts/level_ui/SectorRadar.gd`) pinta todo en `_draw`, cada parte en su función (`_draw_background`, `_draw_grid`, `_draw_sweep`, `_draw_fog`, `_draw_ring_labels`, `_draw_route`, `_draw_station`, `_draw_contacts`), para que el modo corrupto del jefe pueda cambiar o añadir partes. Colores de la interfaz: disco en bandas de `#122440` (centro) a `#060b14`, anillos y radios `#1c4a60`, marcas del borde `#1c7496`, borde, estación y alcance `#40e0f0`, barrido `#befaff` con estela `#40e0f0`.

- Estación en el centro (cruz y cuadro con hueco). 4 anillos y radios cada 30°; marcas del borde cada 5° (más largas cada 30°).
- Barrido: gira a 1,6 rad/s con una estela de 36 cuñas. Al pasar por un contacto lo enciende (alfa 1) y se apaga en 2,6 s hasta 0,45 (0,75 el primer nivel pendiente).
- Un contacto por nivel de `GameData.levels`, en `LevelData.radar_distance` (fracción del radio) y `radar_bearing` (0° arriba, sentido horario). Cada uno más lejos que el anterior (0,20 a 0,66); ningún nivel usa la zona de arriba (reservada al jefe) ni la de la derecha justo encima del eje (textos de km).
- Estados (`get_level_state`): oculto si `GameState.is_unlocked(i)` es `false`; completado (verde `#3cb860`) si tiene estrellas o es anterior a `current_level`; si no, pendiente (amarillo `#ecb23c`). Con el ratón encima o seleccionado, azul `#54a0e2`. El seleccionado da un salto de 6 px, luego flota 2 px arriba y abajo y suelta una onda circular cada 1,4 s; del centro sale hasta él una ruta discontinua azul animada.
- Alcance: llega justo al último contacto visible (su distancia + 0,04, sin pasar de la mitad hasta el siguiente + 0,02; tope 0,9). Fuera, niebla oscura con 120 puntos de ruido nuevos en cada frame; el borde del alcance es un círculo discontinuo que gira. Como `is_unlocked()` ahora devuelve siempre `true`, el alcance cubre todos los niveles; con la progresión normal crece con `current_level`.
- Textos de km de los anillos (radio total `RADIUS_KM` = 4.000 km, separador de miles `NUMBER_THOUSANDS_SEP`) a 16 px, a la derecha justo encima del eje; más tenues fuera del alcance. Van sin "km" porque a este tamaño no caben.
- Iconos: las naves de `LevelData.radar_ship` (incursor, colmillo, triturador y espectro), 16x16 dibujadas a ×2 y teñidas con el color del estado; los ojos se pintan encima en `#f0323c` y parpadean (ciclo de 3,5 s, desfasado por contacto). Debajo, el rótulo `SEC-0N` a 16 px. Los sprites (`assets/sprites/enemies/radar/radar_<nave>.png` y `radar_<nave>_eyes.png`) no se dibujan a mano: los genera `scripts/tools/make_radar_ships.gd` (`godot --headless --path . -s scripts/tools/make_radar_ships.gd`) a partir de plantillas de texto (casco en grises con luz arriba, sombra abajo y contorno `#0a0810`; los ojos son un hueco oscuro en el casco y un PNG aparte en blanco). Si aún no existen, el contacto se pinta como un cuadro.

### Ficha

`SectorCard` (`scripts/level_ui/SectorCard.gd`, `MarginContainer` que crea sus filas en código): fondo `#0a0f1a` al 88 %, borde `#1c4a60` y esquinas en L de `#40e0f0` que salen 3 px. Todo a 24 px. Ancho fijo de 300 px; título, nombres de fila y botón se recortan en vez de ensanchar la ficha, para que no se mueva con textos más largos ni al cambiar de idioma.

- Título `SEC-0N · NOMBRE` en `#40e0f0` (nombre de `LevelData.sector_name`, clave `SECTOR_<n>_NAME`).
- Filas con línea de puntos debajo (nombre `#5a7a96`, valor `#cce6ff`): ESTADO (ASEGURADO en verde o SEÑAL ACTIVA en amarillo), RUMBO (`radar_bearing`, `000°`), DISTANCIA (`radar_distance` × 4.000 km, redondeada a decenas), OLEADAS (`waves.size()`), AMENAZA (`LevelData.threat`: BAJA verde, MEDIA amarilla, ALTA naranja `#ff8c32`, EXTREMA roja `#ff3c5a`, solo para el jefe) y MEJOR: las estrellas de `GameState.get_level_stars()` en pixel art (`VictoryScreen.STAR_SHAPE` a 2 px, llenas `#ecb23c`, vacías `#3c2a0c`), todas vacías si no está completado.
- Botón `» DESPLEGAR «` en amarillo, o `REPETIR` en verde si está completado. Emite `deploy_pressed`.
- Se repinta con `NOTIFICATION_TRANSLATION_CHANGED`.

## Salto al hiperespacio

`MainMenu._open_level` (una sola vez, ignora más pulsaciones; desde DESPLEGAR / REPETIR o doble clic en el radar) llama a `_hyperspace_jump()`: `StarField.warp(0.5)` y un `ColorRect` blanco que cubre el menú en 0,1 s; después carga el nivel. Solo desde el menú ("Siguiente nivel" no hace el salto).

## Navedex

`scenes/Navedex.tscn` + `scripts/screens/Navedex.gd` (clase `Navedex`). Archivo de naves y torretas, accesible con "Archivo" en el título (mismo fundido de 0,25 s que Jugar/Opciones; emite `back_pressed` con "Volver"). Panel holograma (`OverlayFrame`) con cabecera `// ARCHIVO`, una `TabBar` NAVES / TORRETAS, a la izquierda una cuadrícula de 4 columnas (celdas `EnemyCell` cuadradas de 64x64 y sin contador, que valen para cualquier `InspectableData`) y a la derecha el detalle: sprite (animado `up` en las naves, `icon` en las torretas) a ×2, nombre, `description` y stats (`get_stats()` con `StatRow` a 24 px). El panel tiene tamaño fijo: la cuadrícula mide 274x274, el detalle 420x340 (caben la nave con más texto y la torreta con más stats) y la lista de logros 718x340. El tamaño de las celdas lo fija `Navedex` al crearlas (`CELL_SIZE`, con `SIZE_SHRINK_BEGIN` en los dos ejes para que el contenedor no las estire), no `EnemyCell.tscn`, que en la partida sigue igual.

- Torretas: la cuadrícula solo tiene las base. En el detalle, `PrevButton` y `NextButton` (`<` y `>`) pegados a los lados de la imagen (cajas cuadradas de 28 px con el estilo de `EnemyCell`: borde cian fino, relleno tenue, recorte de 3 px; `Navedex._style_arrow`) pasan por la cadena base -> `TurretData.fusion` y vuelven; al cambiar se actualizan imagen, nombre, descripción y stats. Se desactivan en los extremos y en las naves son invisibles (no ocultos, para que la imagen no se mueva). "MEJORA: nombre" se ve en las versiones que aún tienen otra mejora.

- Un enemigo es "visto" si `GameState.has_seen_enemy(data)`. Los no vistos salen en silueta negra (`modulate` negro) y su detalle dice "???" sin stats.
- Al mostrarse se refrescan las siluetas y se elige el primer enemigo.
- Las torretas (`TURRET_FILES`, solo las base) siempre se ven completas.
- Si se añade un enemigo o torreta nuevos, hay que añadirlo a `ENEMY_FILES` / `TURRET_FILES`.

### Logros

Tercera pestaña de la Navedex, LOGROS: oculta cuadrícula y detalle y muestra `AchievementsList`, una cuadrícula de 2 columnas con una fila por logro (`Navedex._make_achievement_row`): icono a ×3 (`assets/ui/achievements/<id>.png`), nombre y descripción. Los que faltan por conseguir se ven apagados (`LOCKED_COLOR`). Los 12 logros están en `GameState.ACHIEVEMENTS` (id -> nombre y descripción) y cómo se cumple cada uno en `GameState._is_done()`. Se guardan en la ranura activa, `user://saves/slot_N.cfg` (`unlocked`, más los contadores `stats` y `fused_turrets`) y "Borrar progreso" los borra. `GameState.load_slot` migra los nombres antiguos de la ranura (`fused_towers`, contador `towers` y logro `towers_50`) a `fused_turrets`, `turrets` y `turrets_50`.

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

`scenes/OptionsMenu.tscn` + `scripts/screens/OptionsMenu.gd` (clase `OptionsMenu`). Un panel holograma cian (`OverlayFrame`) centrado, con los mismos márgenes que el menú principal (24 / 21), con el título "OPCIONES", dos columnas de secciones con cabeceras `// AUDIO`, `// PANTALLA` y `// JUEGO`, y debajo el botón "Volver" (ver más abajo). Etiquetas, cabeceras y botones a 24 px. Columnas separadas 36 px. La misma escena está instanciada en el menú principal y en el menú de pausa (ver [ui.md](ui.md)).

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
| JUEGO | Botón "Idioma" (`LanguageButton`) | `language` |
| JUEGO | Botón "Rango de torretas" | `show_turret_range` |
| JUEGO | Botón "Pausar sin foco" | `pause_on_focus_loss` |

"Volver" (204x36) va en `ButtonsBlock`, debajo de las columnas con 9 px extra de margen (`ButtonsMargin`), así que se separa más de las secciones que los botones entre sí. Las partidas no se borran aquí: se borran desde su ranura en la pantalla de inicio (ver "Pantalla de inicio").

Los deslizadores (96x12, tirador de 5x11) van de 0 a 1 en pasos de 0,05 (colores de la paleta en `menu_theme.tres`, ver [art.md](art.md)). Los botones son interruptores de 54x24 (texto a 24) con la variación de tema `ToggleButton`: en ON van rellenos de cian (como el ratón encima) y muestran "ON"; en OFF van con el estilo normal y muestran "OFF". Al abrirse, cada control toma su valor de `Settings`; cada cambio llama a `Settings.set_value`.

El botón de idioma es del mismo tamaño y estilo pero no es interruptor: cada pulsación pasa al siguiente idioma de `Settings.LANGUAGES` y muestra su código ("ES" / "EN", sin traducir). El cambio se ve al momento en todo lo que está abierto (ver "Idiomas").

### Settings

`scripts/autoloads/Settings.gd`, autoload. Guarda las opciones en `user://settings.cfg` (sección `settings`) con `ConfigFile`.

- Al arrancar carga el archivo y aplica todas las opciones. Si el archivo no existe, falta una clave o su valor no es del tipo esperado, vale el valor por defecto: volúmenes a 1, `vsync` y `pause_on_focus_loss` activados y el resto desactivado. Las claves que no conoce (por ejemplo la antigua `ambient_volume`) se ignoran y desaparecen del archivo en el siguiente guardado. La excepción es `LEGACY_KEYS`: `show_turret_range` también se lee de su nombre antiguo (`show_tower_range`) si el archivo aún no tiene la nueva.
- `get_value(key)` y `set_value(key, value)`. `set_value` aplica el cambio, guarda el archivo y emite `changed(key)`.
- Los tres volúmenes son lineales y se aplican a los buses `Master`, `Music` y `SFX`, definidos en `default_bus_layout.tres`. El bus `SFX` es para los sonidos de torretas, explosiones y demás efectos.
- `muted` silencia el bus `Master` sin cambiar los volúmenes, así que al quitarlo los deslizadores conservan su valor.
- `fullscreen` y `vsync` se aplican con `DisplayServer`.
- `language` (texto, `"es"` por defecto) se aplica con `TranslationServer.set_locale`; si el archivo trae un código que no está en `LANGUAGES` (`["es", "en"]`), se usa el español.
- `show_fps` y `show_turret_range` no hacen nada aquí: las leen `LevelUI` (ver [ui.md](ui.md)) y `Turret` (ver [torretas.md](torretas.md)), que escuchan `changed` para actualizarse al momento.
- `pause_on_focus_loss` tampoco hace nada aquí: la lee `Game` cuando la ventana pierde el foco (ver [flujo.md](flujo.md)).

## Idiomas

Los textos visibles están en `translations/textos.csv` (columnas `keys,es,en`), registrado en `project.godot` (`internationalization/locale/translations`, con los `.translation` que genera Godot al importar el CSV; idioma de reserva `es`). Ni escenas ni scripts llevan textos a mano: usan claves en mayúsculas con prefijo por zona (`BTN_`, `HEADER_`, `OPT_`, `HUD_`, `STAT_`, `TAG_`, `TUTORIAL_`, `ACH_`, `TURRET_`, `ENEMY_`...).

- En los `.tscn` el `text` de `Label` y `Button` es la clave y Godot lo traduce solo (también al cambiar de idioma). Las cabeceras `ScreenHeader` guardan la clave en `title` y la traducen con `tr()`; se repintan con `NOTIFICATION_TRANSLATION_CHANGED`.
- Los textos con números o nombres se montan con `tr("CLAVE") % valores` (por ejemplo `HUD_WAVE_N` = "OLEADA %d"). `Sidebar` y `LevelIndicator` guardan lo último que enseñaron y lo repintan al cambiar de idioma, para que la pausa → Opciones → idioma se vea al volver a la partida.
- `TurretData` y `EnemyData` guardan en `name` y `description` claves (`TURRET_<archivo>_NAME` / `_DESC`, `ENEMY_<archivo>_NAME` / `_DESC`; los tres fragmentos de la Divisora comparten `ENEMY_FRAGMENTO_DIVISORA_*`). Para enseñarlos se usa `get_inspect_name()` / `get_inspect_description()`, que ya traducen; `RunStats.top_turret_name` guarda la clave y la traduce `RunSummary`.
- `StatEntry` recibe el nombre del stat como clave (`STAT_...`) y lo traduce al crearse; las etiquetas de tipo (`TAG_...`) las traduce `get_inspect_tag()`. Ambos caben en 9 caracteres también en inglés.
- Los logros de `GameState.ACHIEVEMENTS` son pares de claves (`ACH_<id>_NAME`, `ACH_<id>_DESC`).
- Se quedan sin traducir el título "ASTRO ARTILLERY" / "TOWER DEFENSE", "NOVA", "VSync", "AUTO", "ON" / "OFF", los "×1" / "×2" y los números.

Para añadir un idioma: una columna nueva en el CSV, su `.translation` en `project.godot` y su código en `Settings.LANGUAGES`.

## Dudas

- El fundido está escrito dos veces: en `MainMenu._transition` (título y selección de nivel) y en `OptionsMenu._fade`.
- Pantalla completa y VSync no tienen efecto si el juego se ejecuta incrustado en el editor de Godot; hay que ejecutarlo en su propia ventana.
