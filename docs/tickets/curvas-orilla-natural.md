# Orilla de las curvas más natural

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La forma de las curvas ya es la buena, pero su orilla es una fila de rocas pequeñas puestas una tras otra: se nota que está dibujada a propósito y rompe la inmersión. Queremos la misma forma hecha con elementos variados, para que los mapas parezcan campos de asteroides creíbles.

## Qué hay que hacer
- Mantener la forma y el margen de las curvas: lo opaco más cercano al centro del camino, a la misma distancia que en las rectas (24 px al píxel; ninguna roca a menos de `BEND_EDGE_MIN` del camino, contando su centro).
- Cambiar `map_generator.gd › _place_bend_edges()` para que la orilla no sea una fila uniforme de rocas de 1x1. Mezclar elementos: rocas de 2x2 (y de 3x3 donde quepan, en el lado de fuera) cuyo borde siga la curva, rocas pequeñas, piedrecitas, algo de chatarra y de las familias de roca de la zona y su pareja. Variar el espaciado (algún hueco pequeño, algún grupo más apretado) sin que la curva deje de leerse.
- Que el lado de dentro de las curvas cerradas (las puntas de las franjas en las U) quede como una roca o un grupo que acaba en punta redondeada, no como una cadena de piedras.
- Que la orilla de una curva enlace sin salto con la de los tramos rectos de antes y después (misma densidad y tipo de piezas).
- No mover las casillas de torreta ni los caminos; las reglas de `_check_slots()` siguen igual.
- Regenerar los 9 niveles, el de emergencia y los mapas de la Navedex con el generador; no escribir `tile_map_data` a mano.
- Comprobar con un render real de cada nivel (piezas de verdad, con una torreta en cada casilla y naves a lo largo de los caminos) que las curvas se leen igual de bien que ahora y que la holgura no baja.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Mapas de los niveles" y "Generador de mapas"
- docs/design/art.md › "Alternativas del tileset de espacio" (piezas desplazadas del atlas de rocas)
- scripts/tools/map_generator.gd › constantes `BEND_EDGE_*`, `_place_bend_edges()`, `_path_distance()`, `_put()`, `_jitter()`, `_place_medium()`, `_place_small()`, `_fill_holes()`

## Archivos que toca
- scripts/tools/map_generator.gd
- scenes/maps/levels/Level1.tscn a Level9.tscn, Emergency.tscn y scenes/maps/Navedex*Map.tscn (regenerados)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar los niveles 1, 3 y 7 y mirar todas las curvas, sobre todo las U.
2. Cada curva se ve con su forma, pero con rocas de varios tamaños y algo de variedad, sin parecer una línea de piedras puesta a mano.
3. Con torretas en las casillas cercanas y una oleada lanzada, las naves siguen sin pisar rocas ni torretas.
