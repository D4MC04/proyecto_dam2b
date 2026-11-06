# Menú principal, opciones y música

## Pantalla de inicio

`scenes/StartScreen.tscn` + `scripts/screens/StartScreen.gd`. Es la escena inicial del proyecto (`run/main_scene`). De fondo, el mismo espacio que el menú: los nodos `Background`, `MenuBackground`, `StarField`, `RingedPlanet`, `Comets`, `Asteroids`, `Satellites`, `Outpost`, `Skirmish` y `Vignette`, con las mismas escenas y scripts (ver "Fondo" y "Decoración"), pero con `RingedPlanet` en (820, 446), `Outpost` en (120, 286) y las franjas por defecto de `Skirmish`: en el menú están movidos para verse por el ventanal. Encima va la interfaz, en fases (`Phase { TITLE, SLOTS, CONFIRM, ENTERING }`):

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

`scenes/MainMenu.tscn` + `scripts/screens/MainMenu.gd`. Se llega desde la pantalla de inicio, al elegir ranura, o al salir de un nivel (ver [flujo.md](flujo.md)). Es la **oficina del comandante**: el jugador está sentado ante la consola del centro de operaciones, mirando al ventanal por el que se ve el espacio, y gira la silla para ver las paredes de los lados. Cada botón del menú es un objeto de la oficina.

Nodos, de fondo a frente:

- `Background`: `ColorRect` negro.
- `Space` (`Node2D`): lo que se ve por el ventanal. Se desplaza con la vista central al girar (ver "Giro de la silla"), así que al girarse el espacio se va con el ventanal.
  - `MenuBackground`: el fondo propio del menú (ver "Fondo").
  - `StarField`: estrellas que parpadean (ver "Decoración").
  - `RingedPlanet`: el gigante gaseoso con anillos (ver "Fondo"). Va detrás de `StarField` para que ninguna estrella se pinte encima.
  - `Comets`, `Asteroids`, `Satellites`, `Planets`, `Outpost`, `Skirmish`: decoración (ver "Decoración").
  - `Vignette`: `Sprite2D` con `menu_vignette.png`, que oscurece los bordes en tramado.
- `Office` (ver "Oficina"): `Views`, con las tres vistas una al lado de otra (`LeftView` en x = -960, `CenterView` en 0 y `RightView` en 960), y las flechas de giro `TurnLeftArrow` y `TurnRightArrow`.
- `PanelDim` (oculto al empezar): `ColorRect` negro al 60 % que oscurece la oficina y para el ratón mientras hay un panel abierto.
- `LevelSelectionScreen` (oculto al empezar): `LevelsPanel`, un panel holograma cian con la cabecera `// SECTORES DISPONIBLES` (`ScreenHeader`), `LevelButtonsContainer` (`GridContainer` de 5 columnas, 12 px de separación) y el botón "Volver" (204x36). Cabecera y botones a 24 px. Márgenes del panel de 24 a los lados y 21 arriba y abajo, 18 de separación en `Content`.
- `StatsScreen` (oculto al empezar): panel holograma con la cabecera `// ESTADÍSTICAS`, `StatsLabel` (24 px) y "Volver". Al abrirse (`_on_combat_scoreboard_pressed`) rellena cinco líneas con los totales de `GameState`: naves destruidas (`stats.kills`), dinero gastado (`stats.spent`, con `UiFormat.money`), tiempo jugado (`play_time`, en h y min), torreta favorita (la de mayor `stats.built_<torreta>`, "-" si no hay) y niveles ganados (`stats.wins`).
- `Navedex` (oculto al empezar): instancia de `scenes/Navedex.tscn` (ver "Navedex").
- `AchievementsScreen` (oculto al empezar): instancia de `scenes/AchievementsScreen.tscn` (ver "Logros").
- `OptionsMenu` (oculto al empezar): instancia de `scenes/OptionsMenu.tscn` (ver "Opciones").
- `QuitConfirm` (oculto al empezar): oscurece todo (negro al 70 %) y muestra un panel holograma rojo (`#ff3c5a`, corchetes `#ffaabe`) con "¿SALIR DEL JUEGO?" (48 px, `#ffaabe`) y los botones "Salir" (`DangerButton`, con el estado pulsado con el ratón encima puesto al de hover, como en la pantalla de inicio) y "Cancelar", de 132x36 y separados 12 px.

