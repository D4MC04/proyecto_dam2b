# Arte

Descripción de lo que hay en `assets/`. Los tamaños y colores están medidos sobre los PNG.

En `assets/` conviven dos estilos: uno propio, con paleta corta y contorno uniforme, y varios packs con otra paleta y otra resolución. Este documento describe el primero como estilo del juego y lista los demás aparte.

## Tamaños

La casilla del mapa es de 16x16 px. Los sprites de juego son múltiplos de esa medida, no 16x16:

| Elemento | Tamaño de frame |
|---|---|
| Torres (base, cañón, icono `_full_up`) | 32x32 |
| Enemigos pequeños (Dart, Wasp) | 24x24 |
| Enemigos medianos y grandes (naves, Acorazado, Ariete, Nodriza, UFO) | 32x32 |
| Spikey (`spiked_ship`) | 34x34 |
| Estación (`base/estacion/`) | 80x80 centrada en frames de 96x96 |
| Escudo de la estación | 64x64 (escalado a 1,25 en juego) |
| Bala del Cañón doble | 4x8 (tira de 8x8 con 2 frames) |
| Proyectil del Cañón pesado | 8x14 (tira de 16x14) |
| Impactos de bala | 16x16 y 24x24 |
| Efectos sobre un enemigo (impacto, escarcha, muerte) | 32x32 |
| Onda del Cryo | 128x128 |
| Texturas de haz y rayo (se repiten a lo largo de una línea) | 32 px de ancho y 3 a 15 de alto |
| Tiles de espacio | 16x16, con piezas de 2x2 y 3x3 casillas |
| Fondos de espacio | 640x272; planeta gigante 224x224 |

## Paleta

Estilo propio (torres, enemigos nuevos, estación, tileset de espacio). Cada sprite usa entre 6 y 15 colores.

- **Contorno**: `#0c0e16` en torres, estación, satélite y tiles de espacio; `#0a0810` en enemigos.
- **Metal gris azulado** (rampa de 3 tonos, de sombra a luz): `#343a4a`, `#606a7c`, `#96a2b6`. En enemigos: `#2c303e`, `#545c6e`, `#8c96aa`, `#d2dceb`.
- **Morado de las naves enemigas**: `#221632`, `#462c62`, `#785096`.
- **Color de acento por torre**, usado en luces, proyectiles y efectos:

| Torre | Acento (de oscuro a claro) |
|---|---|
| Cañón doble | cian `#1c7496`, `#40e0f0`, `#befaff` |
| Cañón pesado | ámbar `#96641e`, `#ecb23c`, `#ffe082`; explosión `#dc461e`, `#ff8c32`, `#ffe28c` |
| Láser | rojo `#961432`, `#ff3c5a`, `#ffaabe` |
| Cryo | azul hielo `#245296`, `#54a0e2`, `#a6defa`, `#ecfaff` |
| Tesla | cobre `#783e20`, `#ce743c`; rayo `#5a3caa`, `#40e0f0`, `#f0faff` |
| Rail | ámbar `#ecb23c`; haz `#1c7496`, `#40e0f0`, `#f0faff` con borde `#aa78ff` |
| Disintegrator | magenta `#6e1a64`, `#be30a0`, `#ff5ad2`, `#ffafeb`, `#fff5fc` |

- **Torres fusionadas** (`assets/sprites/towers/<torre>_fusion/`, mismos tamaños, frames y nombres que la base, p. ej. `turret_fusion/t1_base.png`): misma familia que la base, más detalladas, con acento nuevo.

| Fusionada | Acento nuevo |
|---|---|
| Cañón cuádruple | verde `#1c7440`, `#3cb860`; cuatro cañones |
| Láser doble | magenta (desde el rojo); dos cañones paralelos |
| Cryo ventisca | blanco azulado; cristales diagonales |
| Cañón de asedio | rojo `#dc461e`; boca ancha, vainas laterales; impactos de 32x32 |
| Tormenta | violeta `#5a3caa`; cuatro bobinas, rayos lilas |
| Rail Gauss | cian; segundo capacitor; haz dorado de 32x15 |
| Aniquilador | dorado y blanco; aletas exteriores |

