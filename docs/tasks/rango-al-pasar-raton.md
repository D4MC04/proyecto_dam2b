# Ver el alcance de una torre al pasar el ratón

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Para ver el alcance de una torre colocada hay que seleccionarla.

## Qué hay que hacer
- Al pasar el ratón sobre una torre colocada, dibujar su círculo de alcance tenue (como en la colocación).
- Desaparece al salir.

## Archivos que toca
- scripts/entities/Tower.gd
- scripts/level/BuildManager.gd

## Cómo se prueba a mano
1. Colocar dos torres y pasar el ratón por encima: se ve el alcance de cada una.
