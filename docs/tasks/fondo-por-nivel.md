# Fondo distinto por nivel

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Todos los niveles usan el mismo `SpaceBackground` y se parecen.

## Qué hay que hacer
- Que cada `LevelData` pueda elegir color de nebulosa y planeta gigante (o modulate).
- Paleta distinta por nivel (azul, rojo, verde…).

## Archivos que toca
- scripts/resources/LevelData.gd
- scenes/maps/SpaceBackground.tscn
- scripts/level/Level.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar los niveles 1, 4 y 8: cada uno tiene un fondo de color distinto.
