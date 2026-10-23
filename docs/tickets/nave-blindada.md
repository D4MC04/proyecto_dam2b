# Nave nueva: Blindada frontal

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Todas las naves reciben el mismo daño venga de donde venga.

## Qué hay que hacer
- Recibe la mitad de daño de torres que tiene delante y daño completo por detrás o de lado.
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_blindada.gd
- resources/enemy_data/blindada.tres
- scripts/entities/Enemy.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Las torres que disparan por detrás a la Blindada la matan más rápido que las de delante.
