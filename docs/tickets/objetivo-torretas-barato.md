# Búsqueda de objetivo más barata en las torretas

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
`Turret._best_enemy` recorre todos los enemigos en rango cada vez que dispara; en niveles con muchas naves se nota.

## Qué hay que hacer
- Medir con el Profiler en el nivel 9.
- Guardar el mejor objetivo y recalcularlo solo cuando entra o sale un enemigo o muere el actual (`_on_area_entered`/`_exited`).
- No cambiar el criterio de elección.

## Archivos que toca
- scripts/entities/Turret.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Nivel 9 con muchas torretas: las torretas apuntan a las mismas naves que antes y el tiempo de `_process` baja en el Profiler.
