# Quitar los brillos azules de los carriles

Estado: aceptada
Espera a: mini-arreglos-nivel-1
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Por el centro de los pasillos por donde pasan las naves salen unos brillos azules que marcan el camino. Sobran: el camino ya se ve por el espacio libre entre los asteroides (DESIGN.md › "Decidido": los caminos no se dibujan).

## Qué hay que hacer
- Antes de tocar nada, comprobar en el juego que los brillos son las luces de la capa `Lights` (piezas animadas `LIGHTS_HORIZONTAL` / `LIGHTS_VERTICAL` del tileset de espacio). Si no lo son, parar y preguntar al usuario.
- En `scripts/tools/map_generator.gd`, quitar la capa `Lights`: `_place_lights()`, las constantes `LIGHTS_HORIZONTAL` y `LIGHTS_VERTICAL` y la creación de la capa en el armado del mapa. Comprobar con Grep que nada más las usa.
- Regenerar los mapas con el script (`godot --headless --path . -s scripts/tools/map_generator.gd -- N` para cada nivel y la emergencia, si también la genera). No escribir `tile_map_data` a mano ni borrar el nodo a mano. No cambiar `uid` ni ids.
- Las piezas de luz del tileset se pueden quedar si las usa otra cosa; si no las usa nada, dejarlas igual (no tocar el tileset).
- docs/design/niveles.md: quitar `Lights` de la tabla de capas y el punto de "En `Lights`…".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › la tabla de capas de los mapas y la lista de lo que pone el generador (punto de `Lights`)
- scripts/tools/map_generator.gd › `_place_lights()`, `LIGHTS_HORIZONTAL`, `LIGHTS_VERTICAL` y donde se llama a `_add_layer(map, "Lights", ...)`

## Archivos que toca
- scripts/tools/map_generator.gd
- scenes/maps/levels/Level1.tscn … Level9.tscn (y Emergency.tscn si lo genera el script)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar los niveles 1 y 2: el pasillo por donde pasan las naves debería verse limpio y oscuro, sin brillos azules.
2. El resto del mapa (rocas, gravilla, estrellas que parpadean en el campo, casillas de torreta) debería verse igual que antes.
