# Borrar imágenes sin uso

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Hay sprites que no usa nada: `backgrounds/Fondointernet.webp`, `base/space_station.png` (solo mapas archivados) y quizá algunos `fondo_*.png`.

## Qué hay que hacer
- Listar los .png/.webp de assets/sprites que no aparecen en ningún .tscn/.tres/.gd (grep por nombre y por uid de su .import).
- Enseñar la lista al usuario y borrar los confirmados con su .import.

## Archivos que toca
- assets/sprites/**

## Cómo se prueba a mano
1. Abrir el proyecto y jugar el nivel 1: sin avisos de recurso perdido.
