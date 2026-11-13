# Menú principal, opciones y música

## Pantalla de inicio

`scenes/StartScreen.tscn` + `scripts/screens/StartScreen.gd`. Es la escena inicial del proyecto (`run/main_scene`). De fondo, el mismo espacio que el menú: los nodos `Background`, `MenuBackground`, `StarField`, `RingedPlanet`, `Comets`, `Asteroids`, `Satellites`, `Outpost`, `Skirmish` y `Vignette`, con las mismas escenas y scripts (ver "Fondo" y "Decoración"), pero con `RingedPlanet` en (820, 446), `Outpost` en (120, 286) y las franjas por defecto de `Skirmish`: en el menú están movidos para verse por el ventanal. Encima va la interfaz, en fases (`Phase { TITLE, SLOTS, CONFIRM, ENTERING }`):

- **Título:** `TitleBlock`, "ASTRO ARTILLERY" (72 px) y "TOWER DEFENSE" (24 px, `#40e0f0`) como en el menú, entra con un fundido de 0,6 s con su fila de arriba en y = 168. Debajo, en y = 352, `PressKeyLabel` "PULSA CUALQUIER TECLA" (24 px, `#befaff`) parpadea a golpes: 0,6 s encendido de cada segundo. Cualquier tecla, clic (izquierdo, derecho o central) o botón de mando lo hace parpadear rápido 6 veces (cada 0,05 s) y desaparecer, y a la vez el título se desvanece subiendo 16 px (0,35 s).
- **Salir del juego:** Escape en el título cierra el juego directamente (`get_tree().quit()`), sin confirmación.
- **Ranuras:** `SlotsPanel`, un panel holograma cian (`OverlayFrame`, márgenes 24 / 21, 18 px de separación) centrado, con la fila de arriba en y = 104 (centrado en vertical, ya sin título), con la cabecera `// SELECCIONA PARTIDA` (24 px) y `SlotList`, las 3 ranuras en vertical separadas 12 px. Al entrar, el panel funde en 0,2 s y las tarjetas llegan escalonadas (0,09 s entre una y otra): se deslizan 16 px desde la derecha mientras se descubren de arriba abajo con una línea de escaneo `#befaff` (0,24 s), y después aparecen sus textos y su botón de borrar (0,15 s). Escape (sin ningún aviso en pantalla) funde las ranuras y el título vuelve bajando a su sitio mientras aparece, con el texto parpadeando otra vez.
- **Confirmar borrado:** el botón de borrar de una ranura abre `ConfirmLayer`: oscurece todo (negro al 70 %) y muestra un panel holograma rojo (`#ff3c5a`, corchetes `#ffaabe`) con "¿SEGURO?" (48 px, `#ffaabe`), "Se borrará la partida de la ranura N. No se puede deshacer." (24 px) y los botones "Borrar" (`DangerButton`) y "Cancelar", de 132x36 y separados 12 px. Aparece y se va con un fundido de 0,2 s. "Cancelar", Escape o un clic fuera del panel lo cierran sin hacer nada. "Borrar" llama a `GameState.delete_slot(n)`, cierra la caja y la tarjeta vuelve a entrar, ya como "NUEVA PARTIDA".
- **Entrar:** pulsar una tarjeta llama a `GameState.load_slot(n)`; si la ranura estaba vacía, además a `GameState.flush()`, para que quede ocupada desde ese momento. Después, el efecto de entrada: la cabecera, las otras tarjetas y los botones de borrar se funden en 0,2 s mientras la tarjeta elegida destella 3 veces en `#befaff` (0,07 s por subida y por bajada) y se queda encendida; un `ScreenWipe` tapa la pantalla desde el centro de la pantalla (0,7 s), se espera 0,15 s en oscuro, se cambia a `MainMenu` (a mano, como en "Cambio de escena" de [flujo.md](flujo.md)) y el mismo `ScreenWipe` la destapa desde el centro de la pantalla (0,6 s). No se parece al salto al hiperespacio, que es el de entrar a un nivel.

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
- `LevelSelectionScreen` (oculto al empezar; la abre la mesa de Sectores): `LevelsPanel`, sin panel ni marco (como el boceto, flota sobre el fondo; márgenes 24 / 6, 10 px de separación), con la cabecera `// SECTORES` (`ScreenHeader`), debajo `SectorsSubtitle` "Asegurados N/10 - Alcance del radar: X km" (16 px, `RADAR_SUBTITLE`), `SectorsRow` (`HBoxContainer`, 24 px de separación) con el radar `SectorRadar` (384x384) y a su derecha la ficha `SectorCard` (300 px de ancho fijo), y el botón "Volver" (204x36). Cabecera y botones a 24 px. Ver "Radar de sectores".
- `StatsScreen` (oculto al empezar): panel holograma con la cabecera `// ESTADÍSTICAS` (`HEADER_STATS`), `StatsLabel` (24 px) y "Volver". Al abrirse (`_on_combat_scoreboard_pressed`) rellena cinco líneas con los totales de `GameState`: naves destruidas (`stats.kills`), dinero gastado (`stats.spent`, con `UiFormat.money`), tiempo jugado (`play_time`, en h y min), torreta favorita (la de mayor `stats.built_<torreta>`, "-" si no hay) y niveles ganados (`stats.wins`). Las cinco líneas son textos traducidos (`STATS_KILLS`, `STATS_SPENT`, `STATS_TIME`, `STATS_FAVORITE`, `STATS_WINS`).
- `Navedex` (oculto al empezar): instancia de `scenes/Navedex.tscn` (ver "Navedex").
- `OptionsCloseUp` (oculto al empezar): la consola de opciones de cerca (`scripts/main_menu/OptionsCloseUp.gd`, ver "Consola de opciones"). El cuadro `OptionsMenu` ya no está en el menú principal: solo en la pausa.
- `QuitConfirm` (oculto al empezar): oscurece todo (negro al 70 %) y muestra un panel holograma rojo (`#ff3c5a`, corchetes `#ffaabe`) con "¿VOLVER AL INICIO?" (48 px, `#ffaabe`) y los botones "Salir" (`DangerButton`, con el estado pulsado con el ratón encima puesto al de hover, como en la pantalla de inicio) y "Cancelar", de 132x36 y separados 12 px.

