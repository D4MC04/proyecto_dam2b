# Nave nueva: Escudera

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una nave de apoyo que proteja a otras obliga a elegir objetivo.

## Qué hay que hacer
- Burbuja de escudo que absorbe X daño a las naves cercanas, se recarga cada pocos segundos.
- Sprite con script de `scripts/tools/`.
- Añadir la nave a las oleadas con el panel de balanceo (pestaña Niveles) y a la Navedex.

## Archivos que toca
- scripts/tools/make_escudera.gd
- resources/enemy_data/escudera.tres
- scripts/entities/Enemy.gd
- resources/wave_data/ (oleadas donde salga, editadas con el panel)
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Nivel donde salga: las naves junto a la Escudera tienen burbuja y aguantan más hasta que se rompe.
