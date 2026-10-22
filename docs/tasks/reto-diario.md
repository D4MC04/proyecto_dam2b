# Reto diario

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Rejugabilidad con algo nuevo cada día.

## Qué hay que hacer
- Cada día, nivel y modificador elegidos con la fecha como semilla (p. ej. 'naves +50 % vida', 'solo 3 torres').
- Mejor resultado del día guardado.

## Archivos que toca
- scripts/screens/MainMenu.gd
- scripts/autoloads/GameState.gd
- scripts/level/Level.gd

## Cómo se prueba a mano
1. Abrir el reto diario dos veces el mismo día: es el mismo nivel y modificador.
