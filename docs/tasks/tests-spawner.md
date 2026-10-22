# Pruebas automáticas del Spawner

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
No hay pruebas: un cambio en oleadas se descubre jugando.

## Qué hay que hacer
- Script headless en `scripts/tools/` que monta el `Spawner` con caminos de prueba y comprueba orden, conteo de vivos, `wave_cleared` y que las oleadas no se solapan.
- Sale con código de error si falla.

## Archivos que toca
- scripts/tools/test_spawner.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Ejecutar `godot --headless -s scripts/tools/test_spawner.gd`: dice OK.
