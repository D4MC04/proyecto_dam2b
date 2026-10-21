# Impacto visible cuando una nave llega a la estación

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Cuando una nave llega a la estación solo baja la barra de vida. Un golpe visible hace notar cuándo se está perdiendo.

## Qué hay que hacer
- Al llegar una nave (`reached_end`): pequeña explosión en el punto de choque (reutilizar un impacto de `resources/` a escala), parpadeo del escudo y destello rojo breve de la estación.
- Temblor del mapa de 2 px durante 0,15 s (más fuerte con naves de `base_damage` alto), redondeado a píxeles enteros, que siga `time_scale` y no mueva la UI.

## Archivos que toca
- scripts/entities/Base.gd
- scripts/entities/Enemy.gd (si hace falta el punto de choque)
- scripts/level/Level.gd (temblor)
- docs/design/base.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 1 sin torres.
2. Lanzar la oleada: cada nave que llega explota contra la estación, el escudo parpadea y el mapa tiembla un poco.
