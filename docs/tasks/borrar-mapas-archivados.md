# Borrar los mapas archivados

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`scenes/maps/archive/` guarda mapas viejos que ningún nivel usa; generan avisos (uid duplicados) y arrastran sprites viejos.

## Qué hay que hacer
- Comprobar con grep que nada referencia `scenes/maps/archive`.
- Borrarlo (con `redesign/`) y lo que solo usaban ellos (p. ej. `space_station.png`).
- Quitar las Dudas de niveles.md y base.md que hablan de ellos.

## Archivos que toca
- scenes/maps/archive/
- docs/design/niveles.md
- docs/design/base.md

## Cómo se prueba a mano
1. Abrir el proyecto: sin errores ni avisos de uid duplicado.
2. Jugar los niveles 1 y 9.
