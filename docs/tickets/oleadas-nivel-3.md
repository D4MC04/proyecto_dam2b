# Oleadas del nivel 3 escritas a mano, como las del nivel 2

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Las oleadas del nivel 2 hechas a mano (PR 148) le encantaron a Renzo: principio suave, respiros y picos, y oleadas mezcladas en vez de filas de naves iguales. El nivel 3 sigue saliendo del generador, con todas las oleadas subiendo igual. Hay que hacer lo mismo con él.

## Qué hay que hacer
- En `scripts/tools/make_waves.gd`, que el nivel 3 salga de una tabla escrita a mano, igual que `LEVEL_2` (mismo formato: `health` y grupos `[nave, cuántas, separación, camino, pausa después]`). Reutilizar `_make_level_2()` generalizándola para que valga para cualquier nivel con tabla a mano (p. ej. un diccionario nivel → tabla), sin duplicar código. El nivel 2 tiene que generar exactamente lo mismo que ahora.
- **No cambiar el dinero:** ni `starting_money` (700 €), ni recompensas, ni torretas, ni `PERFECT_WAVE_BONUS`. La suma de `reward` de cada oleada, cerca de la del generador (330 × 1,125^(K-1): 330, 371, 418, 470, 529, 595, 669, 753, 847, 953), ±5 %.
- Naves: la **Nave agresiva** (110 PV, lenta, 50 €) es la protagonista; de apoyo, Darts, Wasps y Nave normal. Torreta nueva del nivel: Cryo.
- Mapa: los dos caminos entran juntos arriba a la derecha y se parten en dos ramas en espejo (camino 0 la de arriba, camino 1 la de abajo) que no se juntan.
- Mismos criterios que el nivel 2 (ver niveles.md › "Nivel 2 a mano"):
  - **Oleada 1** por un solo camino, presentando la Nave agresiva sola entre naves fáciles, muy separadas; la **2** repartida entre los dos.
  - **Principio fácil:** las primeras oleadas se pasan con el dinero inicial sin apurar.
  - **Mezcla:** grupos cortos (2-6), tipos, caminos y ritmos alternados, grupos escolta; nunca más de 6 naves iguales seguidas.
  - **Dientes de sierra:** respiros en 3, 6 y 9; picos en 5, 8 y 10; la 10, la más dura. Que el salto del nivel 2 al 3 se note pero no sea brusco.
- **Probar mucho:** además del `probador`, comprobación numérica por oleada (vida total con `health` frente al daño que se puede montar con el dinero acumulado, ver niveles.md › "Dificultad frente a dinero"), tabla en el resumen y ajustar hasta que todo sea pasable jugando normal. Actualizar la fila del nivel 3 en esa tabla.
- Regenerar `level_3*.tres` conservando sus uid; el resto de niveles no cambia (comprobar con `git diff` que `level_2*.tres` no se mueve, salvo los ids de subrecursos).

## Qué leer
- docs/design/niveles.md › "Generador de oleadas" (punto "Nivel 2 a mano") y "Dificultad frente a dinero"
- scripts/tools/make_waves.gd › `LEVEL_2`, `_make_level_2()`, `LEVELS` (fila del nivel 3) y `_initialize()`
- resources/map_data/level_3.txt (caminos)

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/level_3.tres a level_3_10.tres (regenerados)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el Sector 3 desde el principio.
2. La oleada 1 va por un solo camino y presenta la Nave agresiva con calma; la 2 usa los dos caminos.
3. La 3, la 6 y la 9 se notan más tranquilas; la 5, la 8 y la 10 aprietan, y la 10 es la más dura.
4. Al final no salen filas largas de naves iguales, y se puede ganar jugando bien.
