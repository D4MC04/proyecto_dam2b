# Reutilizar los textos flotantes

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
`FloatingText.spawn` crea un nodo por cada premio o venta; con muchas muertes se acumulan nodos y Tweens.

## Qué hay que hacer
- Hacer que `FloatingText` reutilice nodos ocultos (pool estático pequeño, con límite).
- Si se pasa del límite, reutilizar el más antiguo.
- Documentar en docs/design/ui.md.

## Archivos que toca
- scripts/entities/FloatingText.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 9 y matar muchas naves seguidas: los textos salen igual y el juego no se ralentiza.
