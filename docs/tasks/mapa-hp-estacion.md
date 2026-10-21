# Vida de la estación según el nivel

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
La estación tiene la misma vida en todos los niveles aunque los últimos son mucho más duros.

## Qué hay que hacer
- Campo `base_health` en `LevelData` (por defecto el actual) y que `Base` lo use.
- Ajustarlo en los niveles 7-9 si hace falta.

## Archivos que toca
- scripts/resources/LevelData.gd
- scripts/entities/Base.gd
- resources/level_data/*.tres

## Cómo se prueba a mano
1. Poner otra vida en el nivel 9: la estación empieza con ese valor.
