# Atajos de depuración en el editor

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Probar oleadas tardías obliga a jugar todo el nivel.

## Qué hay que hacer
- Solo en builds de depuración (`OS.is_debug_build()`): teclas para +1000 de dinero, saltar oleada y ganar/perder al momento.

## Archivos que toca
- scripts/level/Level.gd

## Cómo se prueba a mano
1. Con F5 en el editor, pulsar la tecla de dinero: suma 1000. En un exportado no hace nada.
