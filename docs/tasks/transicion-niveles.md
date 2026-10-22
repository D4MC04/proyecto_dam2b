# Transición entre niveles

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al pasar al siguiente nivel o reiniciar el cambio es brusco.

## Qué hay que hacer
- Fundido o barrido estilo hiperespacio (como el del menú) al cargar un nivel.
- Reutilizar el fundido de `MainMenu` si se puede.

## Archivos que toca
- scripts/screens/Game.gd
- docs/design/flujo.md

## Cómo se prueba a mano
1. Ganar el nivel 1 y pulsar 'Siguiente nivel': hay una transición en vez de un corte.
