# Estrellas: 2 por encima del 25 % de vida

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Ahora la segunda estrella se gana con más de la mitad de la vida. Se quiere que el corte esté en el 25 %.

## Qué hay que hacer
- En `GameState.stars_for_health()`:
  - 3 estrellas: ganar sin perder vida (como ahora).
  - 2 estrellas: ganar con más del 25 % de la vida (más de 25 de 100).
  - 1 estrella: ganar con el 25 % o menos.
- Que el 25 % sea una constante con nombre, no un número suelto.
- Actualizar donde se explican las estrellas en `docs/design/` (por ejemplo flujo.md › "Victoria"; buscar con Grep "estrella").

## Qué leer
- scripts/autoloads/GameState.gd › `stars_for_health()`
- docs/design/flujo.md › "Victoria"

## Archivos que toca
- scripts/autoloads/GameState.gd
- docs/design/ (las líneas que hablan del reparto de estrellas)

## Cómo se prueba a mano
1. Ganar un nivel sin perder vida: 3 estrellas.
2. Ganar con algo menos de la mitad pero más de 25 de vida (por ejemplo 40): 2 estrellas (antes daba 1).
3. Ganar con 25 o menos: 1 estrella.
