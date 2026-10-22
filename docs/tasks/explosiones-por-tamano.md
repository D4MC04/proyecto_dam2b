# Explosiones según el tamaño de la nave

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Todas las naves mueren con el mismo efecto; un Acorazado debería estallar más que un Dart.

## Qué hay que hacer
- Escalar el efecto de muerte y el destello según el tamaño o el `hp` de la nave.
- Para naves grandes (Acorazado, Nodriza), varias explosiones pequeñas seguidas.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/Effect.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Nivel 4: matar un Dart y un Acorazado; el del Acorazado es claramente mayor.
