# Nave nueva: Minadora

Creador: Renzo
Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ninguna nave ataca el terreno de construcción.

## Qué hay que hacer
- Al pasar junto a una casilla libre deja una mina que impide construir ahí durante N s (o hasta destruirla con un clic).
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_minadora.gd
- resources/enemy_data/minadora.tres
- scripts/entities/Enemy.gd
- scripts/level/Grid.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Tras pasar la Minadora hay minas en casillas libres y no se puede construir en ellas.