Textos de los paneles en Monogram (ver [art.md](art.md)) a 24 px; "OPCIONES" a 48 px (en `#40e0f0`).

## Oficina

Tres vistas de 960x540: izquierda (puerta y stats), centro (ventanal y centro de operaciones) y derecha (vitrina de condecoraciones). Las vistas laterales no tienen rincones: pared, techo y suelo llegan hasta los dos bordes, para que la oficina parezca grande. Estilo en [art.md](art.md) ("Oficina del menú").

**Dibujos.** Todo lo fijo son PNG de `assets/sprites/office/` dibujados píxel a píxel por `scripts/tools/office/make_office.py` (`python scripts/tools/office/make_office.py` desde la raíz; necesita numpy y Pillow): `pixkit.py` tiene la paleta, los perfiles de bisel, remaches, pomos y la habitación de los lados; `gen_center.py`, `gen_left.py` y `gen_right.py`, cada vista. El mismo comando escribe `scripts/main_menu/OfficeLayout.gd` (clase `OfficeLayout`, constantes `LEFT`, `CENTER` y `RIGHT`): trapecios de las pantallas, pilotos, puerta, medallas... para que los scripts animen encima en el sitio justo. Para cambiar la oficina se tocan los generadores y se vuelve a lanzar; ni los PNG ni `OfficeLayout.gd` se editan a mano. El comando reescribe todos los PNG: con otra versión de Pillow los que no cambian salen con otros bytes pero los mismos píxeles, y esos se pueden dejar como estaban (`git restore`). En código solo se pintan las pantallas animadas y las luces.

**Nodos.** Cada vista (`LeftView`, `CenterView`, `RightView`) tiene `Room`, un `TextureRect` con su PNG (`left_static`, `center_static`, `right_static`), y encima sus objetos. `Lights` (`scripts/main_menu/OfficeLights.gd`, clase `OfficeLights`, `view`) enciende los pilotos de la vista (los huecos están en el PNG; un 35 % parpadea, con semilla fija) y, en el centro, un destello con estela que recorre el tubo de la barra de luz entre el ventanal y la consola, pasando por debajo de las abrazaderas (`CENTER.strip`: fila, alto y tramos de las abrazaderas). Los pinceles comunes están en `scripts/main_menu/OfficePaint.gd` (clase `OfficePaint`): `rect`, `bevel_box`, `line`, `disc`, `ring`, `text`, `brackets`, `quad_brackets` (corchetes inclinados), y `quad_rect` / `quad_bevel_box` / `quad_span` / `quad_source_size` para pintar una pantalla de frente y llevarla fila a fila a su trapecio.

- **Centro.** El ventanal (tres hojas con las esquinas de arriba recortadas; el cristal se deja transparente salvo reflejos tenues, así que se ve `Space` detrás) se apoya directamente en la consola del centro de operaciones: rectangular, de lado a lado e **inclinada**, sube desde el jugador hasta el ventanal, como el panel de una cabina. Entre los dos, una barra de luz de lado a lado: carcasa de metal, tubo cian de 5 filas con el núcleo casi blanco, anillas de metal que lo parten en tramos y dos abrazaderas atornilladas bajo los montantes del ventanal, tan anchas como su metal y centradas con él, con el remache en el centro; debajo, una franja fina (14 px) con pilotos. Todas las piezas se apoyan en el mismo plano inclinado (la x se abre hacia el jugador alrededor de x = 480, `ALPHA` en `gen_center.py`): se ve su canto de delante abajo y su sombra cae hacia el jugador. Los mandos pequeños (pomos e interruptores) también se inclinan: cada fila se desplaza con la línea del plano que pasa por su centro (`lean_knob`, `lean_quad`). Abajo, el borde delantero redondeado con una tira de luz.
- **Izquierda.** La puerta empotrada a ras de la pared (el zócalo se corta contra su marco y en el hueco hay un umbral), una barra de estado encima, el panel de acceso (pantallita y teclado de 3x4) y el monitor de stats, grande y centrado en vertical, con margen hasta el zócalo.
- **Derecha.** La vitrina, de pie sobre su peana y separada de la pared (se ve la tapa de la peana a los lados y delante), con el interior en perspectiva (techo con una tira de luz cálida, laterales y fondo de terciopelo acolchado), labio y escuadras doradas y la insignia de estrella con alas en la peana. Dos apliques de luz cálida a los lados. Sin sombras en la pared ni en el suelo.

**Objetos.** Cada uno es un `OfficeObject` (`scripts/main_menu/OfficeObject.gd`, `Control`) que pinta lo animado en `_draw_object()` y se redibuja cada frame (`time`). Al pasar el ratón (`hovered`, que se mira cada frame con `gui_get_hovered_control()`, así que se apaga también cuando un panel lo tapa) se marca con corchetes en L `#befaff` (`hover_rect()`; `show_brackets` los quita). Las piezas apoyadas en la consola inclinada (radar, tablet y opciones) devuelven además `hover_quad()`, su contorno en trapecio (`table_out`, `tray_quad`, `opt.quad`), y sus corchetes siguen la inclinación de los lados, sin rótulo de texto; el cursor es la mano. Un clic izquierdo emite `pressed`. Sus hijos no reciben el ratón.

