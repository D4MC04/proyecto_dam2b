# Vitrina de torretas sobre un trozo de mapa

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
En la pestaña TORRETAS de la Navedex la torreta dispara sobre una pantalla vacía con cuadrícula. Debería verse como un recorte de un mapa del juego (rocas, gravilla, el pasillo libre y la torreta sobre su asteroide con plataforma), para que la torreta y las naves luzcan como en partida.

## Qué hay que hacer
- Solo la pestaña TORRETAS. Las naves siguen con el fondo de ahora.
- Hacer un mapa pequeño del tamaño de la vitrina con la decoración de verdad de los niveles: el fondo de `SpaceBackground` (nebulosa y estrellas), las rocas y la gravilla del `tileset.tres` y un pasillo limpio por donde pasan las naves. La torreta va encima de su asteroide con plataforma (pieza de 2x2 de las casillas de torreta). Se ve solo el trozo que rodea a la torreta, no un mapa entero.
- El mapa se genera con un script a partir de datos, nunca escribiendo `tile_map_data` a mano (CLAUDE.md). La opción más sencilla es un `.txt` propio (por ejemplo `resources/map_data/navedex.txt`) que pase por `scripts/tools/map_generator.gd` y dé una escena aparte. Si el generador no admite un mapa así de pequeño ni uno sin estación, se adapta, pero los 9 mapas de los niveles tienen que salir idénticos al regenerarlos. No se toca nada de `scenes/maps/` que ya exista.
- El camino no se dibuja: ni carriles, ni bandas, ni flechas (DESIGN.md › Decidido). Lo marca el espacio libre entre las rocas.
- El camino de las naves (`_path`) tiene que ir por el pasillo del mapa, al alcance de la torreta como ahora: 60 px o más, y el Orbitador no dispara a menos de 40.
- El borde y las escuadras cian (`_draw_border`) se quedan por encima, como un recorte en la pantalla de la tablet.
- Actualizar docs/design/menu.md › "Navedex" (la vitrina) y, si cambia el generador, docs/design/niveles.md › "Generador de mapas".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Navedex" (el punto **Vitrina**)
- docs/design/niveles.md › "Generador de mapas" y "SpaceBackground"
- scripts/screens/NavedexShowcase.gd › `_rebuild()`, `_build_turret()`, `_draw_backdrop()`
- scripts/tools/map_generator.gd › `_parse()`, `_build_map()`, `_generate()` y la cabecera con el formato del `.txt`

## Archivos que toca
- scripts/screens/NavedexShowcase.gd
- scripts/tools/map_generator.gd (si hace falta)
- resources/map_data/navedex.txt (nuevo)
- scenes/maps/NavedexMap.tscn (nueva, generada)
- docs/design/menu.md
- docs/design/niveles.md (si cambia el generador)

## Cómo se prueba a mano
1. F5, en la oficina pulsar la tablet y luego TORRETAS.
2. Ir pasando las torretas con el carrusel y las flechas de mejora.
3. Debería verse un trozo de mapa con el espacio de fondo, rocas y gravilla alrededor, la torreta sobre su asteroide con plataforma y la nave pasando por el hueco libre (sin carriles dibujados), con la torreta disparándole. En la pestaña NAVES el fondo sigue como antes.
