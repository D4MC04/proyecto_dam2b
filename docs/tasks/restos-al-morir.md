# Las naves se rompen en pedazos al morir

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Ahora una nave que muere desaparece sin más (solo sale el "+X €"). Que reviente en trozos que salen volando hace que matar se sienta mucho mejor.

## Qué hay que hacer
- En `Enemy.die()`, antes de liberar la nave, crear un efecto de restos colgado del padre (como `FloatingText`): 4-8 trozos cuadrados de 2-3 px sacados de los colores del sprite de la nave (o del frame actual), que salen en direcciones al azar, giran, frenan y se desvanecen en 0,5 s.
- Un destello blanco de 1 frame en el sitio y un anillo de humo pequeño (pixel art, `draw_rect`/`draw_arc` sin antialiasing).
- Más trozos y más grandes en las naves grandes (según `effect_scale()`).
- Solo al morir, no al llegar a la estación. Sigue `time_scale`.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/entities/Debris.gd (nuevo)
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 1 con un par de Cañones dobles.
2. Al morir cada nave, revienta en trocitos de sus colores que salen volando y se apagan.
3. En el nivel 4, el Acorazado suelta más trozos y más grandes.