| Vista | Nodo | Script | Abre | Qué se anima |
|---|---|---|---|---|
| Centro | `RadarConsole` | `RadarConsole.gd` | `LevelSelectionScreen` | Mesa holográfica rectangular apoyada en la consola, así que se ve en trapecio. La pantalla es el shader `resources/shaders/office_radar.gdshader` en `Screen` (`ColorRect`), que enseña la pantalla de Sectores de verdad (radar, subtítulo, ficha y "Volver", en vivo): mientras está cerrada, `LevelSelectionScreen` se pinta en `RadarViewport` (`SubViewport` a la resolución real) y el shader estira a todo el trapecio, sobre su fondo de cuadrícula, solo el contenido (`LevelsPanel` más `SCREEN_MARGIN`, 40 px a los lados y 32 arriba y abajo), para que se vea más grande. Se pulsa en el contorno de la mesa (`_has_point`) |
| Centro | `ArchiveTablet` | `ArchiveTablet.gd` | `Navedex` (con zoom) | Terminal de mano militar (`tablet.png`): carcasa de metal oscuro con las esquinas de arriba a la izquierda y abajo a la derecha cortadas y su canto abajo, dos tornillos arriba, asas de metal atornilladas a los lados y, bajo la pantalla, una tira de luz cian y tres botones físicos (NAVES encendido en cian, TORRETAS y VOLVER) con un piloto encima de cada uno, como el terminal de cerca. Va en una bandeja hundida centrada entre las dos juntas de la consola y tan alta como el módulo de opciones con su canto (de y = 316 a 494, casi lo mismo que la mesa del radar; `TRAY` en `gen_center.py`, y el nodo `ArchiveTablet` ocupa su caja), centrada a la vista en ella (el borde oscuro de la bandeja y el canto cuentan como hueco). La ranura de luz queda bajo el canto. La pantalla (`TAB_TOP`, `TAB_BOTTOM`, `TAB_SIDE`) se llena centrada: una cabecera arriba, el holograma cian de una nave (su frame `up` pasado a la rampa cian por brillo, `make_hologram`), líneas de datos centradas y 4 fichas a todo el ancho abajo, con el mismo hueco entre ellas. Con el ratón encima la tablet sube 8 px con su sombra, se enciende la luz del fondo de la bandeja, la nave gira sobre su centro (se estrecha por los dos lados y se voltea en su sitio, sin moverse de lado) y baja una línea de escaneo |
| Centro | `OptionsConsole` | `OptionsConsole.gd` | `OptionsCloseUp` (con zoom) | Módulo de metal con los valores reales de `Settings`: la pantalla enseña tres vúmetros (nivel real de los buses `Master`, `Music` y `SFX`; apagados con `muted`) con el fader de su volumen al lado, separados 7 px. Abajo, tres pomos brillantes con su canto y una marca hacia su posición (Idioma, Pantalla completa, VSync) y cinco interruptores con la palanca arriba (ON) o abajo (OFF), centrados e inclinados con la consola; las palancas se pintan en el trapecio de su ranura (`opt.switches`) |
| Izquierda | `ExitDoor` | `OfficeDoor.gd` | Vuelve a la pantalla de inicio | Dos hojas lisas de metal oscuro con la junta en zigzag y franjas de luz. Con el ratón encima solo se entreabren (`slide`, 26 px cada una, en 0,35 s): por la rendija se ve la luz del pasillo (`corridor.png`, sin detalle) y una luz tenue cae en el suelo, tan ancha como la rendija; se encienden la luz del marco (`door_glow.png`) y la pantallita del panel de acceso (`access_lit.png`). Cerrada, la junta brilla (`door_seam.png`) y un pulso sube y baja por las franjas. La barra de estado de encima la recorre un tramo de luz (verde con la puerta activa). `Plane` (`door_plane.png`, `clip_children`) recorta las hojas y el pasillo con la forma del hueco. Sin corchetes. Al pulsarla (`open_fully`) se entreabre y emite `opened` |
| Izquierda | `CombatScoreboard` | `CombatScoreboard.gd` | `StatsScreen` | Pantalla sin datos: "// REGISTRO DE COMBATE", 8 barras que suben y bajan, una línea de 2 px que avanza, un anillo de cuatro colores que gira con su leyenda y 5 fichas con el icono (a escala 1) de lo que se cuenta: naves destruidas, victorias, torretas, oleadas perfectas y naves vistas. Abajo, "SISTEMA EN ESPERA" con un cursor |
| Derecha | `MedalCase` | `MedalCase.gd` | Ninguno (no se pulsa) | Una medalla por logro de `GameState.ACHIEVEMENTS` (`medal_<id>.png`, o `medal_empty.png` si falta), en filas de 3, 4 y 3 centradas y escalonadas medio paso, sin solaparse, pintada en el metal de su fase (`AchievementTint`: disco, anilla, pasador y símbolo; la cinta guarda su color); los reflejos del cristal (`case_glass.png`) encima y un destello de vez en cuando en las conseguidas. Solo las medallas se miran: con el ratón encima de una, corchetes en ella y una ficha (nombre y fase en el color de la fase (o "???" en gris, sin fase, si no se tiene) y descripción con la meta que toca) debajo, o encima si no cabe; fuera de las medallas no hay corchetes ni mano |

## Comportamiento

