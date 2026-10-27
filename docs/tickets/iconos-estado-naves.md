# Iconos de estado en las naves

Creador: Renzo
Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
No se ve qué naves están ralentizadas, curándose o camufladas.

## Qué hay que hacer
- Icono de 5x5 px sobre la barra de vida: copo (ralentizada), cruz (curándose).
- Se quita al acabar el efecto.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/entities/HealthBar.gd
- assets/sprites/

## Cómo se prueba a mano
1. Nivel 6 con Cryo y Reparadora: las naves enseñan su icono.
