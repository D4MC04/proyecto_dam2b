# Nave nueva: Escudera

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una nave de apoyo que proteja a otras obliga a elegir objetivo.

## Qué hay que hacer
- Burbuja de escudo que absorbe X daño a las naves cercanas, se recarga cada pocos segundos.
- Sprite con script de `scripts/tools/`.
- Añadirla a `make_waves.gd` y la Navedex.

## Archivos que toca
- scripts/tools/make_escudera.gd
- resources/enemy_data/escudera.tres
- scripts/entities/Enemy.gd
- scripts/tools/make_waves.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Nivel donde salga: las naves junto a la Escudera tienen burbuja y aguantan más hasta que se rompe.
