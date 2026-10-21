# Torres que se teletransportan al colocarlas

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Ahora la torre aparece de golpe al colocarla y desaparece de golpe al venderla. Un efecto de teletransporte hace que construir se sienta mejor.

## Qué hay que hacer
- Al colocar: un haz de luz cian (`#40e0f0`, pixel art con `draw_rect`) baja desde arriba hasta la casilla en 0,15 s; la torre aparece de blanco a su color en 0,2 s, con unos píxeles que saltan alrededor.
- Al vender: la torre se vuelve blanca, se estira hacia arriba y se desvanece en 0,25 s antes de liberarse (el texto de dinero sigue igual).
- Al fusionar, el mismo efecto en la torre nueva.
- La torre no dispara hasta terminar de aparecer.

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/entities/Tower.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y entrar en el nivel 1.
2. Colocar un Cañón doble: baja un haz y la torre se materializa.
3. Venderla: se desintegra hacia arriba antes de desaparecer.
