# Filtro retro CRT opcional

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Un filtro de pantalla retro encaja con el pixel art.

## Qué hay que hacer
- Shader de pantalla (líneas, curvatura suave, aberración leve) en un CanvasLayer arriba de todo.
- Opción en Opciones, apagado por defecto.

## Archivos que toca
- resources/shaders/crt.gdshader
- scenes/Game.tscn
- scripts/autoloads/Settings.gd

## Cómo se prueba a mano
1. Activar el filtro: todo el juego se ve con líneas de CRT; apagarlo lo quita.