Textos de los paneles en Monogram (ver [art.md](art.md)) a 24 px; "OPCIONES" a 48 px (en `#40e0f0`).

## Oficina

Tres vistas de 960x540: izquierda (puerta y stats), centro (ventanal y centro de operaciones) y derecha (vitrina de condecoraciones). Las vistas laterales no tienen rincones: pared, techo y suelo llegan hasta los dos bordes, para que la oficina parezca grande. Estilo en [art.md](art.md) ("Oficina del menú").

**Dibujos.** Todo lo fijo son PNG de `assets/sprites/office/` dibujados píxel a píxel por `scripts/tools/office/make_office.py` (`python scripts/tools/office/make_office.py` desde la raíz; necesita numpy y Pillow): `pixkit.py` tiene la paleta, los perfiles de bisel, remaches, pomos y la habitación de los lados; `gen_center.py`, `gen_left.py` y `gen_right.py`, cada vista. El mismo comando escribe `scripts/main_menu/OfficeLayout.gd` (clase `OfficeLayout`, constantes `LEFT`, `CENTER` y `RIGHT`): trapecios de las pantallas, pilotos, puerta, medallas... para que los scripts animen encima en el sitio justo. Para cambiar la oficina se tocan los generadores y se vuelve a lanzar; ni los PNG ni `OfficeLayout.gd` se editan a mano. En código solo se pintan las pantallas animadas y las luces.

**Nodos.** Cada vista (`LeftView`, `CenterView`, `RightView`) tiene `Room`, un `TextureRect` con su PNG (`left_static`, `center_static`, `right_static`), y encima sus objetos. `Lights` (`scripts/main_menu/OfficeLights.gd`, clase `OfficeLights`, `view`) enciende los pilotos de la vista (los huecos están en el PNG; un 35 % parpadea, con semilla fija) y, en el centro, un destello que recorre la línea de luz entre el ventanal y la consola. Los pinceles comunes están en `scripts/main_menu/OfficePaint.gd` (clase `OfficePaint`): `rect`, `bevel_box`, `line`, `disc`, `ring`, `text`, `brackets`, y `quad_rect` / `quad_span` / `quad_source_size` para pintar una pantalla de frente y llevarla fila a fila a su trapecio.

- **Centro.** El ventanal (tres hojas con las esquinas de arriba recortadas; el cristal se deja transparente salvo reflejos tenues, así que se ve `Space` detrás) se apoya directamente en la consola del centro de operaciones: rectangular, de lado a lado e **inclinada**, sube desde el jugador hasta el ventanal, como el panel de una cabina. Entre los dos, una línea de luz azul de lado a lado; junto al cristal, una franja con pilotos. Todas las piezas se apoyan en el mismo plano inclinado (la x se abre hacia el jugador alrededor de x = 480, `ALPHA` en `gen_center.py`): se ve su canto de delante abajo y su sombra cae hacia el jugador. Abajo, el borde delantero redondeado con una tira de luz.
- **Izquierda.** La puerta empotrada a ras de la pared (el zócalo se corta contra su marco y en el hueco hay un umbral), una barra de estado encima, el panel de acceso (pantallita y teclado de 3x4) y el monitor de stats, grande y centrado en vertical, con margen hasta el zócalo.
- **Derecha.** La vitrina, de pie sobre su peana y separada de la pared (se ve la tapa de la peana a los lados y delante), con el interior en perspectiva (techo con una tira de luz cálida, laterales y fondo de terciopelo acolchado), labio y escuadras doradas y la insignia de estrella con alas en la peana. Dos apliques de luz cálida a los lados. Sin sombras en la pared ni en el suelo.

**Objetos.** Cada uno es un `OfficeObject` (`scripts/main_menu/OfficeObject.gd`, `Control`) que pinta lo animado en `_draw_object()` y se redibuja cada frame (`time`). Al pasar el ratón (`hovered`, que se mira cada frame con `gui_get_hovered_control()`, así que se apaga también cuando un panel lo tapa) se marca con corchetes en L `#befaff` (`hover_rect()`; `show_brackets` los quita), sin rótulo de texto; el cursor es la mano. Un clic izquierdo emite `pressed`. Sus hijos no reciben el ratón.

