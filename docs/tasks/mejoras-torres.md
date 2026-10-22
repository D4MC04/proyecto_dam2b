# Mejoras de torre por niveles

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una torre colocada solo se puede fusionar o vender (Dudas de torres.md).

## Qué hay que hacer
- Botón 'Mejorar' en la ficha: 2 niveles por torre que suben daño, alcance o cadencia, con coste creciente.
- Indicador de nivel (puntos) bajo la torre.
- El valor de venta tiene en cuenta lo gastado.

## Archivos que toca
- scripts/resources/TowerData.gd
- scripts/entities/Tower.gd
- scripts/level_ui/InfoPanel.gd
- scripts/level/BuildManager.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Mejorar una torre dos veces: dispara más fuerte, el indicador cambia y vende por más.
