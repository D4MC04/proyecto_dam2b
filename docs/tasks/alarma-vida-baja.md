# Alarma de vida baja

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Cuando la estación está a punto de caer no hay aviso claro.

## Qué hay que hacer
- Por debajo del 25 % de vida, viñeta roja que late en los bordes de la pantalla.
- Se apaga si la vida vuelve a subir o al acabar el nivel.

## Archivos que toca
- scripts/level_ui/LevelUI.gd
- scenes/level_ui/LevelUI.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. Dejar pasar naves hasta bajar del 25 %: aparece la viñeta roja que late.