- **Giro de la silla:** se empieza en la vista central. `TurnArrow` (`scripts/main_menu/TurnArrow.gd`) es una placa de 22x44 a 16 px del borde con un doble chevrón cian que se ilumina y se adelanta al pasar el ratón. Pulsarla, o las teclas ← → o A D, llama a `_turn(-1 / 1)`: un tween de 0,45 s (seno, entrada y salida) desplaza `Views` y `Space` 960 px, redondeando a píxeles enteros. En una vista lateral solo se ve la flecha que vuelve al centro.
- **Zoom a un objeto:** `_zoom_in(panel, step)` y `_zoom_out(step)` acercan y alejan la oficina en `ZOOM_TIME` (0,7 s, seno, entrada y salida); `step(amount)` (0 la oficina normal, 1 acercada) coloca `Office` y `Space` con `_zoom_office(focus, final_scale, target, amount)` (el punto `focus` de la vista central acaba en `target` del menú, con escala `final_scale`) y hace lo propio del objeto. `PanelDim` va transparente, solo para tapar la oficina al ratón. Mientras dura (`_zooming`) no se gira ni se pulsa nada. Lo usan la mesa del radar (`_set_radar_zoom`), la consola de opciones (`_set_options_zoom`) y la tablet del archivo (`_set_tablet_zoom`).
- **Mesa del radar:** no abre Sectores con fundido. `_open_sectors()` acerca la oficina hacia la pantalla de la mesa mientras `RadarConsole.set_zoom()` endereza el trapecio hasta quedar justo encima de ese contenido (`_screen_rect`), centrado. Con el zoom aparece en el margen un marco de metal de 24 px (`frame_px`: bisel, línea cian, pilotos arriba y luces ámbar en las esquinas) y a los lados se ve la oficina: al final se ve la pantalla, no solo lo de dentro. Entonces `LevelSelectionScreen` sale de `RadarViewport` y queda encima, igual (sin salto). Al cerrar (`_close_sectors()`, con "Volver" o Escape) vuelve a `RadarViewport` y se hace lo inverso.
- **Consola de opciones:** al pulsarla, la oficina se acerca hasta que la consola ocupa el sitio de `OptionsCloseUp` (su alto); desde `CLOSE_UP_FADE_START` (0,85 del zoom) la consola de cerca aparece encima con un fundido. Escape, "Volver" o un clic fuera de la consola (`back_pressed`) hacen el zoom inverso. La pantalla de Sectores no tiene cabecera "// SECTORES". Sus botones ("Volver" y DESPLEGAR / REPETIR de la ficha) usan la variación `ScreenButton` de `menu_theme.tres`: solo el contorno, como dibujados en la pantalla, con un relleno cian tenue al pasar el ratón.
- Cada objeto abre su panel (menos la tablet, la mesa del radar y las opciones, que usan el zoom) con `_open_panel(panel)`: `PanelDim` y el panel aparecen con un fundido de 0,25 s, con la oficina quieta detrás. "Volver" de cualquier panel (o `back_pressed` de `Navedex` y `OptionsCloseUp`) llama a `_close_panel()`, el fundido inverso. Con un panel abierto no se gira.
- **Escape** (`ui_cancel`): con "¿Volver al inicio?" abierto lo cierra; con un panel abierto, lo cierra; en la oficina abre "¿Volver al inicio?". "Salir" vuelve a la pantalla de inicio (sin esperar a la puerta) y "Cancelar" lo cierra.
- La puerta se entreabre y después se vuelve a la pantalla de inicio. Ambas salidas usan un `ScreenWipe` que tapa (0,7 s) y destapa (0,6 s) desde el centro de la pantalla, cambiando a `StartScreen` a mano; `MainMenu` carga `StartScreen` con `load` porque un `preload` sería circular.
- Si `start_on_level_selection` es `true` (lo pone `Game` al volver de un nivel), el menú abre con la selección de nivel ya abierta sobre la vista central, sin animación (la oficina ya acercada detrás).
- `_refresh_sectors()` (al abrir el menú, al pulsar la mesa de Sectores y con `GameState.progress_reset`) vuelve a leer el progreso en el radar y la ficha.
- Clic en un contacto del radar = seleccionarlo (`sector_selected` → la ficha lo enseña). Para jugar: el botón DESPLEGAR / REPETIR de la ficha (`deploy_pressed`) o doble clic en el contacto (`sector_launched`); los dos llaman a `_open_level`.
- `_open_level(data)` instancia `scenes/Game.tscn`, le asigna `level_data` y la pone como escena actual.
- **Nivel de emergencia:** `open_emergency()` lanza el nivel de prueba del tutorial (`GameData.emergency_level`) con `_open_level`, salto al hiperespacio incluido. Una partida que aún no lo ha pasado (`GameState.tutorial_done` false) lo lanza sola al abrir el menú, 0,8 s después (`EMERGENCY_DELAY`, mientras la pantalla de inicio destapa la oficina), salvo al volver de un nivel. Del nivel de emergencia se vuelve a la oficina, no a la selección de nivel.

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

## Radar de sectores

`SectorRadar` (`scripts/level_ui/SectorRadar.gd`) pinta todo en `_draw`, cada parte en su función (`_draw_background`, `_draw_grid`, `_draw_sweep`, `_draw_fog`, `_draw_ring_labels`, `_draw_route`, `_draw_station`, `_draw_contacts`), para que el modo corrupto del jefe pueda cambiar o añadir partes. Colores de la interfaz: disco en bandas de `#122440` (centro) a `#060b14`, anillos y radios `#1c4a60`, marcas del borde `#1c7496`, borde, estación y alcance `#40e0f0`, barrido `#befaff` con estela `#40e0f0`.

- Estación en el centro (cruz y cuadro con hueco). 4 anillos y radios cada 30°; marcas del borde cada 5° (más largas cada 30°).
- Barrido: gira a 1,6 rad/s con una estela de 36 cuñas. Al pasar por un contacto lo enciende (alfa 1) y se apaga en 2,6 s hasta 0,45 (0,75 el primer nivel pendiente).
- Un contacto por nivel de `GameData.levels`, en `LevelData.radar_distance` (fracción del radio) y `radar_bearing` (0° arriba, sentido horario). Cada uno más lejos que el anterior (0,20 a 0,70), repartidos por todo el disco para que no se amontonen; ningún nivel usa la zona de arriba (reservada al jefe) ni la de la derecha justo encima del eje (textos de km).
- Estados (`get_level_state`): oculto si `GameState.is_unlocked(i)` es `false`; completado (verde `#3cb860`) si tiene estrellas o es anterior a `current_level`; si no, pendiente (amarillo `#ecb23c`). Con el ratón encima o seleccionado, azul `#54a0e2`. El seleccionado da un salto de 6 px, luego flota 2 px arriba y abajo y suelta una onda circular cada 1,4 s; del centro sale hasta él una ruta discontinua azul animada.
- Alcance: llega justo al último contacto visible (su distancia + 0,04, sin pasar de la mitad hasta el siguiente + 0,02; tope 0,9). Fuera, niebla oscura con 120 puntos de ruido nuevos en cada frame; el borde del alcance es un círculo discontinuo que gira. El radar solo enseña los niveles hasta el progreso real (`índice < GameState.current_level`), aunque `is_unlocked()` devuelva siempre `true` para probar.
- Textos de km de los anillos (radio total `RADIUS_KM` = 4.000 km, separador de miles `NUMBER_THOUSANDS_SEP`) a 16 px, a la derecha justo encima del eje; solo los anillos dentro del alcance (fuera no se ve ninguno). Van sin "km" porque a este tamaño no caben.
- Sector del jefe: mientras `GameData.levels` tenga menos de `TOTAL_SECTORS` (10), el último sale como contacto `UNKNOWN` de prueba arriba en el centro (distancia 0,72, rumbo 0°), solo cuando se ha ganado el último nivel que hay (entonces el alcance llega a su tope, 0,9): un "?" rojo `#e65a4f` que late, con su rótulo `SEC-10`. Se puede seleccionar (la ficha dice SIN DATOS, todo "???" y el botón NO DISPONIBLE apagado), pero no se juega. El modo corrupto es el ticket `radar-corrupto-jefe`.
- Iconos: las naves de `LevelData.radar_ship` (incursor, colmillo, triturador y espectro), 16x16 dibujadas a ×2 y teñidas con el color del estado; los ojos se pintan encima en `#f0323c` y parpadean (ciclo de 3,5 s, desfasado por contacto). Debajo, el rótulo `SEC-0N` a 16 px. Los sprites (`assets/sprites/enemies/radar/radar_<nave>.png` y `radar_<nave>_eyes.png`) no se dibujan a mano: los genera `scripts/tools/make_radar_ships.gd` (`godot --headless --path . -s scripts/tools/make_radar_ships.gd`) a partir de plantillas de texto (casco en grises con luz arriba, sombra abajo y contorno `#0a0810`; los ojos son un hueco oscuro en el casco y un PNG aparte en blanco). Si aún no existen, el contacto se pinta como un cuadro.

