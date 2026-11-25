# Decoración de los niveles con las naves nuevas

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Algunas decoraciones de los mapas están dibujadas con sprites de naves antiguas, que ya no existen en el juego. Desentonan con las naves rediseñadas.

## Qué hay que hacer
- Localizar qué piezas del tileset de espacio usan naves antiguas. Candidatas, en `scripts/tools/map_generator.gd` (`_landmarks` y `_wrecks`, hacia la línea 345):
  - La pieza especial animada "nave estrellada" (`espacio_animados.png`, (0, 8), 3x3).
  - El "casco roto" de los restos (`espacio_rocas.png`, (6, 6), 2x2).
  - Mirar también el resto de piezas de esas dos hojas por si hay más.
- Redibujarlas con las naves nuevas (las de `scripts/tools/make_base_ships.gd`: mismo casco, paleta y estilo), **manteniendo el papel de cada pieza**: la nave estrellada sigue siendo una nave estrellada (con su animación), y el casco roto, un casco roto.
- Mantener el tamaño y la posición de cada pieza en el atlas, para que los mapas no tengan que cambiar. Si se generan con script, dejarlo en `scripts/tools/`.
- Si alguna pieza tuviera que cambiar de tamaño o de sitio en el atlas, regenerar los mapas con el generador, nunca a mano.

## Qué leer
- scripts/tools/map_generator.gd › las listas `_landmarks` y `_wrecks` (líneas ~340-360)
- docs/design/art.md › la línea de las **Naves base** (estilo de referencia) y lo que hable del tileset de espacio (sacarlo con Grep "espacio")
- docs/design/niveles.md › "Generador de mapas", punto 3 "Restos" y las piezas especiales

## Archivos que toca
- assets/tilesets/espacio/espacio_animados.png y/o espacio_rocas.png
- scripts/tools/ (si se generan con script)

## Cómo se prueba a mano
1. Jugar varios niveles y buscar la nave estrellada y los restos de casco.
2. Deberían verse con el estilo de las naves nuevas, haciendo el mismo papel que antes (nave estrellada, casco roto) y en el mismo sitio.
