# Revisar la importación de texturas pixel art

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Texturas con mipmaps o compresión con pérdida emborronan el pixel art y pesan más en VRAM.

## Qué hay que hacer
- Revisar los .import de assets/sprites: `compress/mode=0` (sin pérdida), `mipmaps/generate=false`.
- Comprobar que el filtro por defecto del proyecto es Nearest.
- Reimportar.

## Archivos que toca
- assets/sprites/**/*.import
- project.godot

## Cómo se prueba a mano
1. Jugar el nivel 1 a pantalla completa: los sprites se ven nítidos, sin bordes borrosos.
