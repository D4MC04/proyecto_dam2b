# Escala de la interfaz

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
En pantallas grandes o pequeñas la UI puede quedar diminuta o enorme.

## Qué hay que hacer
- Opción 'Tamaño de interfaz' (100/125/150 %) que escala los CanvasLayer de UI sin tocar el mapa.

## Archivos que toca
- scripts/autoloads/Settings.gd
- scripts/level_ui/LevelUI.gd

## Cómo se prueba a mano
1. Poner 150 %: barras y ficha se ven más grandes y el mapa igual.
