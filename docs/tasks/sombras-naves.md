# Sombra bajo las naves

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Las naves parecen pegadas al fondo.

## Qué hay que hacer
- Copia del sprite en negro al 30 % y desplazada 3 px abajo a la derecha, detrás de cada nave.
- Que siga la rotación y el camuflaje del Espectro.

## Archivos que toca
- scripts/entities/Enemy.gd
- scenes/entities/Enemy.tscn

## Cómo se prueba a mano
1. Jugar el nivel 2: cada nave lleva una sombra suave que se mueve con ella.
