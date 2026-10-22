# Pantalla de estadísticas globales

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No se ve el progreso total del jugador.

## Qué hay que hacer
- Pantalla desde el menú: naves destruidas, dinero gastado, horas jugadas, torre favorita, niveles ganados.
- Guardar los totales en `GameState`.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn

## Cómo se prueba a mano
1. Jugar un nivel y abrir Estadísticas: los totales han subido.
