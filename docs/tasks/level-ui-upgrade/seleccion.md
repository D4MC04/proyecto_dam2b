# Tarea: selección de torre en LevelState

Primera tarea del rediseño de la UI de nivel. Es un refactor sin cambios visuales: prepara la base para las pestañas y la ficha que vendrán después.

## Problema actual

- `Sidebar.tower_selected` tiene dos receptores que hacen lo mismo. `LevelUI._on_tower_selected` (conectado en `LevelUI._ready`) y `Level.on_tower_selected` (conectado y desconectado en `Game._setup_level` y `Game._restart_level`) escriben los dos `LevelState.selected_tower`.
- Al cancelar con clic derecho, `BuildManager` pone `state.selected_tower = null`, pero el botón de la barra lateral sigue pulsado. `Sidebar.reset_selection` existe y nadie la llama.
- `LevelState.selected_tower` es una variable sin señal, así que la UI no se entera de los cambios que no hace ella.

## Qué hay que hacer

1. **`LevelState` es la única fuente de la torre seleccionada.**
   - `selected_tower` pasa a tener un setter que emite `selected_tower_changed(data: TowerData)` solo cuando el valor cambia de verdad.
   - Nadie más guarda una copia de la selección como estado propio (por ejemplo `Sidebar._selected`). Si alguien necesita saberla, la lee de `LevelState` o escucha la señal.
2. **Un solo camino de la UI al estado.**
   - La barra lateral pide el cambio y `LevelUI` lo escribe en `LevelState`.
   - Se eliminan `Level.on_tower_selected` y las conexiones o desconexiones de `Game` con `ui.sidebar.tower_selected`.
3. **La barra lateral refleja el estado.**
   - `LevelUI.setup` conecta `state.selected_tower_changed` a la barra lateral, igual que ya hace con `money_changed`, incluida la desconexión del `LevelState` anterior al reiniciar.
   - Al recibir la señal, la barra marca como pulsado el botón de esa torre y suelta los demás, o los suelta todos con `null`. Hay que cambiar el estado del botón sin volver a disparar `toggled` (por ejemplo `set_pressed_no_signal`) para no crear un bucle.
4. **`BuildManager` no cambia de comportamiento.** Sigue poniendo `selected_tower = null` con el clic derecho; ahora el botón se suelta solo gracias a la señal.

## Comportamiento que debe mantenerse

- Pulsar un botón selecciona la torre; pulsarlo otra vez la deselecciona (`allow_unpress`). Solo puede haber uno pulsado.
- Tras colocar una torre, la selección se mantiene para poder colocar otra.
- Si el dinero baja del coste de la torre seleccionada, el botón se desactiva y la selección pasa a `null`.
- Reiniciar el nivel deja la selección vacía y sin botones pulsados.

## Cómo probarlo

- Seleccionar una torre, cancelar con clic derecho en el mapa: el botón se suelta y la vista previa desaparece.
- Seleccionar, colocar varias, quedarse sin dinero: el botón se desactiva y se suelta.
- Reiniciar desde la pausa con una torre seleccionada: al volver no hay nada seleccionado y no salen errores de señales duplicadas o desconectadas en la consola.
- El proyecto carga sin errores en headless.

## Al terminar

Actualizar `docs/design/ui.md` y `docs/design/niveles.md`: la tabla de comunicación, las dos dudas resueltas y la desaparición de `Level.on_tower_selected`.