### Ficha

`SectorCard` (`scripts/level_ui/SectorCard.gd`, `MarginContainer` que crea sus filas en código): fondo `#0a0f1a` al 88 %, borde `#1c4a60` y esquinas en L de `#40e0f0` que salen 3 px. Todo a 24 px. Ancho fijo de 300 px; título, nombres de fila y botón se recortan en vez de ensanchar la ficha, para que no se mueva con textos más largos ni al cambiar de idioma.

- Título `SEC-0N - NOMBRE` en `#40e0f0` (con guion: Monogram pinta el punto medio arriba) (nombre de `LevelData.sector_name`, clave `SECTOR_<n>_NAME`).
- Filas con línea de puntos debajo (nombre `#5a7a96`, valor `#cce6ff`): ESTADO (ASEGURADO en verde o SEÑAL ACTIVA en amarillo), RUMBO (`radar_bearing`, `000°`), DISTANCIA (`radar_distance` × 4.000 km, redondeada a decenas), OLEADAS (`waves.size()`), AMENAZA (`LevelData.threat`: BAJA verde, MEDIA amarilla, ALTA naranja `#ff8c32`, EXTREMA roja `#ff3c5a`, solo para el jefe) y MEJOR: las estrellas de `GameState.get_level_stars()` en pixel art (`VictoryScreen.STAR_SHAPE` a 2 px, llenas `#ecb23c`, las que faltan solo con el contorno en el mismo color, como ☆), todas vacías si no está completado.
- Botón `» DESPLEGAR «` en amarillo, o `REPETIR` en verde si está completado. Emite `deploy_pressed`.
- Se repinta con `NOTIFICATION_TRANSLATION_CHANGED`.

## Salto al hiperespacio

`MainMenu._open_level` (una sola vez, ignora más pulsaciones; desde DESPLEGAR / REPETIR o doble clic en el radar) llama a `_hyperspace_jump()`: `Space/StarField.warp(0.5)` (las estrellas se estiran por el ventanal) y un `ColorRect` blanco que cubre el menú en 0,1 s; después carga el nivel. Solo desde el menú ("Siguiente sector" no hace el salto).

## Navedex

`scenes/Navedex.tscn` + `scripts/screens/Navedex.gd` (clase `Navedex`). Archivo de naves y torretas, dentro de la tablet de la oficina. Al pulsar `ArchiveTablet`, `MainMenu` hace el zoom generalizado (`_set_tablet_zoom`: la tablet sacada, `ArchiveTablet.get_lifted_rect()` con el tamaño de `tablet.png`, va al centro de la vista a `Navedex.SCALE` = 3) y desde `CLOSE_UP_FADE_START` aparece encima `Navedex` con un fundido. `ArchiveTablet.held` la mantiene sacada mientras está abierta. Escape o "Volver" (`back_pressed` -> `_close_panel()`) hacen el zoom inverso.

