# Panel de balanceo: separación por velocidad

Estado: aceptada
Espera a: panel-sprites
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Con `separacion-por-velocidad`, `SpawnGroup.spacing` ya no existe: la separación sale de `resources/spawn_spacing.tres` según la velocidad de la nave. El panel aún no lo sabe: la columna de separación de los grupos sale vacía y "Salida (s)" y "Sale a (s)" no dan número.

## Qué hay que hacer
- **Pestaña Niveles**:
  - Quitar la columna "Separación" de los grupos: `spacing` de `GROUP_FIELDS`, su cabecera y su edición.
  - La duración de la salida ("Salida (s)"), "Sale a (s)" y demás tiempos usan la tabla `spacing_by_speed` de `resources/spawn_spacing.tres` con la `speed` de la nave de cada grupo, igual que `WaveData.get_entries()`. Si la velocidad no está en la tabla, 0,5 s.
  - Copiar, pegar y duplicar grupos dejan de llevar `spacing`.
- **Pestaña Enemigos**: columna editable "Separación (s)" en todas las naves, con el valor de su velocidad en la tabla.
  - Al cambiarla se cambia la entrada de esa velocidad en `spawn_spacing.tres`, así que cambia a la vez en todas las naves con esa velocidad, y se recalculan los tiempos de Niveles.
  - Si se cambia la `speed` de una nave a una velocidad que no está en la tabla, la columna lo marca y, al poner una separación, se añade la entrada nueva.
  - Tooltip: "Compartida por todas las naves de X px/s".
- **`tres.js`**: `Tres.scan()` solo entiende valores de varias líneas si son cadenas, y Godot guarda el `Dictionary` en varias líneas. Hacer que siga los paréntesis y las llaves abiertos hasta cerrarlos.
  - Leer `Dictionary[int, float]({ ... })` como mapa velocidad → segundos.
  - Al guardar, reescribir solo ese valor con el formato de Godot (`Dictionary[int, float]({\n30: 0.68,\n...\n})`, claves ordenadas, `float` como `0.5`). El resto del archivo y los `uid` quedan igual.
- Ampliar docs/CLAUDE-CODE.md › "Panel de balanceo" y la parte del panel de docs/design/niveles.md › "Generador de oleadas" (la separación se edita en Enemigos, ya no por grupo).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Datos de nivel" y "Generador de oleadas" (lo que dejó `separacion-por-velocidad`)
- scripts/resources/SpawnSpacing.gd, WaveData.gd › `get_entries()`; resources/spawn_spacing.tres
- tools/balance/levels.js › `GROUP_FIELDS`, `waveStats()`, `waveColumns()`, la tabla de grupos (cabecera "Separación", "Sale a (s)")
- tools/balance/enemies.js › `columns()`; tools/balance/tres.js › `scan()` y la escritura

## Archivos que toca
- tools/balance/levels.js, tools/balance/enemies.js, tools/balance/tres.js, tools/balance/project.js
- docs/CLAUDE-CODE.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir el panel en la carpeta del worktree. En Niveles, los grupos no deberían tener columna de separación, y "Salida (s)" y "Sale a (s)" deberían dar números.
2. En Enemigos, cambiar la separación del Dart y guardar. `git diff resources/spawn_spacing.tres` debería cambiar solo la línea de su velocidad, y las demás naves con esa velocidad deberían enseñar el valor nuevo.
3. Jugar el nivel 1: los Darts deberían salir con la separación nueva. Godot debería cargar `spawn_spacing.tres` sin errores.
