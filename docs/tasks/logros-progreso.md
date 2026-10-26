# Progreso de los logros por contador

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
En la pestaña LOGROS solo se ve `[ ]` o `[X]`. En los logros de contador (Cazador, Exterminador, Veterano, Constructor, Defensa perfecta, Observador) no se sabe cuánto falta.

## Qué hay que hacer
- En `GameState`, una función que devuelva el progreso de un logro (actual y meta) para los que dependen de un contador; `null` para los demás.
- En la lista de LOGROS de la Navedex, enseñar "340/1000" al lado de los logros no conseguidos que tengan contador.
- No cambiar qué logros hay ni cuándo se consiguen.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/Navedex.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Menú → ARCHIVO → LOGROS.
2. "Cazador" sin conseguir debe enseñar algo como "12/100".
3. Jugar un nivel, matar naves y volver: el número ha subido. Al llegar a 100 sale `[X]` y deja de verse el contador.
