# Barras de vida de los enemigos

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No se ve cuánta vida le queda a cada nave; con la Nodriza, el Acorazado o la Escudera no se sabe si las torres van a poder con ellas antes de que lleguen.

## Qué hay que hacer
- Requiere `habilidades-naves-base` en main (los dos tocan `Enemy.gd`).
- Encima de cada nave, una barra fina en pixel art (2 px de alto y ancho según el tamaño del sprite, con `effect_scale()`), pintada con `draw_rect` sin antialiasing:
  - Fondo oscuro `#14060a`.
  - Relleno verde con más de la mitad de vida, ámbar `#ecb23c` por debajo de la mitad y rojo `#f0323c` por debajo del 25 %.
  - Contorno de 1 px negro.
- Solo se ve cuando la nave ha recibido daño (con la vida llena, oculta), y sube cuando la curan (`Enemy.heal`, de la Reparadora).
- Si la nave tiene escudo (habilidad Escudo), una segunda línea cian de 1 px encima con lo que le queda de escudo.
- No gira con el sprite (naves con `rotate_sprite`): siempre horizontal encima. Se quita al morir.

## Archivos que toca
- scripts/entities/Enemy.gd (o un `HealthBar.gd` nuevo que cuelga de la nave)
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 4 (sale el Acorazado y la Escudera).
2. Colocar un Cañón doble junto al camino y lanzar la oleada.
3. Las naves salen sin barra; al recibir el primer disparo aparece encima una barra que baja con cada golpe, cambia de verde a ámbar y a rojo, y no gira con la nave.
4. La Escudera enseña además una línea cian con su escudo.
