# Ajustes de importación de audio uniformes

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Cada efecto tiene su propio .import y algunos no tienen bucle o compresión adecuados.

## Qué hay que hacer
- Revisar los .import de assets/audio/effects: efectos cortos en WAV con `compress/mode=2` (QOA), largos o en bucle en OGG.
- Poner `edit/loop_mode` correcto en los que suenan en bucle (rayos, ambientes).
- Reimportar.

## Archivos que toca
- assets/audio/**/*.import

## Cómo se prueba a mano
1. Jugar un nivel con Disintegrator y Tesla: los sonidos de bucle no saltan y los cortos suenan igual.
