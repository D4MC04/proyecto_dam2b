# Separación de las naves según su velocidad

Estado: aceptada
Espera a: panel-niveles-copiar-oleadas
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ahora cada grupo de una oleada lleva su propio `spacing` a mano. Lo que importa es la velocidad de la nave: con la misma velocidad se quiere la misma separación. Con una fórmula no se puede ajustar a ojo, así que la separación pasa a ser una tabla por velocidad, que se ajusta a mano.

## Qué hay que hacer
- Nuevo Resource (por ejemplo `SpawnSpacing` en `scripts/resources/`, con un único `.tres` en `resources/`): una entrada por velocidad distinta de nave (`EnemyData.speed`), que da la separación en segundos.
- `WaveData.get_entries()` usa la separación de la tabla según la velocidad de `enemy_data`, en vez de `group.spacing`. Si una velocidad no está en la tabla, avisar con `push_warning` y usar 0,5 s.
- Quitar `spacing` de `SpawnGroup` y sus líneas de todos los `resources/wave_data/*.tres`. No tocar `uid` ni ids. `pause_after` se queda igual.
- Valores de partida de la tabla: para cada velocidad, la separación que más se repite hoy en los grupos con esa velocidad, para que el juego cambie lo menos posible. Apuntar en el resumen del chat qué grupos cambian de separación.
- `scripts/tools/make_waves.gd`: que use la tabla en vez de calcular `spacing` por grupo, y apuntar en docs/design/niveles.md cómo queda.
- Panel de balanceo, pestaña Niveles:
  - Quitar la columna de separación de los grupos.
  - Añadir una tabla editable "Separación por velocidad", con una fila por velocidad y las naves que la tienen. Sale una fila nueva cuando una nave tiene una velocidad que no estaba.
  - La duración de la salida y demás calculados usan la tabla.
- Comprobar con Grep que nada más usa `SpawnGroup.spacing`.
- Actualizar docs/design/niveles.md: "Datos de nivel" (`SpawnGroup`), "Generador de oleadas" y lo que hable de separaciones del nivel 1 y 2. Actualizar también enemigos.md › "Datos" si nombra la separación, y docs/CLAUDE-CODE.md › "Panel de balanceo".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas"
- docs/design/enemigos.md › "Datos"
- scripts/resources/SpawnGroup.gd, WaveData.gd › `get_entries()`, EnemyData.gd (`speed`)
- scripts/tools/make_waves.gd (donde calcula `spacing`)
- tools/balance/levels.js › `waveStats()`, `buildGroups()`, `spawnGroupDefaults()`

## Archivos que toca
- scripts/resources/SpawnGroup.gd, scripts/resources/WaveData.gd, scripts/resources/SpawnSpacing.gd (nuevo)
- resources/spawn_spacing.tres (nuevo), resources/wave_data/*.tres
- scripts/tools/make_waves.gd
- tools/balance/levels.js, tools/balance/project.js
- docs/design/niveles.md, docs/design/enemigos.md, docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir el panel en la carpeta del worktree, ir a Niveles y cambiar la separación de la velocidad de los Darts. Guardar.
2. Jugar el nivel 1: todos los grupos de Darts deberían salir con la separación nueva y los demás igual que antes.
3. Godot debería cargar todas las oleadas sin errores.
