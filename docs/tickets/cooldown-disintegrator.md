# Arreglar attack_cooldown del Disintegrator

Creador: Renzo
Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`disintegrator.tres` tiene `attack_cooldown = 1.0` que el código no usa (Dudas de torretas.md).

## Qué hay que hacer
- Quitar el valor o hacer que el código lo use, lo que tenga sentido; documentarlo.

## Archivos que toca
- resources/turret_data/disintegrator.tres
- docs/design/torretas.md

## Cómo se prueba a mano
1. Colocar un Disintegrator: dispara igual que antes.
