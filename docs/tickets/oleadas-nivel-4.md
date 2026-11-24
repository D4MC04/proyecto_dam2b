# Oleadas del nivel 4 escritas a mano, como las de los niveles 2 y 3

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las oleadas a mano de los niveles 2 y 3 (PR 148 y 150) funcionan: principio suave, respiros y picos, y oleadas mezcladas. El nivel 4 sigue saliendo del generador. Va después de `oleadas-solo-tablas-a-mano` (los dos tocan `make_waves.gd`).

## Qué hay que hacer
- Tabla a mano `LEVEL_4` en `scripts/tools/make_waves.gd`, añadida a `HAND_LEVELS`, con el mismo formato y criterios que `LEVEL_2` y `LEVEL_3` (ver niveles.md › "Generador de oleadas").
- **No cambiar el dinero:** ni `starting_money` (900 €), ni recompensas, ni torretas, ni `PERFECT_WAVE_BONUS`. Recompensa por oleada cerca de la actual (440 × 1,125^(K-1): 440, 495, 557, 627, 705, 793, 892, 1004, 1129, 1270), ±5 %.
- Naves: el **Acorazado** (420 PV, muy lento, 135 €) es el protagonista; de apoyo, Darts, Wasps, Nave normal y Nave agresiva. Torreta nueva: Cañón pesado.
- Mapa: dos caminos simétricos que bajan desde las esquinas de arriba (camino 0 izquierda, camino 1 derecha), se juntan abajo en el centro y suben juntos por la columna central hasta la estación.
- Oleada 1 por un solo camino presentando el Acorazado con calma; la 2 por los dos. Principio fácil, grupos cortos y mezclados (nunca más de 6 iguales seguidas), dientes de sierra (respiros 3, 6, 9; picos 5, 8, 10; la 10 la más dura) y un salto desde el nivel 3 que se note sin ser brusco.
- Probar mucho: `probador` y comprobación numérica por oleada (niveles.md › "Dificultad frente a dinero"), tabla en el resumen y fila del nivel 4 actualizada.
- Regenerar solo `level_4*.tres` (conservando uid) y comprobar con `git diff` que los demás niveles no cambian.

## Qué leer
- docs/design/niveles.md › "Generador de oleadas" y "Dificultad frente a dinero"
- scripts/tools/make_waves.gd › `LEVEL_3`, `HAND_LEVELS`, `LEVELS` (fila del nivel 4)
- resources/map_data/level_4.txt (caminos)

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/level_4.tres a level_4_10.tres
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el Sector 4 desde el principio.
2. La oleada 1 va por un solo camino y presenta el Acorazado; la 2 usa los dos.
3. La 3, la 6 y la 9 son más tranquilas; la 5, la 8 y la 10 aprietan.
4. No salen filas largas de naves iguales y se puede ganar jugando bien.
