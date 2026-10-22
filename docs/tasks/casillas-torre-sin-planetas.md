# Sustituir los planetas de las casillas de torre

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las torres se ponen sobre planetas porque la idea original era montar bases defensivas en ellos. Ahora son torretas, y un planeta no es el sitio donde pondrías una. Hay que encontrar algo más acorde (placa, plataforma, estación…) y pasar los mapas a eso.

## Qué hay que hacer
Por fases, y sin pasar a la siguiente sin el visto bueno del usuario:
1. **Lluvia de ideas**: proponer varias alternativas a los planetas (pieza de 2x2 casillas, 32x32 px), explicando cómo encaja cada una con las torretas, la estación y la decoración de los mapas.
2. **Prototipos visuales**: dibujar los sprites de las que elija el usuario (pixel art según `docs/design/art.md`) y enseñarlos en una escena de prueba o en un mapa, con torres colocadas encima.
3. **Decisión**: el usuario elige una (o pide cambios).
4. **Implementación**:
   - Meter las piezas nuevas en `tileset_espacio.tres` (sin cambiar uid ni ids existentes) y quitar las de planeta si ya no las usa nada.
   - Cambiar `scripts/tools/map_generator.gd` para que ponga la pieza nueva en las casillas de torre (hoy: capa `Planets`, con piezas distintas si están a 8 casillas o menos). Renombrar la capa y actualizar sus referencias.
   - Regenerar los 9 mapas con el generador (nada a mano).
   - Revisar textos o pistas que hablen de planetas (`scripts/level_ui/TutorialHints.gd`).
   - Borrar los prototipos que no se usen.
   - Actualizar `docs/design/niveles.md` y `docs/design/art.md`, y en `docs/DESIGN.md` la frase de "Decidido" que dice que los caminos los marca el espacio libre "entre asteroides y planetas" (el criterio no cambia, solo la palabra).

Los planetas del menú principal son decoración del fondo y no entran en este ticket.

## Archivos que toca
- assets/sprites/... (sprites nuevos)
- assets/tilesets/... y resources/tilesets/tileset_espacio.tres
- scripts/tools/map_generator.gd
- scenes/maps/levels/Level1.tscn a Level9.tscn (regenerados)
- scripts/level_ui/TutorialHints.gd
- docs/design/niveles.md, docs/design/art.md, docs/DESIGN.md

## Cómo se prueba a mano
1. Jugar los niveles 1, 5 y 9.
2. Las casillas de torre deberían verse con la pieza nueva, sin planetas, y distinguirse bien del campo de asteroides.
3. Colocar torres: deberían quedar bien encima de la pieza, y los caminos deberían seguir leyéndose igual que antes.
