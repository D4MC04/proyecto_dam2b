# Oleadas del nivel 2 escritas a mano, con picos y respiros

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El nivel 2 es demasiado fácil: el generador sube todas las oleadas igual (ratio "construyendo" de 0,78 a 0,73, ver niveles.md › "Dificultad frente a dinero") y no hay ninguna oleada que ponga a prueba ni ninguna de respiro. Otros tower defense (Kingdom Rush, Plants vs Zombies) hacen las oleadas a mano en dientes de sierra: presentan la nave nueva sola, aprietan, dan un respiro y vuelven a apretar más alto, con una oleada final claramente más dura. Es el primer nivel de una serie: luego se hará lo mismo con el 3, el 4, etc.

## Qué hay que hacer
**Se parte de la rama `claude/oleadas-nivel-2-45cb2c`** (commit `34af0c9`): ya tiene la tabla `LEVEL_2` en `make_waves.gd`, las oleadas regeneradas y el dinero cuadrado. Renzo la probó y no le convence; hay que rehacerla con esto:

- **No cambiar el dinero:** ni `starting_money`, ni recompensas, ni torretas, ni `PERFECT_WAVE_BONUS`. La suma de `reward` de cada oleada sigue cerca de la de ahora (230, 260, 294, 332, 375, 424, 479, 541, 611, 691), ±10 %.
- **Oleada 1:** toda por el camino de la izquierda (`path_index` 0, el que sube por la columna 5).
- **Oleada 2:** repartida entre los dos caminos.
- **Más fácil al principio:** las primeras oleadas tienen que poder pasarse con lo que da el dinero inicial (500 €) sin apurar. Bajar `health` y separar más las naves al principio.
- **Que no salgan en fila iguales al final:** ahora las últimas oleadas son filas largas de la misma nave (12-14 Naves normales seguidas). Mezclar dentro de cada oleada: grupos más cortos (3-6), tipos alternados, naves rápidas (Darts/Wasps) intercaladas con las lentas y algún grupo "escolta" (una Nave normal con Darts alrededor), como en Kingdom Rush o Bloons, donde las oleadas mezclan tipos y ritmos en vez de una fila larga.
- Mantener la forma en dientes de sierra (presentación, respiros en 3, 6 y 9, picos en 5 y 8, final la más dura), pero con una subida que se pueda pasar.
- **Probar mucho y que sea pasable:** además del `probador`, hacer una comprobación numérica por oleada (vida total con `health` frente al daño que se puede montar con el dinero acumulado, ver niveles.md › "Dificultad frente a dinero"), apuntar la tabla en el resumen y ajustar hasta que todas las oleadas sean pasables jugando normal y ninguna dé un salto brusco. Actualizar la fila del nivel 2 de esa tabla en niveles.md.
- Regenerar `level_2*.tres` conservando sus uid. El resto de niveles no cambia.

## Qué leer
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas" y "Dificultad frente a dinero"
- scripts/tools/make_waves.gd › `LEVELS`, `EMERGENCY`, `_make_emergency()` y `_make_level()`

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/level_2.tres a level_2_10.tres (regenerados)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el Sector 2 desde el principio.
2. Las oleadas 1-2 presentan la Nave normal con calma; la 3, la 6 y la 9 se notan más tranquilas; la 5 y la 8 aprietan y la 10 es la más dura.
3. Debería costar ganar sin construir bien, pero se puede ganar cubriendo los dos caminos y mejorando torretas.
