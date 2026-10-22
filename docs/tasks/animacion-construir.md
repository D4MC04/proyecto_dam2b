# Animación al construir, fusionar y vender

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Las torres aparecen y desaparecen de golpe.

## Qué hay que hacer
- Al construir: escala de 0 a 1 con rebote y destello.
- Al fusionar: destello más fuerte.
- Al vender: se encoge y suelta chispas antes de desaparecer.

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/entities/Tower.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Construir, fusionar y vender una torre: cada acción tiene su animación corta.