| Vista | Nodo | Script | Abre | Qué se anima |
|---|---|---|---|---|
| Centro | `RadarConsole` | `RadarConsole.gd` | `LevelSelectionScreen` | Mesa holográfica rectangular apoyada en la consola, así que se ve en trapecio. La pantalla es el shader `resources/shaders/office_radar.gdshader` en `Screen` (`ColorRect`): cuadrícula, tres anillos y cruz chafados por la inclinación, y un barrido `#befaff` con estela tramada (más deprisa con el ratón encima). Encima, en `Blips`, 6 ecos rojos que destellan con una columna de luz al pasar el barrido. Se pulsa en el contorno de la mesa (`_has_point`) |
| Centro | `ArchiveTablet` | `ArchiveTablet.gd` | `Navedex` | Tablet robusta (`tablet.png`: marco grueso, escuadras atornilladas, canto abajo) en una bandeja hundida. En la pantalla, pestañas, el holograma cian de una nave (su frame `up` pasado a la rampa cian por brillo), líneas de datos y 4 fichas. Con el ratón encima la tablet sube 8 px con su sombra, se enciende la luz del fondo de la bandeja, la nave gira y baja una línea de escaneo |
| Centro | `OptionsConsole` | `OptionsConsole.gd` | `OptionsMenu` | Módulo de metal: la pantalla solo enseña el volumen (tres vúmetros con su fader, centrados; más deprisa con el ratón encima). Abajo, tres pomos brillantes y cuatro interruptores (el tercero bajado), centrados |
| Izquierda | `ExitDoor` | `OfficeDoor.gd` | Sale del juego | Dos hojas lisas de metal oscuro con la junta en zigzag y franjas de luz. Con el ratón encima solo se entreabren (`slide`, 26 px cada una, en 0,35 s): por la rendija se ve la luz del pasillo (`corridor.png`, sin detalle) y una luz tenue cae en el suelo, tan ancha como la rendija; se encienden la luz del marco (`door_glow.png`) y la pantallita del panel de acceso (`access_lit.png`). Cerrada, la junta brilla (`door_seam.png`) y un pulso sube y baja por las franjas. La barra de estado de encima la recorre un tramo de luz (verde con la puerta activa). `Plane` (`door_plane.png`, `clip_children`) recorta las hojas y el pasillo con la forma del hueco. Sin corchetes. Al pulsarla (`open_fully`) se entreabre y emite `opened` |
| Izquierda | `CombatScoreboard` | `CombatScoreboard.gd` | `StatsScreen` | Pantalla sin datos: "// REGISTRO DE COMBATE", 8 barras que suben y bajan, una línea de 2 px que avanza, un anillo de cuatro colores que gira con su leyenda y 5 fichas con el icono (a escala 1) de lo que se cuenta: naves destruidas, victorias, torretas, oleadas perfectas y naves vistas. Abajo, "SISTEMA EN ESPERA" con un cursor |
| Derecha | `MedalCase` | `MedalCase.gd` | `AchievementsScreen` | Una medalla por logro de `GameState.ACHIEVEMENTS` (`medal_<id>.png`, o `medal_empty.png` si falta), en filas de 5, 4 y 3 centradas y escalonadas medio paso, sin solaparse; los reflejos del cristal (`case_glass.png`) encima y un destello de vez en cuando en las conseguidas. Con el ratón encima de una medalla, los corchetes la marcan a ella |

## Comportamiento

- **Giro de la silla:** se empieza en la vista central. `TurnArrow` (`scripts/main_menu/TurnArrow.gd`) es una placa de 22x44 a 16 px del borde con un doble chevrón cian que se ilumina y se adelanta al pasar el ratón. Pulsarla, o las teclas ← → o A D, llama a `_turn(-1 / 1)`: un tween de 0,45 s (seno, entrada y salida) desplaza `Views` y `Space` 960 px, redondeando a píxeles enteros. En una vista lateral solo se ve la flecha que vuelve al centro.
- Cada objeto abre su panel con `_open_panel(panel)`: `PanelDim` y el panel aparecen con un fundido de 0,25 s, con la oficina quieta detrás. "Volver" de cualquier panel (o `back_pressed` de `Navedex`, `AchievementsScreen` y `OptionsMenu`) llama a `_close_panel()`, el fundido inverso. Con un panel abierto no se gira.
- **Escape** (`ui_cancel`): con "¿Salir del juego?" abierto lo cierra; con un panel abierto, lo cierra; en la oficina abre "¿Salir del juego?". "Salir" cierra el juego y "Cancelar" lo cierra.
- La puerta se entreabre y después se cierra el juego.
- Si `start_on_level_selection` es `true` (lo pone `Game` al volver de un nivel), el menú abre con la selección de nivel ya abierta sobre la vista central.
- `_build_level_buttons()` crea un `LevelButton` de 60x60 (número a 24) por cada entrada de `GameData.levels`, numerado desde 1 y desactivado si `GameState.is_unlocked(i)` es `false`.
- `LevelButton` (`scripts/level_ui/LevelButton.gd`) emite `level_selected(data)` al pulsarse.
- `_open_level(data)` instancia `scenes/Game.tscn`, le asigna `level_data` y la pone como escena actual.