- **Terminal:** `Navedex._draw` pinta, a ×3 y de frente, el mismo terminal que `tablet.png` (`FRAME_SIZE` 147x178): asas, carcasa de metal con las esquinas cortadas en escalera (`_cut_box`) y tornillos, la pantalla (`SCREEN_RECT`) con su aro, la tira de luz y un piloto encima de cada botón (encendido el de la pestaña elegida); tapa la tablet inclinada de la oficina. En la banda de abajo, tres botones físicos (`_style_physical`: metal con contorno grueso, cian el de la pestaña elegida): NAVES, TORRETAS (`ButtonGroup`, `_open_tab`) y "Volver".
- **Pantalla:** lo elegido es lo principal. `Content` deja 12 px de margen dentro de la pantalla (327x372). Arriba, la vitrina (`Showcase`): en las naves crece con el hueco que sobra (112 px como mínimo); en las torretas mide siempre 112 px, para que el mapa tenga el mismo tamaño en todas, y el hueco que sobra queda en `Spacer`, entre los stats y el carrusel. Debajo, el nombre (24 px, centrado) entre las flechas de mejora de torreta, "MEJORA: nombre", la `description` (16 px, centrada) y los stats en dos columnas (`StatRows`, `GridContainer` con 12 px entre columnas y 5 entre filas). Abajo, el carrusel. Todo cabe con la torreta que más ocupa (Orbitador).
- **Vitrina** (`scripts/screens/NavedexShowcase.gd`, clase `NavedexShowcase`): un mini nivel en vivo con las piezas reales del juego, así que se ve igual que en partida y no hay una segunda versión de los efectos. Un `SubViewport` (a la resolución final de pantalla, con el aumento en la transformación del canvas y no ampliando la imagen, para que lo que gira salga nítido: a ×1 en las torretas, con la cámara lejos, y a ×2 en las naves) con, en las torretas, un trozo de mapa del juego (`scenes/maps/<Nombre>Map.tscn`, 28x16 casillas, generado de `resources/map_data/navedex*.txt` por `map_generator.gd`: fondo `SpaceBackground`, rocas y gravilla, el pasillo libre del camino sin dibujar y las casillas de torreta con su asteroide con plataforma; se recorta por los bordes y la casilla de la torreta queda donde diga su escena) o, en las naves, fondo oscuro con cuadrícula y un `Path2D` cerrado (rectángulo); y, encima, el borde y las escuadras cian. Se para con la Navedex cerrada. Mapas: `navedex.txt` (`NavedexMap`), un pasillo vertical con la torreta 3 casillas a su izquierda, para el Cañón doble, la Minigun y el Cañón pesado; las demás tienen el suyo, `navedex_<torreta>.txt` (`NavedexCryoMap`...; las mejoras usan el de su base), con la torreta en el centro salvo el Rail. El mapa del Amplificador es de 44x18 y el del Minero lleva la estación espacial (`station`, con su `SpaceStation` y el camino que llega a ella). La escena admite `zoom` (aumento propio), pero todas van a ×1. Torretas: la `Turret` de verdad (`Turret.tscn` con su `TurretData`) a la izquierda, sobre su asteroide, colgando de un `BuildManager` con su `LevelState` (oleada en curso, para la excavadora), como en partida. Las naves de la escena de cada torreta (`NavedexShowcase.SCENES`, un diccionario por torreta base; las mejoras usan la de su base) van por los caminos del mapa (`Paths`) como en una oleada: entran donde cada camino entra en la vitrina, salen por otro borde (y se quitan) o mueren, y cada `interval` s sale por cada camino otra o un grupo de `group` en fila a 26 px (`SHIP_GAP`), sin pasar de `max` en la vitrina. Velocidad y vida (multiplicador) se cambian solo en la vitrina; los `.tres` no se tocan. Escenas: Cañón doble, grupos de 3 Darts verdes (vida ×4) cada 6 s, lo básico; Minigun, Acorazados lentos (20 px/s, vida ×3) seguidos cada 2,5 s, para que no le falte objetivo y se vea la rampa de cadencia, el calor y la parada; Cryo, entre dos caminos, uno a cada lado a 3 casillas dentro de su onda, con Darts rojos rápidos (60 px/s) que no mueren y frenan al pasar junto a ella; Cañón pesado, parejas de Naves normales cada 7 s, para el área; Tesla, un camino en zigzag a su alrededor con oleadas de 4 Naves normales cada 6 s, para los saltos de la cadena; Rail, a la izquierda, al final de una recta que viene hacia él y gira hacia abajo 4 casillas antes, con filas de 4 Naves normales cada 5 s que el haz atraviesa enteras; Disintegrator, el camino le pasa por encima en arco, siempre a su alcance, con un Acorazado lento (15 px/s) cada vez, al que el haz no suelta y sube de nivel hasta romperlo; Orbitador, algo por encima del centro, entre dos caminos horizontales que cruzan su anillo, uno 2 casillas por encima (pasa también por el hueco de dentro) y otro 3 por debajo, con Naves agresivas lentas (20 px/s) cada 7 s, para que le dé tiempo a cargar y se vean las cargas girar y chocar; Amplificador, un Cañón pesado y una Tesla a 6 casillas, dentro de su aura, amplificados desde el principio (`set_amplification`, no hay `Grid`), que disparan a Naves normales (vida ×2, cada 3 s) por un camino por debajo: la onda los hace brillar, la explosión del cañón es más grande y la cadena salta a más naves (el aura se recorta por arriba y por abajo); Minero, junto a la estación espacial y sin naves, generando dinero con la oleada en curso, para que se vea que no ataca. Las balas son las de partida: si su objetivo muere antes de llegar, siguen rectas y pueden dar a la nave siguiente. Naves: el `Enemy` de verdad da vueltas a un bucle centrado (`loop` del `PathFollow2D`), con la animación y el giro del juego (`rotate_sprite`, `rotation_offset`) y su habilidad: el Espectro se camufla y la Saboteadora lanza el EMP. La Reparadora cura a una nave secundaria tenue (Dart al 45 % de opacidad y sin vida, que vuelve a perderla al curarse del todo). La Divisora se parte cada 3 s como en `Spawner` (grieta y trozos) y a los 3 s vuelve a salir entera. Las no vistas dan vueltas en silueta negra y sin habilidad (una copia de su `EnemyData` sin `heal_aura`, camuflaje, EMP ni `split_into`).
- **Carrusel** (`Carousel`): flechas y 5 celdas `EnemyCell` de 40x40 sin contador; la del medio es la elegida (pulsada). Las flechas o una celda de los lados lo mueven (`_step`) y da la vuelta en los extremos. Las celdas se crean una vez y al moverse cambian de dato.
- **Stats con barra:** cada stat (`StatRow`, con el fondo alterno por filas, y una barra de 3 px a 1 px debajo) escala su valor (lo que se lee del texto con `to_float()`) frente al más alto de ese stat entre los de la pestaña (`_stat_max`, incluidas las mejoras de torreta). Los valores que no son número no llevan relleno.
- Torretas: el carrusel solo tiene las base. `PrevButton` y `NextButton` (`<` y `>` a los lados del nombre, cajas de 28 px con el estilo de `EnemyCell`: `Navedex._style_arrow`) pasan por la cadena base -> `TurretData.fusion` y vuelven; al cambiar se actualizan vitrina, nombre, descripción y stats. Se desactivan en los extremos y en las naves son invisibles (no ocultos, para que el nombre no se mueva). "MEJORA: nombre" se ve en las versiones que aún tienen otra mejora.
- Un enemigo es "visto" si `GameState.has_seen_enemy(data)`. Los no vistos salen en el carrusel en silueta negra y en la vitrina como silueta, con nombre "???" y sin descripción ni stats.
- Al mostrarse se refresca lo elegido (por si se vio una nave nueva). Al cambiar de pestaña se elige el primero.
- Las torretas (`TURRET_FILES`, solo las base) siempre se ven completas.
- Si se añade un enemigo o torreta nuevos, hay que añadirlo a `ENEMY_FILES` / `TURRET_FILES`.

### Logros

Los logros se ven en la vitrina de condecoraciones de la oficina (`MedalCase`, ver "Oficina"): no hay pantalla propia. Al pasar el ratón por una medalla sale su ficha con el nombre, la fase conseguida, todo en su color (si aún no se tiene, el nombre es "???" en gris apagado y sin fase; la descripción sale siempre) y la descripción con la meta de la siguiente fase (`GameState.achievement_description`). La Navedex no tiene pestaña de logros.