- **Motores y luces de enemigos**: `#8c1628`, `#f0323c`, `#ff8c5a`, `#ffdc78`.
- **Variantes de Dart**: mismo dibujo con el casco en azul hielo, morado, rojo o verde.
- **Escudo de la base**: `#40e0f0`, `#aaf5ff`, `#ebffff`, semitransparente.
- **Fondo de espacio**: azules y morados muy oscuros (`#0a1226`, `#14102e`, `#1e163e`, `#2a1e50`); estrellas en `#ffecc8`, `#befffa`, `#c8dcff` y blanco.
- **Interfaz** (`assets/ui/menu_theme.tres`): fondo azul casi negro y bordes de 1 px en la rampa cian. Los botones no son PNG: `ClippedBoxStyle` los pinta en código, en píxeles enteros, como una caja con las esquinas de arriba a la izquierda y de abajo a la derecha recortadas 3 px en diagonal (escalera de 1 px por fila). Sin corchetes ni `>`. Ver [ui.md](ui.md).

| Botón del tema | Fondo | Borde | Texto |
|---|---|---|---|
| Normal | `#081626` | `#1c7496` | `#cce6ff` |
| Ratón encima | `#1c5d6d` (`#081626` mezclado al 35 % con `#40e0f0`) | `#40e0f0` | `#befaff` |
| Pulsado | `#144252` (mezclado al 22 %) | `#40e0f0` | `#befaff` |
| Desactivado | `#060b14` | `#1c4a60` | `#5a7a96` |
| `DangerButton` normal | `#081626` | `#ff3c5a` | `#ff3c5a` |
| `DangerButton` ratón encima / armado | `#961432` | `#ff3c5a` | `#ffaabe` |

  Los interruptores de Opciones (variación de tema `ToggleButton`) usan el relleno del ratón encima cuando están en ON y el normal en OFF.

  Deslizadores (`HSlider`): pista `#081626` con borde `#1c7496`, parte llena `#40e0f0` y tirador de 3x7 en `#befaff` (blanco con el ratón encima). `PanelContainer` del tema: fondo `#0a0f1a` y borde `#1c7496`.

  Las opciones de las pantallas superpuestas son el mismo botón en el acento de su pantalla (fondos y bordes de `#060b14` mezclado con el acento, relleno al 35 % con el ratón encima y texto en el tono claro del acento). Los botones de las barras (pestañas, INICIAR, AUTO, flechas, torres y celdas de enemigo) tienen la misma forma con sus propios colores.

- **Panel holograma** (pausa, derrota, victoria, y en el menú principal los botones, la selección de nivel y Opciones): no es PNG; lo pinta `OverlayFrame` en código, en píxeles enteros, a partir del acento de cada pantalla (cian `#40e0f0`, rojo `#ff3c5a`, ámbar `#ecb23c`) y de su tono claro (`#befaff`, `#ffaabe`, `#ffe082`). Esquinas de arriba a la izquierda y de abajo a la derecha recortadas 6 px en diagonal. Ver [ui.md](ui.md).

