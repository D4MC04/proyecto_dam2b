# Área de alcance con estilo del juego

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El alcance se pinta como un círculo blanco liso (`Shape2D.draw` con `RANGE_COLOR` blanco al 15 %), igual que en el editor de Godot, y queda feo.

## Qué hay que hacer
- Pintar el alcance como un círculo con borde de 1 px pixelado en cian `#40e0f0` y un relleno cian casi transparente, en vez de `attack_range.draw(...)`.
- Que lo usen la torreta colocada (`Turret._draw`) y la vista previa al construir (`BuildManager._draw_range`), con una función compartida para no repetir el dibujo.
- Cambiar `BuildManager.RANGE_COLOR` (o sustituirlo por los dos colores nuevos).

## Archivos que toca
- scripts/entities/Turret.gd
- scripts/level/BuildManager.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1, elegir una torreta de la tienda y pasar el ratón por el mapa: el alcance se ve con borde cian pixelado y relleno tenue.
2. Colocarla y pasar el ratón por encima o seleccionarla: el mismo estilo.
3. Activar "mostrar alcance" en Opciones: todas las torretas lo enseñan con ese estilo.
