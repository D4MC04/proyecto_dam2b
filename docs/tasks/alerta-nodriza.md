# Alerta de jefe cuando sale la Nodriza

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La Nodriza es el enemigo más gordo pero sale como uno más. Un aviso de "jefe" le da drama al momento.

## Qué hay que hacer
- Al empezar una oleada que tenga Nodriza (o el enemigo de más `base_damage` del juego), antes de que salga, enseñar una franja roja `#f0323c` que cruza el área de juego con "// ALERTA //" y el nombre "NODRIZA" en Monogram, parpadeando 2 veces (1,5 s en total).
- Bordes del área de juego con un pulso rojo suave mientras dura.
- La Nodriza sale de su grieta con el temblor más fuerte (si el portal lo permite fácilmente).
- No para el juego ni tapa la UI de las barras.

## Archivos que toca
- scripts/level_ui/LevelUI.gd (o una escena nueva `BossAlert` en scenes/level_ui/)
- scripts/level/Spawner.gd (saber si la oleada trae Nodriza)
- docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 6 hasta la oleada con Nodriza.
2. Al lanzarla, cruza una franja roja "ALERTA - NODRIZA" que parpadea y los bordes laten en rojo.
3. Las oleadas sin Nodriza no la enseñan.
