# Logros

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No hay metas fuera de ganar niveles.

## Qué hay que hacer
- 10-15 logros (ganar sin perder vida, 1000 bajas, fusionar todas las torres…).
- Guardados en `GameState`; aviso pequeño al conseguir uno y lista en el menú.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/MainMenu.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Ganar el nivel 1 sin perder vida: sale el aviso del logro y aparece en la lista.
