# Nave nueva: Portadora de drones

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ninguna nave crea enemigos mientras vive.

## Qué hay que hacer
- Cada N segundos suelta 2 drones pequeños por el mismo camino.
- Drones con su `EnemyData` (poca vida, poca recompensa).
- Que el Spawner los cuente como vivos (como los trozos de la Divisora).

## Archivos que toca
- scripts/tools/make_portadora.gd
- resources/enemy_data/portadora.tres
- resources/enemy_data/dron.tres
- scripts/level/Spawner.gd
- scripts/entities/Enemy.gd
- resources/wave_data/ (oleadas donde salga, editadas con el panel)

## Cómo se prueba a mano
1. Nivel donde salga: la Portadora suelta drones; la oleada no acaba hasta matarlos.
