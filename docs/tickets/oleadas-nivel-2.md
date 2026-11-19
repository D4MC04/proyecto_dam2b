# Oleadas del nivel 2 escritas a mano, con picos y respiros

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
El nivel 2 es demasiado fácil: el generador sube todas las oleadas igual (ratio "construyendo" de 0,78 a 0,73, ver niveles.md › "Dificultad frente a dinero") y no hay ninguna oleada que ponga a prueba ni ninguna de respiro. Otros tower defense (Kingdom Rush, Plants vs Zombies) hacen las oleadas a mano en dientes de sierra: presentan la nave nueva sola, aprietan, dan un respiro y vuelven a apretar más alto, con una oleada final claramente más dura. Es el primer nivel de una serie: luego se hará lo mismo con el 3, el 4, etc.

## Qué hay que hacer
- En `scripts/tools/make_waves.gd`, que el nivel 2 salga de una tabla escrita a mano (como `EMERGENCY`), no de `LEVELS`: por oleada, `health` y grupos `[nave, cuántas, separación, camino, pausa después]` (pausa negativa = solapa con el siguiente grupo, para usar los dos caminos a la vez). El resto de niveles sigue con el generador.
- **No cambiar el dinero:** ni `starting_money`, ni recompensas, ni torretas, ni `PERFECT_WAVE_BONUS`. La suma de `reward` de cada oleada debe quedar cerca de la actual (230 × 1,13^(K-1): 230, 260, 294, 332, 375, 424, 479, 541, 611, 691), ±10 %.
- Forma de las 10 oleadas (las naves son las de ahora: Nave normal la protagonista; Darts y Wasps de apoyo):
  1. y 2. **Presentación**: la Nave normal sola por un camino, sin prisas, con algún grupo de Darts.
  3. **Respiro**: Darts y Wasps, para ahorrar y comprar la primera Minigun.
  4. Sube: Naves normales por los dos caminos, una detrás de otra.
  5. **Primer pico**: Naves normales por los dos caminos a la vez (solapadas), para obligar a cubrir los dos.
  6. **Respiro**.
  7. Sube, mezclando todo.
  8. **Pico fuerte**: un grupo compacto de Naves normales (separación corta).
  9. **Respiro corto**.
  10. **Final**: la más dura con diferencia, por los dos caminos a la vez.
- Vida (`health`) también en dientes de sierra: baja algo en los respiros y llega a cerca de ×3 en la última (ahora ×2,5).
- Regenerar las oleadas del nivel 2 (`level_2*.tres`, conservando sus uid) y actualizar la estimación del nivel 2 en la tabla de "Dificultad frente a dinero" si cambia.

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
