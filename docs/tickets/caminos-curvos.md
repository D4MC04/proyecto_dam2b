# Caminos curvos y naves que giran suave

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Los caminos son siempre rectos y en ángulo recto, porque los mapas se piensan por casillas, y las naves giran de golpe al llegar a cada esquina, lo que queda raro. El tileset sigue teniendo sentido para lo visual, pero los caminos no tienen por qué ir por casillas.

## Qué hay que hacer
- Caminos curvilíneos: las esquinas de cada camino pasan a ser curvas suaves (y, donde encaje, tramos curvos en vez de rectos), manteniendo casi toda la estructura de cada nivel (por dónde entra, por dónde va, dónde se divide o se junta y dónde está la estación).
- `map_generator.gd › _make_curve()` crea una `Curve2D` suave (con tangentes o puntos de control en los giros), no una línea quebrada; las naves la siguen y giran poco a poco (`Enemy` ya orienta el sprite con la tangente de la curva).
- El pasillo de espacio libre (`_rasterize()`) sigue la misma curva, para que lo que se ve coincida con por dónde van las naves. Los caminos siguen sin dibujarse (DESIGN.md › "Decidido").
- Si hace falta, ampliar el formato de `resources/map_data/*.txt` (por ejemplo, radio de giro o puntos de control) y documentarlo en la cabecera del generador.
- Regenerar con el generador los 9 niveles y los mapas de la Navedex (`navedex*.txt`); no escribir `tile_map_data` a mano. Comprobar que los huecos de torreta siguen fuera del pasillo y que los caminos que comparten tramo siguen pasando por los mismos puntos.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Mapa", "Mapas de los niveles" y "Generador de mapas"
- scripts/tools/map_generator.gd › cabecera (formato), `_parse()`, `_build_map()`, `_rasterize()`, `_make_curve()`, `_find_entrances()`, `_place_lights()`
- scripts/entities/Enemy.gd › movimiento por `progress` y giro con la tangente
- resources/map_data/level_1.txt a level_9.txt

## Archivos que toca
- scripts/tools/map_generator.gd
- resources/map_data/*.txt
- scenes/maps/levels/Level1.tscn a Level9.tscn y los mapas de la Navedex (regenerados)
- scripts/entities/Enemy.gd (si el giro necesita ajuste)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar los niveles 1, 3 y 9 y lanzar oleadas.
2. Los pasillos se ven curvos en los giros y las naves giran suave, sin cambiar de dirección de golpe.
3. Cada nivel se reconoce igual que antes (mismas entradas, ramas y estación) y las naves siguen el pasillo sin salirse.