| Parte | Color |
|---|---|
| Brillo exterior (1 px) | `#0a0f1a` mezclado al 25 % con el acento |
| Borde exterior (1 px) | acento |
| Hueco (1 px) | color del fondo |
| Borde interior (1 px) | `#0a0f1a` mezclado al 35 % |
| Fondo | `#0a0f1a` mezclado al 15 %, al 85 % de opacidad; líneas de barrido con una fila de cada dos un 25 % más oscura |
| Regla de marcas | `#0a0f1a` mezclado al 50 % |
| Corchetes de fuera (L de 6 px a 3 px del panel) | tono claro del acento |
| Pie ("SISTEMA EN ESPERA", "SIN SEÑAL", "MISIÓN CUMPLIDA", "SISTEMA LISTO", "SECTORES X/Y", "CONFIGURACIÓN") | `#0a0f1a` mezclado al 60 % |
- **Iconos de interfaz** (`assets/ui/`, 16x16, contorno `#0c0e16`, sombreado plano): `tab_towers.png` (cañón de artillería de perfil: base ancha abajo, torreta redonda y cañón largo inclinado hacia arriba a la derecha en pendiente 2:1, en la rampa de metal gris azulado `#343a4a`, `#606a7c`, `#96a2b6`, con un anillo cian cerca de la boca y una mirilla y dos luces cian en `#1c7496`, `#40e0f0`, `#befaff`) y `tab_waves.png` (una sola nave enemiga roja apuntando hacia abajo que ocupa casi todo el icono, alas en flecha y cabina oscura, en `#961432`, `#ff3c5a` y `#ffaabe`, con tres líneas de estela detrás, sin contorno, que se oscurecen al alejarse), los iconos de las pestañas de la barra derecha; `wave_next.png` (doble flecha ▶▶ con la rampa cian del Cañón doble, mitad superior clara y mitad inferior en sombra) y `wave_auto.png` (rayo con la rampa ámbar `#96641e`, `#ecb23c`, `#ffe082`), los controles de la pestaña Oleadas; `power_meteor.png` (roca gris en `#343a4a`, `#606a7c`, `#96a2b6` abajo a la derecha con una estela de fuego en diagonal hacia arriba a la izquierda, sin contorno, en la rampa ámbar) y `power_freeze.png` (copo de cuatro brazos con ramas cortas y diagonales junto al centro, en `#1c7496`, `#40e0f0` y centro `#befaff`), los botones de poder de la ficha.
- **Retrato del guía** (`assets/ui/guide_portrait.png`, 32x32, contorno `#0c0e16`): astronauta de busto con casco redondo en el metal claro (`#343a4a`, `#606a7c`, `#96a2b6`, `#d2dceb`, luz arriba a la izquierda), visor con la cara visible (piel `#e0a882` y sombra `#b0705a`, ojos de 1x2 en el contorno, mejillas `#e88a7a`, boca `#7a3c3c`) y franja de cristal `#1c4a60` arriba, luces cian a los lados del casco y placa de pecho con luces cian, ámbar y roja. Es el retrato del tutorial.
- **Icono de plegar** (`assets/ui/fold.png`, 8x8, sin contorno, cian `#40e0f0` con la diagonal en `#befaff`): una esquina en L arriba a la izquierda y una diagonal hacia ella; es el botón de plegar de la pausa.
- **Iconos de stat** (`assets/ui/stat_icons/`, 8x8, contorno `#0c0e16` de 1 px solo en cruz alrededor del relleno, sombreado plano), para las filas de la ficha y del resumen de partida. Cada uno combina una forma y un color propios para distinguirse a 8 px:

| Archivo | Dibujo | Colores |
|---|---|---|
| `cost.png` | moneda | ámbar `#96641e`, `#ecb23c`, `#ffe082` |
| `range.png` | anillo con punto central | cian `#40e0f0`, `#befaff` |
| `cooldown.png` | reloj con agujas oscuras | metal claro `#8c96aa`, `#d2dceb` |
| `damage.png` | estallido | rojo `#961432`, `#ff3c5a`, `#ffaabe` |
| `speed.png` | flecha a la derecha con marca de movimiento | metal claro `#8c96aa`, `#d2dceb` |
| `slow.png` | copo de nieve | hielo `#54a0e2`, `#a6defa`, `#ecfaff` |
| `duration.png` | reloj de arena | marco `#96a2b6`, cristal `#a6defa`, arena `#54a0e2` |
| `targets.png` | tres puntos (enemigos) | rojo `#961432`, `#ff3c5a` |
| `jump.png` | rayo en zigzag | `#40e0f0`, `#f0faff` |
| `pierce.png` | haz que atraviesa una placa | placa `#96a2b6`, haz `#40e0f0` y `#aa78ff` |
| `dps.png` | llama | magenta `#be30a0`, `#ff5ad2`, `#ffafeb` |
| `splash.png` | explosión en disco (daño en área) | rojo `#dc461e`, naranja `#ff8c32`, crema `#ffe28c` |
| `level_time.png` | tres barras de nivel crecientes | magenta `#be30a0`, `#ff5ad2`, `#ffafeb` |
| `health.png` | corazón | verde `#1c7440`, `#3cb860`, `#c4f5d0` |
| `reward.png` | lingote de oro | ámbar `#96641e`, `#ecb23c`, `#ffe082` |
| `wave.png` | nave enemiga mirando hacia arriba con la llama del motor (oleada alcanzada, en el resumen de partida) | morado `#221632`, `#462c62`, `#785096`; motor `#f0323c` |
| `kills.png` | calavera (enemigos destruidos, en el resumen de partida) | metal claro `#8c96aa`, `#d2dceb`; ojos en el contorno |

- **Barras laterales (tablet)**: no son PNG; `TabletFrameStyle`, `ScreenHeader`, `StatRow` y la cabecera de créditos las pintan en código, en píxeles enteros. Ver [ui.md](ui.md).

