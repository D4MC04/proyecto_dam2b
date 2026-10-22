# Celdas de enemigo de la pestaña de oleadas tan altas como las de torre

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
En la barra lateral, las celdas de enemigo de la pestaña de oleadas son más bajas que los botones de torre de la tienda, y las dos pestañas no casan.

## Qué hay que hacer
- Añadir margen vertical a las celdas de enemigo (`EnemyCell`) de la pestaña de oleadas para que ocupen lo mismo que los botones de torre (`TowerButton`).
- Comprobar que no se rompe el `EnemyCell` del Navedex (la misma escena, sin contador): si allí no debe cambiar, que el margen solo se aplique en la barra lateral (p. ej. desde `WaveBlock`).
- Actualizar `docs/design/ui.md`.

## Archivos que toca
- scenes/level_ui/EnemyCell.tscn y/o scripts/level_ui/EnemyCell.gd
- scripts/level_ui/WaveBlock.gd (si el margen va solo en la barra)
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y abrir la pestaña de oleadas de la barra lateral.
2. Las celdas de enemigo deberían ser igual de altas que los botones de torre de la pestaña de tienda.
3. Abrir el Archivo desde el menú: las celdas del Navedex deberían verse bien.