## Fondo

`scenes/MenuBackground.tscn` y el nodo `RingedPlanet`. Siguen el estilo del fondo de los niveles (`SpaceBackground`, ver [niveles.md](niveles.md)): tonos planos muy oscuros, transiciones en tramado de píxeles y cuerpos con bandas onduladas. Pero no es el mismo, para que el menú tenga identidad propia: otra paleta (verde azulado en vez de morado) y otra composición.

- `Nebula`: `Parallax2D` a -2 px/s, repetida en horizontal cada 960 px, con `menu_nebula.png`: nubes verde azuladas y una banda de estrellas ondulada que cruza la pantalla, con una franja de polvo oscuro rota por dentro. Las estrellas van pintadas en la imagen, más juntas en la banda.
- `RingedPlanet` (nodo de `MainMenu`, no de esta escena, para quedar delante de `StarField`): gigante gaseoso ámbar con dos anillos (`menu_planet.png`), en (820, 138), en la hoja derecha del ventanal, iluminado desde arriba a la izquierda y con la sombra de los anillos sobre el planeta.
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
| `Outpost` | `scripts/main_menu/Outpost.gd` (clase `Outpost`) | En (110, 172), en la hoja izquierda del ventanal, a ×0,5 y con el tono de las naves de `Skirmish` (`modulate` opaco), como parte del fondo. La estación del jugador (`estacion.tres`, animación `fase_0`) con tres torretas alrededor (Cañón doble, Minigun y otro Cañón doble), con los sprites de base y cañón de sus `TurretData`. `fire_at(target)` gira hacia `target` el cañón más cercano, le pone su animación de disparo si la tiene (si tiene `spin`, los tubos arrancan a ×4 y frenan hasta pararse en 1 s) y devuelve la posición de la boca |
| `Skirmish` | `scripts/main_menu/Skirmish.gd` | Cada 6-12 s cruza un grupo de 2-4 naves enemigas en V (mismo sprite, ×0,5, oscurecidas con `SHIP_TINT` pero opacas, para que no transparenten lo que tengan detrás, 60 px/s, siempre en horizontal y giradas hacia donde avanzan igual que `Enemy._update_animation`) por una de sus franjas (`lanes`, en fracción del alto): por defecto las de arriba y abajo (0,05-0,2 y 0,8-0,95), lejos de los botones; en el menú, 0,06-0,2 y 0,28-0,42, dentro del ventanal (que acaba en y = 262). Cada 1,5-4 s un disparo (línea cian de 1 px) apuntando a una nave: si tiene `outpost`, sale de la boca de una torreta del puesto (`Outpost.fire_at`); si no, desde fuera de la pantalla por arriba o abajo; siempre hace un impacto (`minigun_impact`) y el 40 % de las veces la nave se destruye |

`scripts/main_menu/SpaceBody.gd` (clase `SpaceBody`) es un `AnimatedSprite2D` con `@tool` que construye su `SpriteFrames` a partir de `sheet`, una tira horizontal de frames cuadrados (lado = alto de la imagen), a la velocidad `fps`. Lo usan los planetas del menú y los asteroides.

## Salto al hiperespacio

`MainMenu._open_level` (una sola vez, ignora más pulsaciones) llama a `_hyperspace_jump()`: `Space/StarField.warp(0.5)` (las estrellas se estiran por el ventanal) y un `ColorRect` blanco que cubre el menú en 0,1 s; después carga el nivel. Solo desde el menú ("Siguiente nivel" no hace el salto).

## Navedex

