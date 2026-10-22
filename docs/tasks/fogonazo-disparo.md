# Fogonazo en el cañón al disparar

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los disparos salen sin destello en la boca del cañón.

## Qué hay que hacer
- Sprite pequeño de fogonazo (2-3 frames, pixel art según art.md) que aparece en la punta del cañón al disparar.
- Usar el punto de salida de la bala que ya calcula `Tower._shoot`.

## Archivos que toca
- scripts/entities/Tower.gd
- assets/sprites/towers/
- docs/design/torres.md

## Cómo se prueba a mano
1. Colocar un Cañón doble en el nivel 1: cada disparo enseña un fogonazo breve.
