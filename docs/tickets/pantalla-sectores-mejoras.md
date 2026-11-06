# Mejorar la pantalla de sectores

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La pantalla de sectores (radar y ficha) tiene que verse mejor.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario cómo está la pantalla y preguntarle qué mejoras quiere. Hacer solo esas.
- No cambiar el modo corrupto del jefe (es el ticket `radar-corrupto-jefe`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Escena y script" (`LevelSelectionScreen`), "Radar de sectores" y "Ficha"
- scripts/level_ui/SectorRadar.gd
- scripts/level_ui/SectorCard.gd

## Archivos que toca
- scripts/level_ui/SectorRadar.gd
- scripts/level_ui/SectorCard.gd
- scenes/MainMenu.tscn (`LevelSelectionScreen`)
- scripts/screens/MainMenu.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar a la oficina y pulsar la mesa de sectores.
2. Se ven las mejoras que pidió el usuario y se puede seguir eligiendo y desplegando un sector.
