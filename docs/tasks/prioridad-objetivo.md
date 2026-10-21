# Elegir a quién dispara cada torre

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Las torres siempre usan el mismo criterio.

## Qué hay que hacer
- En la ficha, botón que cambia la prioridad: primera, última, más fuerte, más cercana.
- `Tower._best_enemy` usa la prioridad elegida.

## Archivos que toca
- scripts/entities/Tower.gd
- scripts/level_ui/InfoPanel.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Poner una torre en 'más fuerte': dispara a los Acorazados antes que a los Darts.
