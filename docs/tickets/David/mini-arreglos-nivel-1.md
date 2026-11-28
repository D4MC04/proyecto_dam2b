# Mini arreglos del nivel 1

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Retoques pequeños del nivel 1 que el usuario explica al empezar la tarea, con capturas como referencia visual.

## Qué hay que hacer
- Al empezar, no tocar nada: pedir al usuario las capturas y la lista de arreglos y esperar.
- Hacer solo lo que explique. Si algo contradice "Decidido" de docs/DESIGN.md, parar y avisar.
- El mapa se genera con su script: no escribir `tile_map_data` a mano.
- Actualizar docs/design/niveles.md › "Nivel 1" con lo que cambie.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › la sección del nivel 1 y la de su mapa
- Lo que haga falta según lo que pida el usuario

## Archivos que toca
- Según lo que pida el usuario (seguramente el script del mapa del nivel 1, `resources/level_data/level_1.tres` y `resources/wave_data/level_1*.tres`)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1 (`/test` con `--level=1`).
2. Comprobar uno a uno los arreglos que explicó el usuario, con sus capturas al lado.
