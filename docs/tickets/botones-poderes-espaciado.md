# Separar tecla e icono en los botones de poderes

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
En los botones de poderes la letra de la tecla (Q, E, R) y el icono están pegados y se ve congestionado.

## Qué hay que hacer
- En `scripts/level_ui/PowerButton.gd`, repartir bien el espacio del botón (unos 35x24): la letra que pinta `_draw` (hoy en `KEY_MARGIN` a la izquierda) y el icono del `Button`, con aire entre los dos y respecto a los bordes. Ajustar márgenes, alineación del icono o tamaño de letra según haga falta y, si hace falta, la separación de `PowersRow` en `scenes/level_ui/InfoPanel.tscn`.

## Archivos que toca
- scripts/level_ui/PowerButton.gd
- scenes/level_ui/InfoPanel.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y mirar la fila de poderes en la barra izquierda.
2. En cada botón la letra y el icono se ven separados y equilibrados, también con el oscurecido de recarga.