| Parte | Colores |
|---|---|
| Marco de metal | contorno `#0c0e16`; rampa del metal gris azulado: luz `#96a2b6` arriba y a la izquierda, cuerpo `#606a7c`, sombra `#343a4a` abajo y a la derecha |
| Tornillos (3x3) y rejilla de altavoz | `#343a4a`, con luz `#96a2b6` en los tornillos |
| Pantalla | líneas de barrido alternas `#08111f` y `#060d18`; corchetes de las esquinas `#40e0f0` |
| Cabeceras `// TEXTO` | texto `#40e0f0`; regla de marcas `#1c7496` |
| Pie de la barra izquierda ("MK3") | `#1c7496` |
| Ficha: esquinas del icono y etiqueta de tipo | cian `#40e0f0` en todas las torres, rojo `#f0323c` en todos los enemigos |
| Filas de stat | fondos alternos `#0b2132` y `#091d2c`; nombre `#5a7a96`; valor `#cce6ff` |
| Ficha | nombre del objetivo `#befaff`; descripción `#5a7a96` |
| Cabecera de créditos | fondo `#221e19`, borde `#96641e`, "CRÉDITOS" `#ecb23c`, cantidad `#ffe082` |
| Torre seleccionada en la tienda | borde y corchetes exteriores `#ecb23c`, fondo `#0e1626` mezclado al 25 % con ese ámbar |

- **Escáner de la ficha**: no es un PNG; `ScannerDisplay` lo pinta píxel a píxel en código (57x57, sin antialiasing), con los azules de la interfaz: disco `#0e1626`, anillos y cruz `#1c4a60`, anillo exterior `#1c7496`, marcas y ecos `#40e0f0`, barrido `#befaff`, estela `#1c7496` y `#14304a`. Ver [ui.md](ui.md).

## Contorno

- Contorno exterior de 1 px, de un solo color muy oscuro, cerrado por todo el borde de la figura. En bases de torre, iconos y estación el 100 % de los píxeles de borde son `#0c0e16`.
- En los enemigos el contorno es `#0a0810` en entre el 81 % y el 100 % del borde; el resto son llamas de motor y luces que sobresalen sin contorno.
- El mismo color oscuro separa las piezas interiores (paneles, cañones).
- Los efectos (balas de energía, haces, impactos, ondas, escarcha) no llevan contorno oscuro: su borde es el tono más saturado del acento.

## Luz y sombreado

- Sombreado plano por bloques con rampas de 3 o 4 tonos. Sin degradados ni tramado.
- Sin antialiasing en los cuerpos: los sprites de torres y enemigos no tienen píxeles semitransparentes.
- Los efectos sí usan transparencia parcial para desvanecerse.
- Las partes que emiten luz (núcleos, motores, luces de aviso) usan los tonos claros del acento.

## Animación

- Cañones de torre: `default` (reposo) y `fire_0`, `fire_1`... (disparo, sin bucle). `default` está en bucle en Cryo, Tesla, Rail y Disintegrator. El Cañón doble tiene `fire_0` y `fire_1`; el Láser solo tiene `default`. En el Disintegrator, `fire_0` a `fire_2` son un bucle por nivel de haz.
- Enemigos: Acorazado, Ariete, Nodriza, Wasp y los Dart tienen 3 frames; Nave normal y Nave agresiva, 1. Las cuatro animaciones `up`, `down`, `left` y `right` existen en todos; en los que tienen el dibujo mirando hacia arriba, el giro se hace por código.
- Los sprites de torre y enemigo se dibujan mirando hacia arriba.

## Convención de nombres

- Carpetas: `assets/sprites/<categoría>/<nombre>/`, con categorías `towers`, `enemies`, `base`, `bullets`, `planets`, `backgrounds`. Tilesets en `assets/tilesets/`.
- Minúsculas con guion bajo.
- Torres: `<prefijo>_<parte>[_<estado>][_sheet].png`.
  - Partes: `base`, `cannon`, `full_up` (icono con base y cañón), `bullet`, `beam`, `bolt`, `impact`, `muzzle`, `flash`, `wave`, `frost`, `death`.
  - Estados del cañón: `idle`, `charge`, `fire`, `pulse`, `cool`, `recover`.
  - Niveles del Disintegrator: `l1`, `l2`, `l3`.
