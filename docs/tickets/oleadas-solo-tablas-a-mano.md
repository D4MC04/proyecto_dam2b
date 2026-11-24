# make_waves.gd solo reescribe los niveles con oleadas a mano (y el nivel 1 pasa a tabla)

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: alta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al lanzar `make_waves.gd` se regeneran las oleadas de todos los niveles, y los 1 y 4-9 salen distintos de los que hay en main (el chat del nivel 3 tuvo que restaurarlos a mano). El nivel 1 está bien como está y no debe cambiar. Los demás niveles se irán haciendo a mano uno a uno (4, 5...), cada uno en su ticket.

## Qué hay que hacer
- Pasar el nivel 1 a una tabla a mano `LEVEL_1` (mismo formato que `LEVEL_2`/`LEVEL_3`) **copiando tal cual** sus oleadas actuales de `resources/wave_data/level_1*.tres` de main (grupos, cuántas, separación, camino, pausa y `health_multiplier`), sin volver a generarlas, y añadirla a `HAND_LEVELS`. Si algún grupo de un `.tres` no cabe en el formato de la tabla (p. ej. Darts de colores mezclados en un tramo), escribir cada tramo como su propio grupo para que salga idéntico.
- Que `_initialize()` solo reescriba los niveles de `HAND_LEVELS` (y el de emergencia); los que siguen con el generador (`LEVELS`, ahora 4-9) no se tocan. Dejar el generador en el script (no borrarlo) por si se quiere usar de base, pero sin que escriba nada al lanzar el script normal.
- **Comprobar:** lanzar el script y que `git diff --stat resources/wave_data` no cambie nada de contenido (en los niveles 1, 2 y 3 como mucho los ids de subrecursos; en el resto, nada). Si el nivel 1 cambia en algo jugable, la tabla está mal copiada.
- Actualizar niveles.md › "Generador de oleadas": qué niveles van a mano (1, 2, 3), que el script solo reescribe esos y que los 4-9 están pendientes de pasar a mano en su ticket.

## Qué leer
- docs/design/niveles.md › "Generador de oleadas"
- scripts/tools/make_waves.gd › `LEVEL_2`, `HAND_LEVELS`, `_initialize()`, `_make_hand_level()`
- resources/wave_data/level_1.tres a level_1_10.tres

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/level_1*.tres (solo si cambian los ids al reescribirlos)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el Sector 1: las oleadas son exactamente las de antes.
2. Jugar el Sector 4: igual que antes (no se ha tocado).
