# Nave nueva: Regeneradora

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Una nave que se cura sola premia concentrar el daño.

## Qué hay que hacer
- Recupera un % de vida por segundo si no recibe daño en 2 s.
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_regeneradora.gd
- resources/enemy_data/regeneradora.tres
- scripts/entities/Enemy.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Dañar una Regeneradora y dejar de disparar: su barra vuelve a subir.
