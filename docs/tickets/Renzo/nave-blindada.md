# Nave nueva: Blindada frontal

Estado: propuesta
Prioridad: baja
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Todas las naves reciben el mismo daño venga de donde venga.

## Qué hay que hacer
- Recibe la mitad de daño de torretas que tiene delante y daño completo por detrás o de lado.
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_blindada.gd
- resources/enemy_data/blindada.tres
- scripts/entities/Enemy.gd
- resources/wave_data/ (oleadas donde salga, editadas con el panel)

## Cómo se prueba a mano
1. Las torretas que disparan por detrás a la Blindada la matan más rápido que las de delante.