`scenes/Navedex.tscn` + `scripts/screens/Navedex.gd` (clase `Navedex`). Archivo de naves y torretas, que abre la tablet de la oficina (emite `back_pressed` con "Volver"). Panel holograma (`OverlayFrame`) con cabecera `// ARCHIVO`, una `TabBar` NAVES / TORRETAS, a la izquierda una cuadrícula de 4 columnas (celdas `EnemyCell` cuadradas de 64x64 y sin contador, que valen para cualquier `InspectableData`) y a la derecha el detalle: sprite (animado `up` en las naves, `icon` en las torretas) a ×2, nombre, `description` y stats (`get_stats()` con `StatRow` a 24 px). El panel tiene tamaño fijo: la cuadrícula mide 274x274, y el detalle 420x340 (caben la nave con más texto y la torreta con más stats). El tamaño de las celdas lo fija `Navedex` al crearlas (`CELL_SIZE`, con `SIZE_SHRINK_BEGIN` en los dos ejes para que el contenedor no las estire), no `EnemyCell.tscn`, que en la partida sigue igual.

- Torretas: la cuadrícula solo tiene las base. En el detalle, `PrevButton` y `NextButton` (`<` y `>`) pegados a los lados de la imagen (cajas cuadradas de 28 px con el estilo de `EnemyCell`: borde cian fino, relleno tenue, recorte de 3 px; `Navedex._style_arrow`) pasan por la cadena base -> `TurretData.fusion` y vuelven; al cambiar se actualizan imagen, nombre, descripción y stats. Se desactivan en los extremos y en las naves son invisibles (no ocultos, para que la imagen no se mueva). "MEJORA: nombre" se ve en las versiones que aún tienen otra mejora.

- Un enemigo es "visto" si `GameState.has_seen_enemy(data)`. Los no vistos salen en silueta negra (`modulate` negro) y su detalle dice "???" sin stats.
- Al mostrarse se refrescan las siluetas y se elige el primer enemigo.
- Las torretas (`TURRET_FILES`, solo las base) siempre se ven completas.
- Si se añade un enemigo o torreta nuevos, hay que añadirlo a `ENEMY_FILES` / `TURRET_FILES`.

### Logros

`scenes/AchievementsScreen.tscn` + `scripts/screens/AchievementsScreen.gd` (clase `AchievementsScreen`), que abre la vitrina de condecoraciones de la oficina (la Navedex ya no tiene pestaña de logros). Panel holograma cian con la cabecera `// LOGROS`, `AchievementsList` (cuadrícula de 2 columnas de 718x340) con una fila por logro (`_make_row`): icono a ×3 (`assets/ui/achievements/<id>.png`), nombre y descripción; y "Volver", que emite `back_pressed`. La lista se rehace cada vez que se muestra. Los que faltan por conseguir se ven apagados (`LOCKED_COLOR`). Los 12 logros están en `GameState.ACHIEVEMENTS` (id -> nombre y descripción) y cómo se cumple cada uno en `GameState._is_done()`. Se guardan en la ranura activa, `user://saves/slot_N.cfg` (`unlocked`, más los contadores `stats` y `fused_turrets`) y se borran al borrar la ranura. `GameState.load_slot` migra los nombres antiguos de la ranura (`fused_towers`, contador `towers` y logro `towers_50`) a `fused_turrets`, `turrets` y `turrets_50`.

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

- `open_from(opener)`: funde de `opener` (el panel que la abre, en la pausa) a las opciones, 0,25 s de salida y 0,25 s de entrada, y recuerda `opener`.
- "Volver" hace el fundido inverso hacia ese mismo panel. Sin `opener` (en el menú la abre el cuadro de mantenimiento con el fundido de la oficina), "Volver" emite `back_pressed`.
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

"Volver" (204x36) va en `ButtonsBlock`, debajo de las columnas con 9 px extra de margen (`ButtonsMargin`), así que se separa más de las secciones que los botones entre sí. Las partidas no se borran aquí: se borran desde su ranura en la pantalla de inicio (ver "Pantalla de inicio").

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

- El fundido está escrito dos veces: en `MainMenu._fade_panel` (paneles de la oficina) y en `OptionsMenu._fade`.
- Pantalla completa y VSync no tienen efecto si el juego se ejecuta incrustado en el editor de Godot; hay que ejecutarlo en su propia ventana.
