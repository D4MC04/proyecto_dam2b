# Bajas y daño de la ficha en vivo

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Las filas BAJAS y HECHO de la ficha de una torre colocada solo se rellenan al seleccionarla. Si la torre sigue disparando con la ficha abierta, los números se quedan viejos y hay que volver a hacer clic.

## Qué hay que hacer
- Que `Tower` avise (señal) cuando cambian sus bajas o su daño.
- Mientras esa torre es la seleccionada (`LevelState.sellable_tower`), la ficha actualiza solo esas dos filas, sin rehacer la ficha entera ni repetir el destello de cambio.
- Al seleccionar otra cosa, dejar de escuchar a la torre anterior.

## Archivos que toca
- scripts/entities/Tower.gd
- scripts/level_ui/InfoPanel.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Colocar una torre junto al camino y hacer clic en ella.
2. Lanzar una oleada sin tocar nada: BAJAS y HECHO suben solos mientras dispara.
3. Seleccionar otra torre: enseña las suyas y también se actualizan.
