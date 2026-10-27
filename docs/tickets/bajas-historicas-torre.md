# Bajas históricas de cada torre en la Navedex

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
`bajas-por-torre` cuenta las bajas de cada torre en una partida, pero al salir se pierden. Ver en la ficha de cada torre de la Navedex cuántas naves ha destruido en total ayuda a saber cuál rinde más.

## Qué hay que hacer
- Al morir una nave por una torre, sumar 1 a `GameState.add_stat("kills_<torre>")` (mismo nombre de archivo que usa `built_<torre>`). Las fusiones cuentan aparte, con su propio nombre.
- En la ficha de una torre en la Navedex (pestaña Torres), una fila "BAJAS TOTALES" con ese contador.
- "Borrar progreso" ya borra los contadores de `stats`; comprobarlo.

## Archivos que toca
- scripts/entities/Tower.gd (o donde se registra la baja de la torre)
- scripts/screens/Navedex.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Jugar un nivel con un Cañón doble y matar varias naves.
2. Menú → ARCHIVO → Torres → Cañón doble: "BAJAS TOTALES" enseña las bajas.
3. Jugar otra vez: el número sigue sumando.
