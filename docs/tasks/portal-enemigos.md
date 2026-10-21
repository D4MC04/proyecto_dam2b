# Portal de aparición de los enemigos

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Ahora las naves aparecen de golpe en el borde del mapa. Un portal que se abre al empezar la oleada y del que salen las naves da sensación de invasión y avisa de por dónde vienen.

## Qué hay que hacer
- Crear `Portal` (`scripts/entities/Portal.gd`, `Node2D`): anillo en pixel art morado y cian (paleta de `docs/design/art.md`) pintado con `draw_*` sin antialiasing, o con un sprite nuevo de 32x32 en `assets/`. Gira despacio y late.
- Al recibir `wave_started`, abrir un portal al principio de cada camino que use esa oleada (los `path_index` de sus entradas): crece de 0 a su tamaño en 0,3 s.
- Cada enemigo nuevo (`Spawner._spawn`) sale del portal: empieza a escala 0 y crece hasta 1 en 0,2 s, con un destello.
- Al recibir `wave_spawn_finished`, el portal se cierra (encoge en 0,3 s) y se libera.
- Que siga `Engine.time_scale` (×2) y se pare con la pausa.

## Archivos que toca
- scripts/level/Spawner.gd
- scripts/entities/Portal.gd (nuevo)
- scripts/entities/Enemy.gd (animación de entrada)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 2 (tiene varios caminos).
2. Pulsar INICIAR: al principio de cada camino que se use se abre un portal girando.
3. Las naves salen del portal creciendo; cuando sale la última, el portal se cierra.
