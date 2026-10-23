# Quitar UFO y Spikey

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El UFO (`ufo`) y el Spikey (`spiked_ship`) se quitan del juego, junto con todo lo que los usa.

## Qué hay que hacer
- Borrar `resources/enemy_data/ufo.tres` y `spiked_ship.tres`, `resources/sprite_frames/ufo.tres` y `spiked_ship.tres`, `resources/collision_shapes/ufo.tres` y `spiked_ship.tres`, las carpetas `assets/sprites/enemies/ufo` y `spiked_ship`, y los sonidos `assets/audio/effects/SpaceShips/UFO` y `SpikedUFO` (con sus `.import`). Antes, comprobar con Grep que nada más los usa.
- `scripts/tools/make_waves.gd`: quitar `ufo` y `spiked_ship` de las listas `new` y `old` de cada nivel y volver a generar `resources/wave_data/*.tres` con el script (no editarlos a mano).
- `scripts/screens/Navedex.gd`: quitarlos de `ENEMY_FILES`.
- `scripts/main_menu/Skirmish.gd`: quitar el UFO de `SHIPS` (fondo del menú).
- Mirar si `GameState` guarda algo de esas naves en `progress.cfg` (naves vistas, logros) y que no falle si quedan sus ids en un guardado viejo.

## Archivos que toca
- resources/enemy_data/, resources/sprite_frames/, resources/collision_shapes/, resources/wave_data/
- assets/sprites/enemies/, assets/audio/effects/SpaceShips/
- scripts/tools/make_waves.gd
- scripts/screens/Navedex.gd
- scripts/main_menu/Skirmish.gd
- docs/design/enemigos.md, docs/design/niveles.md (nivel 2: solo Nave normal como nueva), docs/design/art.md

## Cómo se prueba a mano
1. Lanzar el juego: en el fondo del menú no debería cruzar ningún UFO.
2. Archivo > Naves: no salen UFO ni Spikey.
3. Jugar los niveles 2 y 3 unas oleadas: salen naves normales y agresivas, sin UFO ni Spikey, y sin errores en la salida.
