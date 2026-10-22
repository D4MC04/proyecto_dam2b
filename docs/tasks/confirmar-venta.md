# Confirmar la venta de torres caras

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Es fácil vender una torre fusionada sin querer.

## Qué hay que hacer
- Si la torre vale más de X, el primer clic en Vender cambia el texto a '¿Seguro?' y el segundo vende.

## Archivos que toca
- scripts/level_ui/InfoPanel.gd

## Cómo se prueba a mano
1. Seleccionar una torre fusionada y pulsar Vender: pide confirmación.
