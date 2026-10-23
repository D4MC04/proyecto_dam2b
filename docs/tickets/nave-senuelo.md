# Nave nueva: Señuelo

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Las torres siempre eligen bien el objetivo.

## Qué hay que hacer
- Nave que atrae el fuego de las torres cercanas (prioridad máxima) y tiene mucha vida pero no daña la estación.
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_senuelo.gd
- resources/enemy_data/senuelo.tres
- scripts/entities/Tower.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Mientras el Señuelo está cerca, las torres le disparan a él.
