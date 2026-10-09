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
| Estación y escudo | 64x64 |
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

- **Motores y luces de enemigos**: `#8c1628`, `#f0323c`, `#ff8c5a`, `#ffdc78`.
- **Variantes de Dart**: mismo dibujo con el casco en azul hielo, morado, rojo o verde.
- **Escudo de la base**: `#40e0f0`, `#aaf5ff`, `#ebffff`, semitransparente.
- **Fondo de espacio**: azules y morados muy oscuros (`#0a1226`, `#14102e`, `#1e163e`, `#2a1e50`); estrellas en `#ffecc8`, `#befffa`, `#c8dcff` y blanco.
- **Interfaz** (`assets/ui/menu_theme.tres`): fondo azul casi negro (`Color(0.04, 0.06, 0.1)`), bordes de 1 px en cian (`#00ffff`), más claro al pasar el ratón y más oscuro al pulsar.

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
- Enemigos nuevos: `<nombre>_<frame>.png`. Los antiguos (`ufo`, `spiked_ship`): `up.png`, `down.png`, `left.png`, `right.png`.
- Los `SpriteFrames` que agrupan estos PNG están en `resources/sprite_frames/` con el nombre de la torre o el enemigo.

## Otros estilos presentes

- `assets/tilesets/` (hierba, piedra, plantas, objetos, estructuras, muros): pack de exteriores en verdes oliva y marrones, con miles de colores por hoja y sombras semitransparentes. Lo usan los mapas de hierba (niveles 1, 3 y 4).
- `enemies/ufo` y `enemies/spiked_ship`: verdes (`#80b33b`, `#87bb3c`) con contorno negro grisáceo y entre 34 y 82 colores por sprite.
- `planets/`: tiras de 50 o 60 frames cuadrados de 30 a 210 px, con 3 a 11 colores y sin contorno. Se usan en el menú, reducidos por escala.
- `bullets/red_bullet.png` (16x16, 129 colores) y `bullets/bullets.png` (1536x1024).
- `base/space_station.png` (48x48, 41 colores).
- `backgrounds/fondo_1` a `fondo_6` y `fondo_nebula_1` y `_2`: 480x272, 9 a 34 colores.

## Dudas

- `CLAUDE.md` dice "Pixel art 16x16", pero ningún sprite de torre o enemigo mide 16x16: son de 24, 32 o 34 px sobre una casilla de 16.
- No he podido determinar una dirección de luz: no la he medido, y a simple vista los sprites de torre y enemigo parecen simétricos respecto a su eje vertical.
- El contorno usa dos colores casi iguales (`#0c0e16` y `#0a0810`) según sea torre o enemigo.
- Prefijos de torre que no coinciden con el nombre de su carpeta o de su recurso: `turret/t1_*`, `turret2/t2_*` (recurso `rocket_launcher`), `disintegrator/disint_*`.
- Mezcla de idiomas en los nombres: `acorazado`, `ariete`, `nodriza`, `nave_normal`, `dart_hielo` frente a `wasp`, `ufo`, `spiked_ship`, `cryo`, `rail`.
- Nombres de enemigo que no siguen `<nombre>_<frame>`: `nave_agresiva_up.png`, `nave_normal_up_1.png`, `wasp/up_0.png`.
- Nombres sin guion bajo en `planets/`: `planetagaseoso`, `planetalava1`, `planetaluna`, `planetarojo`, `saturnin`.
- Archivos que ninguna escena, recurso o script referencia: `towers/tower.png`, `bullets/bullets.png`, `backgrounds/fondo_1` a `fondo_6`, `fondo_nebula_1`, `fondo_nebula_2`, `Fondointernet.webp`, y en `planets/`: `planeta_2` a `planeta_11`, `planetagaseoso`, `planetalava` y `planetaluna`.
