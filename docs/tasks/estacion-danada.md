# Estación con daños visibles

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La estación se ve igual con toda la vida que a punto de caer.

## Qué hay que hacer
- 2-3 estados de sprite (grietas, humo, chispas) según el porcentaje de vida.
- Hacer los sprites con un script de `scripts/tools/` siguiendo art.md.

## Archivos que toca
- scripts/entities/Base.gd
- assets/sprites/base/
- scripts/tools/make_station_damage.gd
- docs/design/base.md

## Cómo se prueba a mano
1. Dejar pasar naves en el nivel 1: la estación se ve más rota al bajar su vida.
