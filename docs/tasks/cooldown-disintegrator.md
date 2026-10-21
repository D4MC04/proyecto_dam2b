# Arreglar attack_cooldown del Disintegrator

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`disintegrator.tres` tiene `attack_cooldown = 1.0` que el código no usa (Dudas de torres.md).

## Qué hay que hacer
- Quitar el valor o hacer que el código lo use, lo que tenga sentido; documentarlo.

## Archivos que toca
- resources/turret_data/disintegrator.tres
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Disintegrator: dispara igual que antes.
