# Números de daño opcionales

Creador: Renzo
Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No se ve cuánto daño hace cada torreta.

## Qué hay que hacer
- Número pequeño que sube y se desvanece al recibir daño una nave (agrupar golpes muy seguidos).
- Opción en Opciones, apagada por defecto.
- Reutilizar `FloatingText`.

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/entities/FloatingText.gd
- scripts/autoloads/Settings.gd

## Cómo se prueba a mano
1. Activar la opción: cada golpe enseña su daño; apagada no sale nada.
