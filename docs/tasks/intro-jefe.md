# Entrada de la Nodriza más espectacular

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La Nodriza sale con el `BossAlert` pero sin presentación en el mapa.

## Qué hay que hacer
- Al salir: el portal se agranda, la pantalla oscurece un poco y la cámara tiembla.
- Barra de vida grande del jefe arriba mientras viva.

## Archivos que toca
- scripts/level/Spawner.gd
- scripts/level_ui/BossAlert.gd
- scripts/entities/Portal.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Llegar a la última oleada del nivel 6: la Nodriza sale con su entrada y su barra de vida.
