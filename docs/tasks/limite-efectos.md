# Límite de efectos simultáneos

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Con muchas explosiones, curaciones y destellos a la vez puede bajar el framerate en equipos modestos.

## Qué hay que hacer
- Contar efectos vivos (`Effect`, `HealEffect`, `EmpSparks`) y no crear más de N (constante) a la vez; los sobrantes se omiten.
- Añadir la opción 'Efectos: altos/bajos' en Opciones si es sencillo.

## Archivos que toca
- scripts/Effect.gd
- scripts/entities/HealEffect.gd
- scripts/autoloads/Settings.gd

## Cómo se prueba a mano
1. Nivel 9 con muchas naves muriendo a la vez: el juego no se atasca y los efectos se siguen viendo.
