# Brillo (glow) en disparos y luces

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Láseres, rayos y luces de motor quedarían mejor con un brillo suave.

## Qué hay que hacer
- Activar glow 2D (WorldEnvironment con modo canvas o HDR 2D) solo en lo que tenga modulate > 1.
- Subir el modulate de láser, Tesla, Rail y luces de motor.
- Opción para apagarlo en Opciones.

## Archivos que toca
- scenes/Level.tscn
- scripts/autoloads/Settings.gd
- docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 5: los rayos brillan; con la opción apagada se ven como antes.
