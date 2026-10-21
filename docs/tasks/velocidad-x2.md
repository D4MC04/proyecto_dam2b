# Botón de velocidad x2

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Las primeras oleadas se hacen lentas.

## Qué hay que hacer
- Botón junto a AUTO que alterna `Engine.time_scale` entre 1 y 2.
- Volver a 1 en pausa, al perder, ganar o salir.

## Archivos que toca
- scripts/level_ui/LevelUI.gd
- scripts/level_ui/Sidebar.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Pulsar x2: todo va al doble; al pausar y salir vuelve a velocidad normal.
