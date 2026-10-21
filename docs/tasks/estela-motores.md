# Estela de los motores de las naves

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Las naves se deslizan por el camino sin nada detrás. Una estela de motor les da sensación de velocidad y se ve muy espacial.

## Qué hay que hacer
- Cada nave deja detrás una estela corta de píxeles (2-4 px que se apagan en 0,3 s), en la dirección contraria a su movimiento.
- Color por nave con un campo nuevo `trail_color` en `EnemyData` (por defecto cian claro); rellenarlo en las 12 `resources/enemy_data/*.tres` con un color a juego con su sprite.
- Las rápidas (Dart, Wasp) con estela más larga; las lentas (Acorazado, Spikey), más corta.
- Al ralentizarse (Cryo/congelar) la estela se acorta.
- Barato: sin `GPUParticles2D` por nave, pintado con `_draw` o un `Line2D` corto.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/resources/EnemyData.gd
- resources/enemy_data/*.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 2.
2. Cada nave lleva una estela de su color detrás; los Dart, más larga.
3. Con un Cryo cerca, la estela se acorta al frenarse.