- `_sheet`: tira horizontal de frames en una sola fila.
- `_0`, `_1`, `_2`...: frames o variantes en archivos sueltos.
- Estación: `estacion_fase_<n>_sheet.png` (fases de daño 0 a 3, 8 frames en bucle), `estacion_explosion_sheet.png` (10 frames) y `estacion_destruida.png` (1 frame).
- Enemigos nuevos: `<nombre>_<frame>.png`. Los antiguos (`ufo`, `spiked_ship`): `up.png`, `down.png`, `left.png`, `right.png`.
- Los `SpriteFrames` que agrupan estos PNG están en `resources/sprite_frames/` con el nombre de la torre o el enemigo.

## Fuente

Monogram (`assets/fonts/Monogram.ttf`) es la única fuente del juego, puesta como `default_font` en `menu_theme.tres`. Su tamaño nativo es 16 px: a 16, 32 y 48 sale nítida y a cualquier otro tamaño sale borrosa, así que solo se usan esos tres (16 el texto normal, 32 los subtítulos, 48 los títulos grandes). A 16 px cada carácter avanza 6 px y la línea mide 13 px. La importación va sin suavizado, sin hinting y sin posición subpíxel para que cada píxel de la fuente caiga en un píxel de pantalla. Tiene tildes, Ñ, €, ×, ◀, ▶, `>` y `_`.

## Otros estilos presentes

- `assets/tilesets/` (hierba, piedra, plantas, objetos, estructuras, muros): pack de exteriores en verdes oliva y marrones, con miles de colores por hoja y sombras semitransparentes. Lo usan los mapas de hierba (niveles 1, 3 y 4).
- `enemies/ufo` y `enemies/spiked_ship`: verdes (`#80b33b`, `#87bb3c`) con contorno negro grisáceo y entre 34 y 82 colores por sprite.
- `planets/`: tiras de 50 o 60 frames cuadrados de 30 a 210 px, con 3 a 11 colores y sin contorno. Se usan en el menú, reducidos por escala.
- `bullets/red_bullet.png` (16x16, 129 colores) y `bullets/bullets.png` (1536x1024).
- `base/space_station.png` (48x48, 41 colores).
- `backgrounds/fondo_1` a `fondo_6` y `fondo_nebula_1` y `_2`: 480x272, 9 a 34 colores.
- `backgrounds/espacio/fondo_nebulosa_tall.png` (640x544): la `fondo_nebulosa.png` (640x272) arriba y la misma volteada en vertical debajo, para que case consigo misma por arriba y por abajo. Generada con `scripts/tools/make_tall_nebula.gd` (`godot --headless --path . -s scripts/tools/make_tall_nebula.gd`).

## Dudas

- `CLAUDE.md` dice "Pixel art 16x16", pero ningún sprite de torre o enemigo mide 16x16: son de 24, 32 o 34 px sobre una casilla de 16.
- No he podido determinar una dirección de luz: no la he medido, y a simple vista los sprites de torre y enemigo parecen simétricos respecto a su eje vertical.
- El contorno usa dos colores casi iguales (`#0c0e16` y `#0a0810`) según sea torre o enemigo.
- Prefijos de torre que no coinciden con el nombre de su carpeta o de su recurso: `turret/t1_*`, `turret2/t2_*` (recurso `rocket_launcher`), `disintegrator/disint_*`.
- Mezcla de idiomas en los nombres: `acorazado`, `ariete`, `nodriza`, `nave_normal`, `dart_hielo` frente a `wasp`, `ufo`, `spiked_ship`, `cryo`, `rail`.
- Nombres de enemigo que no siguen `<nombre>_<frame>`: `nave_agresiva_up.png`, `nave_normal_up_1.png`, `wasp/up_0.png`.
- Nombres sin guion bajo en `planets/`: `planetagaseoso`, `planetalava1`, `planetaluna`, `planetarojo`, `saturnin`.
- Archivos que ninguna escena, recurso o script referencia: `towers/tower.png`, `bullets/bullets.png`, `backgrounds/fondo_1` a `fondo_6`, `fondo_nebula_1`, `fondo_nebula_2`, `Fondointernet.webp`, y en `planets/`: `planeta_2` a `planeta_11`, `planetagaseoso`, `planetalava` y `planetaluna`.