**Fases.** Cada logro tiene 3 fases (bronce, plata y oro, `GameState.PHASE_BRONZE`..`PHASE_GOLD`) con metas crecientes, o 1 sola, que se consigue directamente en oro; no hay de 2. Los 10 logros están en `GameState.ACHIEVEMENTS` (id -> nombre, descripción con `%d` y metas; `GOAL_ALL` = todos) y lo que cuenta cada uno en `GameState.get_progress()`:

| Id | Nombre | Cuenta | Bronce | Plata | Oro |
|---|---|---|---|---|---|
| `first_win` | Primera victoria | niveles ganados | | | 1 |
| `flawless` | Intacto | ganar sin perder vida (`register_win`) | | | sí |
| `all_levels` | Sector despejado | ganar el último nivel (`register_win`) | | | sí |
| `wins` | Veterano | niveles ganados | 5 | 15 | 30 |
| `kills` | Cazador | naves destruidas | 100 | 1000 | 3000 |
| `seen` | Observador | tipos de nave de la Navedex vistos | 5 | 10 | todos |
| `turrets` | Constructor | torretas construidas | 50 | 200 | 500 |
| `fusions` | Maestro de mejoras | tipos de torreta mejorados | 1 | 5 | todos |
| `powers` | Poder desatado | poderes usados | 1 | 25 | 100 |
| `perfect_waves` | Defensa perfecta | oleadas perfectas | 10 | 30 | 90 |

`get_phase(id)`, `phase_count(id)`, `get_goals(id)`, `next_goal(id)`, `phase_name(fase)` y `PHASE_COLORS` sirven a la vitrina y la lista. Las medallas y los iconos tienen un solo PNG; `AchievementTint.tint(textura, fase, filas que no se tocan)` (`scripts/main_menu/AchievementTint.gd`) cambia los colores ámbar, rojo y cian de la paleta de la oficina por el tono del mismo brillo del bronce, la plata o el oro (el oro es el ámbar tal cual) y guarda la textura. Si un contador salta varias metas de golpe, solo avisa la fase más alta.

**Guardado.** La fase de cada logro se guarda en la ranura activa, `user://saves/slot_N.cfg` (`achievements`: id -> fase, más los contadores `stats` y `fused_turrets`) y se borra al borrar la ranura. Las ranuras viejas tienen la lista `unlocked` con los ids de antes: `GameState.LEGACY_ACHIEVEMENTS` dice para qué fase cuenta cada uno como mínimo (`kills_1000` es plata de `kills`, `fuse_all` plata de `fusions`...), y al cargarla (`load_slot`) las fases se recalculan con los contadores, sin avisos, y se guarda. `load_slot` también migra los nombres antiguos (`fused_towers`, contador `towers`) a `fused_turrets` y `turrets`. El contador de logros de las ranuras (`get_slot_summary`) es fases conseguidas sobre el total de fases (24).

- Contadores (`GameState.add_stat`): bajas (`Level`, por `enemy_died`), torretas construidas, poderes usados, oleadas perfectas y niveles ganados. `register_fusion` lo llama `BuildManager.upgrade_selected`; `register_win(número, intacto)` lo llama `Game` al ganar (intacto = la estación con toda la vida).
- Los contadores se guardan con `flush()` al limpiar una oleada y al ganar o perder, no a cada baja; al conseguir una fase se guarda al momento.
- Al conseguir una fase sale `LOGRO: nombre (fase)`, en el color de la fase, arriba a la derecha 3 s y se desvanece (capa propia de `GameState`, también en pausa y victoria).

## Música

`scripts/autoloads/MusicManager.gd`, autoload de tipo `AudioStreamPlayer`.

- Carga `assets/audio/music/theme.ogg` (el bucle va activado en su import) y la reproduce al arrancar. Si el archivo no existe, avisa y no suena nada.
- `process_mode = ALWAYS`: sigue sonando con el juego en pausa. Al ser autoload no se corta al cambiar de escena.
- Suena por el bus `Music`. No guarda volumen ni silencio: eso lo lleva `Settings` a través de los buses.

Convención de formatos: los audios largos o en bucle (música, ambientes, sonidos de nave largos, GameOver y Victory) van en OGG Vorbis; los efectos cortos, en WAV. Solo `theme` y los dos ambientes (`LevelAmbience/`) tienen `loop=true` en el import.

Es el único audio del juego: todavía no hay efectos de sonido, así que nada suena por el bus `SFX`.

## Consola de opciones

En el menú principal las opciones se tocan en la consola de cerca, `OptionsCloseUp` (`scripts/main_menu/OptionsCloseUp.gd`, `Control` a pantalla completa en `MainMenu`): la consola de la oficina de frente, 660x500 y centrada, a resolución completa. Lo fijo es `options_close.png` (metal, pantalla y mesa hundidas, aro del pulsador, pomos con sus dos marcas, ranuras con el hueco del piloto, pantallita y botón), que dibuja `gen_center.py` › `build_options_close()` con el mismo estilo que la oficina; las posiciones están en `OfficeLayout.CENTER.opt_close`. En código se pintan los mandos con el valor de `Settings`, y cada cambio llama a `Settings.set_value` y se ve al momento (el idioma, en toda la consola).

- **Faders** (pantalla de arriba): General, Música y Efectos (`master_volume`, `music_volume`, `sfx_volume`). Se arrastran en vertical (o con la rueda) en pasos de 0,05. A su izquierda, separado 24 px (`FADER_GAP`), un vúmetro de 14 segmentos con el pico real del bus (`OptionsConsole.meter_level`: 48 dB en la barra, cae 1,5 barras por segundo); con `muted`, apagado.
- **Silenciar:** pulsador grande, rojo encendido con `muted`. Clic.
- **Pomos:** Idioma (`language`, posiciones ES / EN), Pantalla completa y VSync (OFF / ON). Clic pasa a la siguiente posición; la rueda gira hacia un lado. La marca apunta a 45° a la izquierda o a la derecha de arriba, y el nombre de la posición elegida se enciende.
- **Palancas:** Mostrar FPS, Rango de torretas, Números de daño, Temblor de pantalla y Pausar sin foco. Arriba ON (piloto verde), abajo OFF. Clic.
- **Pantallita:** con el ratón encima de un mando, su nombre y su valor ("MÚSICA 40%", "IDIOMA ES"), con las claves de `OptionsMenu`; si no, "OPCIONES" con un cursor que parpadea.
- **Volver:** botón de la consola (`BTN_BACK`).
- El mando bajo el ratón se marca con los corchetes de la oficina y el cursor es la mano.

