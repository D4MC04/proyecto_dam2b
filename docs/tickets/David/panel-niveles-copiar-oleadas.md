# Panel de balanceo: copiar, pegar y duplicar oleadas y grupos; quitar ratios

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Montar oleadas parecidas en la pestaña Niveles obliga a rehacer los grupos uno a uno. Además, los ratios de dificultad frente a dinero no dan información útil y llevan a error.

## Qué hay que hacer
- En la pestaña Niveles, **copiar, pegar y duplicar** tanto oleadas enteras como grupos (las mini oleadas, `SpawnGroup`):
  - **Grupo**: duplicar lo pone justo debajo. Copiar lo guarda en un portapapeles del panel, y pegar lo inserta detrás del grupo seleccionado en cualquier oleada de cualquier nivel. Cada grupo pegado es un `sub_resource` con id nuevo, y una nave que esa oleada no usaba es un `ext_resource` nuevo.
  - **Oleada**: duplicar crea un `.tres` nuevo en `resources/wave_data/` con el siguiente nombre libre del nivel y lo añade detrás en la lista `waves` del `level_N.tres`, como `ext_resource` nuevo. Copiar y pegar hace lo mismo en el nivel y la posición elegidos. Pegar encima de una oleada existente le sustituye los grupos y el `health_multiplier`, preguntando antes.
  - Se pueden copiar varios grupos a la vez (selección múltiple) y pegarlos juntos.
  - Los ids y `uid` que ya existen no se tocan. Godot debe cargar los archivos nuevos sin errores; un `.tres` nuevo va sin `uid` o con uno nuevo válido, nunca copiado.
  - Todo queda como cambio pendiente hasta Guardar, igual que lo demás. Descartar lo deshace, también los archivos nuevos.
- **Quitar los ratios**: las columnas "Ratio" y "Ratio máx.", su tooltip y su cálculo (`ratioText`, `RATIO_TITLE` y lo que solo usen ellos). Las demás columnas calculadas se quedan.
- docs/design/niveles.md › "Generador de oleadas": quitar lo del ratio que enseña el panel y contar el copiar, pegar y duplicar. "Dificultad frente a dinero" se queda como explicación.
- Ampliar la pestaña Niveles en docs/CLAUDE-CODE.md › "Panel de balanceo".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas"
- tools/balance/levels.js › `levelColumns()`, `waveColumns()`, `levelStats()`, `ratioText()`, `readGroups()`, `writeGroups()`, `addGroup()`, `buildGroups()`
- tools/balance/tres.js y tools/balance/project.js (escribir y crear archivos, cambios pendientes)
- resources/level_data/level_1.tres y resources/wave_data/level_1_3.tres (formato)

## Archivos que toca
- tools/balance/levels.js, tools/balance/tres.js, tools/balance/project.js, tools/balance/style.css
- docs/design/niveles.md
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir el panel en la carpeta del worktree y entrar en Niveles: ya no deberían salir columnas de ratio.
2. En el nivel 1, duplicar la oleada 3 y guardar. Debería salir un `.tres` nuevo en `resources/wave_data/` y el nivel 1 debería tener una oleada más.
3. Copiar dos grupos de la oleada 2 del nivel 1, pegarlos en una oleada del nivel 2 y guardar.
4. Jugar los dos niveles: las oleadas tienen que salir como en el panel. `git diff` no debería cambiar ningún `uid` ni id que ya existiera.
