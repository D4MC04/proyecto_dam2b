# Torres apagadas por EMP más visibles

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Las torres apagadas solo se oscurecen; con muchas en pantalla cuesta verlas.

## Qué hay que hacer
- Chispas intermitentes y pequeño contador circular del tiempo que falta.
- Reutilizar `EmpSparks`.

## Archivos que toca
- scripts/entities/Tower.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Nivel 8: cuando una Saboteadora apaga torres, se ven chispas y el tiempo restante.