`OptionsConsole` tiene las listas de mandos en orden (`FADERS`, `KNOBS`, `SWITCHES`) y lo que comparten las dos consolas (`meter_level`, `knob_values`, `knob_index`, `knob_angle`).

## Opciones

`scenes/OptionsMenu.tscn` + `scripts/screens/OptionsMenu.gd` (clase `OptionsMenu`). Solo en el menú de pausa (en el menú principal están en la consola de opciones). Un panel holograma cian (`OverlayFrame`) centrado, con los mismos márgenes que el menú principal (24 / 21), con el título "OPCIONES", dos columnas de secciones con cabeceras `// AUDIO`, `// PANTALLA` y `// JUEGO`, y debajo el botón "Volver" (ver más abajo). Etiquetas, cabeceras y botones a 24 px. Columnas separadas 36 px. Está instanciada en el menú de pausa (ver [ui.md](ui.md)).

- `open_from(opener)`: funde de `opener` (el panel que la abre, en la pausa) a las opciones, 0,25 s de salida y 0,25 s de entrada, y recuerda `opener`.
- "Volver" hace el fundido inverso hacia ese mismo panel. Sin `opener`, "Volver" emite `back_pressed`.
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
| JUEGO | Botón "Números de daño" | `show_damage_numbers` |
| JUEGO | Botón "Temblor de pantalla" | `screen_shake` (encendido por defecto) |
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
- `fullscreen` y `vsync` se aplican con `DisplayServer`. En OFF la ventana se maximiza (toda la pantalla menos la barra de tareas) y el escalado es fraccionario (`window/stretch/scale_mode="fractional"`) para que el juego la llene; en pantalla completa 1080p sigue siendo x2 exacto. Si el jugador restaura la ventana, toma `window/size/window_*_override` (1280x720): tiene que ser menor que el monitor, porque en Windows una ventana del tamaño exacto de la pantalla pasa sola a pantalla completa exclusiva. `fullscreen` vale `true` por defecto, igual que `window/size/mode=3` de `project.godot`. Incrustado en el editor (`Engine.is_embedded_in_editor()`, F5 de Godot 4.7) la ventana no cambia: `Settings.get_value(&"fullscreen")` devuelve `false`, `set_value` lo ignora y el botón de `OptionsMenu` queda desactivado.
- `language` (texto, `"es"` por defecto) se aplica con `TranslationServer.set_locale`; si el archivo trae un código que no está en `LANGUAGES` (`["es", "en"]`), se usa el español.
- `screen_shake` tampoco hace nada aquí: la lee `Level.shake_map()` en cada temblor (ver [base.md](base.md)).
- `show_fps`, `show_turret_range` y `show_damage_numbers` no hacen nada aquí: las leen `LevelUI` (ver [ui.md](ui.md)), `Turret` (ver [torretas.md](torretas.md)) y `Enemy` (ver [enemigos.md](enemigos.md)), que escuchan `changed` para actualizarse al momento.
- `pause_on_focus_loss` tampoco hace nada aquí: la lee `Game` cuando la ventana pierde el foco (ver [flujo.md](flujo.md)).

## Idiomas

Los textos visibles están en `translations/textos.csv` (columnas `keys,es,en`), registrado en `project.godot` (`internationalization/locale/translations`, con los `.translation` que genera Godot al importar el CSV; idioma de reserva `es`). Ni escenas ni scripts llevan textos a mano: usan claves en mayúsculas con prefijo por zona (`BTN_`, `HEADER_`, `OPT_`, `HUD_`, `STAT_`, `TAG_`, `TUTORIAL_`, `ACH_`, `TURRET_`, `ENEMY_`...).

- En los `.tscn` el `text` de `Label` y `Button` es la clave y Godot lo traduce solo (también al cambiar de idioma). Las cabeceras `ScreenHeader` guardan la clave en `title` y la traducen con `tr()`; se repintan con `NOTIFICATION_TRANSLATION_CHANGED`.
- Los textos con números o nombres se montan con `tr("CLAVE") % valores` (por ejemplo `HUD_WAVE_N` = "OLEADA %d"). `Sidebar` y `LevelIndicator` guardan lo último que enseñaron y lo repintan al cambiar de idioma, para que la pausa → Opciones → idioma se vea al volver a la partida.
- `TurretData` y `EnemyData` guardan en `name` y `description` claves (`TURRET_<archivo>_NAME` / `_DESC`, `ENEMY_<archivo>_NAME` / `_DESC`; los tres fragmentos de la Divisora comparten `ENEMY_FRAGMENTO_DIVISORA_*`). Para enseñarlos se usa `get_inspect_name()` / `get_inspect_description()`, que ya traducen; `RunStats.top_turret_name` guarda la clave y la traduce `RunSummary`.
- `StatEntry` recibe el nombre del stat como clave (`STAT_...`) y lo traduce al crearse; las etiquetas de tipo (`TAG_...`) las traduce `get_inspect_tag()`. Ambos caben en 9 caracteres también en inglés.
- Los logros de `GameState.ACHIEVEMENTS` son pares de claves (`ACH_<ID>_NAME`, `ACH_<ID>_DESC`, esta con `%d` para la meta y, si la meta puede ser 1, `ACH_<ID>_DESC_ONE`); las fases, `ACH_PHASE_BRONZE`, `ACH_PHASE_SILVER` y `ACH_PHASE_GOLD`.
- Se quedan sin traducir el título "ASTRO ARTILLERY" / "TOWER DEFENSE", "NOVA", "VSync", "AUTO", "ON" / "OFF", los "×1" / "×2" y los números.

Para añadir un idioma: una columna nueva en el CSV, su `.translation` en `project.godot` y su código en `Settings.LANGUAGES`.

## Dudas

- El fundido está escrito dos veces: en `MainMenu._fade_panel` (paneles de la oficina) y en `OptionsMenu._fade`.
- VSync no tiene efecto si el juego se ejecuta incrustado en el editor de Godot; hay que ejecutarlo en su propia ventana.
