# Chispas de vender en todas direcciones

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Al vender una torre, las chispas caen hacia abajo como si hubiera gravedad; en el espacio deberían dispersarse en todas direcciones como una mini explosión.

## Qué hay que hacer
- En `Turret.play_sell()` (`scripts/entities/Turret.gd`), el `CPUParticles2D` usa la gravedad por defecto (hacia abajo): ponerla a cero y que salgan en todas direcciones (`spread` de toda la vuelta), con una velocidad que frene un poco (`damping`) para que parezca un estallido.

## Archivos que toca
- scripts/entities/Turret.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1, colocar una torreta y venderla.
2. Las chispas deberían salir hacia todos lados desde la torreta, sin caer hacia abajo.
