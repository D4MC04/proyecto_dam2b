# Las torres apuntan al enemigo más cerca de la estación

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
Las torres eligen objetivo por `progress` (distancia recorrida en su propio camino). En mapas con varios caminos de distinta longitud eso no es "el que antes llega a la estación", y las torres pueden ignorar al enemigo peligroso (docs/design/torres.md, "Dudas").

## Qué hay que hacer
- Elegir objetivo por distancia que le falta: `longitud del camino - progress` (la longitud sale de la `Curve2D` del camino, `get_baked_length()`).
- Darle a `Enemy` una función tipada `get_remaining_distance() -> float` y usarla en `Tower.gd` en lugar de `progress`.
- Quitar esa duda de docs/design/torres.md y describir el criterio nuevo.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/entities/Tower.gd
- docs/design/torres.md, docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y entrar a un nivel con dos caminos de distinta longitud (ver docs/design/niveles.md).
2. Poner una torre donde alcance los dos caminos.
3. Lanzar oleada: la torre debe disparar al enemigo que está más cerca de la estación, aunque haya recorrido menos.
