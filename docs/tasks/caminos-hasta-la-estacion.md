# Que los enemigos lleguen hasta la estación

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los caminos terminan antes de la estación: en el nivel 1 el camino acaba en (376, 216) y la estación está en (440, 216) (docs/design/base.md, "Dudas"). Los enemigos desaparecen a 64 px de la estación y parece que la estación pierde vida por nada.

## Qué hay que hacer
- En los mapas que usan los niveles (`scenes/maps/Level1.tscn`, `Level3.tscn`, `Level4.tscn`, `espacio/Level2_espacio.tscn`, `espacio/Level5_espacio.tscn`, `espacio/Level6_espacio.tscn`), mirar dónde acaba cada `Path2D` y dónde está la `Base`.
- Alargar el último punto de cada camino hasta el borde de la estación, editando solo los puntos de la curva. No tocar `tile_map_data` ni ningún `uid=`.
- Si en algún mapa la estación no está al final de los caminos, no tocarlo y apuntarlo en el resumen.
- Quitar la duda de docs/design/base.md y apuntar qué mapas se han cambiado en docs/design/niveles.md.

## Archivos que toca
- scenes/maps/Level1.tscn, Level3.tscn, Level4.tscn
- scenes/maps/espacio/Level2_espacio.tscn, Level5_espacio.tscn, Level6_espacio.tscn
- docs/design/base.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5) y entrar al nivel 1 sin poner torres.
2. Lanzar una oleada: los enemigos llegan pegados a la estación y justo ahí desaparecen y baja la barra ESTACIÓN.
3. Repetir en los niveles 2 a 6 que tengas desbloqueados.
