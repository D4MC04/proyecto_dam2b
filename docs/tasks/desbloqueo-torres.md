# Desbloqueo de torres con pantalla de novedad

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Las torres nuevas aparecen sin presentación.

## Qué hay que hacer
- Al entrar en el primer nivel que trae una torre nueva, panel corto que la presenta (sprite, nombre, para qué sirve).

## Archivos que toca
- scripts/level_ui/LevelUI.gd
- scripts/autoloads/GameState.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Entrar por primera vez al nivel 2: sale la presentación de la Cryo; la segunda vez no.
