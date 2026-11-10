# Flujo de juego y autoloads

## Autoloads

Definidos en `project.godot`, en este orden:

| Nombre | Origen | Qué guarda |
|---|---|---|
| `GameData` | `scenes/GameData.tscn` + `scripts/autoloads/GameData.gd` | `levels: Array[LevelData]`, la lista de niveles del juego |
| `GameState` | `scripts/autoloads/GameState.gd` | `current_level: int` (número, desde 1, del nivel más alto desbloqueado; empieza en 1), `is_unlocked(i)` (`i < current_level`), `tutorial_done: bool` (ya se pasó por el simulacro: ganado, saltado o abandonado), `complete_level(number)`, `complete_tutorial()` y `reset_progress()` (vuelve a 1, reactiva el simulacro, guarda y emite la señal `progress_reset`); `i` es el índice desde 0 en `GameData.levels` |
| `Settings` | `scripts/autoloads/Settings.gd` | Las opciones del jugador, guardadas en `user://settings.cfg`; ver [menu.md](menu.md) |
| `MusicManager` | `scripts/autoloads/MusicManager.gd` | La música; ver [menu.md](menu.md) |

`GameData.levels` tiene 6 entradas. Su contenido está en [niveles.md](niveles.md).

`GameState` guarda el progreso en 3 ranuras independientes (`SLOT_COUNT`), un `ConfigFile` por ranura en `user://saves/slot_N.cfg` (sección `progress`). `active_slot` (0 = ninguna al arrancar; mientras sea 0, `_save()` no escribe) lo fija `load_slot(slot)`, que carga la ranura (valores por defecto si no tiene archivo; solo acepta un entero >= 1 y un booleano en `current_level` y `tutorial_done`). Cada guardado añade `saved_at` (tiempo Unix). También hay `has_save(slot)`, `delete_slot(slot)` (si era la activa la deja sin ranura y con los valores por defecto) y `get_slot_summary(slot)` (`saved_at`, `play_time`, `sector`, `achievements`, `achievements_total`; vacío sin partida; no toca la partida activa). `_ready` migra el antiguo `user://progress.cfg` a `slot_1.cfg` si no hay ninguna ranura y lo borra. La ranura la elige la pantalla de inicio (`StartScreen`, ver [menu.md](menu.md)), que llama a `load_slot` y, en una ranura vacía, a `flush()` para que quede ocupada; para borrarla llama a `delete_slot`. Ninguna pantalla llama ya a `reset_progress()`. Se guarda en `complete_level`, `complete_tutorial` y `reset_progress`. `GameState` guarda también `play_time` (segundos jugados, que suma `Level._process` en tiempo real) la mejor marca de estrellas de cada nivel en `level_stars` (número de nivel → 1..3; las partidas antiguas sin esta clave cargan sin estrellas; se borra con `_set_defaults`, así que también al borrar la ranura o en `reset_progress`) y los contadores `stats` `spent` (dinero gastado, desde `LevelState.spend_money`) y `built_<torreta>` (torretas construidas, desde `BuildManager`); `reset_progress` los borra. `Settings` guarda las opciones en su propio archivo.

## Escena Game

`scenes/Game.tscn` + `scripts/screens/Game.gd` (clase `Game`). Nodos hijos:

- `LevelUI`: instancia de `scenes/level_ui/LevelUI.tscn`.
- `Level`: instancia de `scenes/Level.tscn`.

`Game` tiene la propiedad `level_data: LevelData`, que le asigna el menú antes de añadirlo al árbol, y `from_hyperspace: bool`: si es true, el mapa entra con un fundido desde blanco de 0,2 s (`_fade_in_from_white`) tras el salto al hiperespacio del menú. `_fade_white(desde, hasta, capa)` es el fundido común: `CanvasLayer` 100 con un `ColorRect` blanco que bloquea el ratón, tween que sigue con el árbol en pausa y que se libera al llegar a alfa 0.

### Arranque

En `_ready`:

1. Guarda la `PackedScene` de `Level` para poder volver a instanciarla.
2. Conecta `ui.action_requested` a `_on_action_requested`. Es la única señal de la UI que escucha.
3. Llama a `_setup_level()`:
   - `level.setup(level_data)`
   - conecta `level.lost` a `_on_level_lost` y `level.won` a `_on_level_won`
   - `ui.setup_powers(...)` con el `Powers` del nivel y después `ui.setup(level.game_state, level.turrets, level_number, level.spawner, has_next_level)` (`has_next_level` es true si el nivel está en `GameData.levels` y no es el último), que conecta la UI con el `LevelState` y el `Spawner` del nivel (ver [ui.md](ui.md)).

### Acciones de la UI

`_on_action_requested(action)` decide con un `match` sobre `LevelUI.Action`: `RESTART` llama a `_restart_level()`, `QUIT` a `_quit_to_menu()` y `NEXT_LEVEL` a `_next_level()`. Cuando llega la señal, `LevelUI` ya ha pasado a `PLAYING`, así que no hay pantalla ni pausa.

### Pérdida de foco

`Game._notification` recibe `NOTIFICATION_APPLICATION_FOCUS_OUT` (Alt+Tab, clic fuera de la ventana) y llama a `ui.pause_if_playing()`, que abre la pausa normal solo si se está jugando: en pausa, derrota, victoria (también durante la cámara lenta y el respiro) no hace nada. Tampoco durante el barrido de reinicio o siguiente nivel (`_transitioning`). Se desactiva con la opción `pause_on_focus_loss` de `Settings` (activada por defecto, ver [menu.md](menu.md)). Al volver el foco el juego sigue en pausa hasta pulsar Continuar o Escape.

### Derrota

Cuando la estación se destruye, `Level` deja de construir y ya no puede ganar, espera a que acabe su explosión y emite `lost` (una sola vez por partida). `_on_level_lost()` pasa el resumen a la UI con `ui.show_run_stats(level.get_run_stats())` y después llama a `ui.set_state(LevelUI.UiState.LOST)`. La UI frena el juego con una cámara lenta de algo más de 1 s, vuelve a velocidad normal, pausa el árbol y muestra la pantalla de derrota con un glitch de entrada (ver [ui.md](ui.md)). "Reintentar" usa `RESTART` y "Menú" usa `QUIT`; las dos pasan antes a `PLAYING`, que deja `Engine.time_scale` en 1.

### Victoria

`Level` emite `won` al limpiar la última oleada (y solo si no ha emitido `lost`) y `Game` pasa a la UI el resumen de la partida (`ui.show_run_stats(level.get_run_stats())`) y después llama a `ui.set_state(LevelUI.UiState.WON)`. La UI no congela el juego al momento: durante un respiro de 0,6 s sigue a velocidad normal (se ve explotar al último enemigo), sin selección de torreta ni Escape, y después pausa el árbol y muestra `VictoryScreen`, que entra deslizando y cuenta los números del resumen (ver [ui.md](ui.md)). "Siguiente nivel" ejecuta `_next_level()`: cambia `level_data` al siguiente de `GameData.levels` y llama a `_restart_level()`, así que no se cambia de escena y la cabecera, las oleadas, la tienda, el dinero y la ficha se rehacen para el nivel nuevo. "Menú" usa `QUIT`. `_on_level_won` llama antes a `GameState.complete_level(número del nivel)`: si era el más alto desbloqueado y no es el último, sube `current_level` y guarda; si no, no hace nada. Así "Siguiente nivel" ya está desbloqueado. Después calcula `GameState.stars_for_health(base.health, base.max_health)`, lo guarda con `GameState.record_level_stars(número, estrellas)` y lo pasa a la pantalla de victoria con `ui.show_victory_stars(estrellas)`, que pinta tres estrellas pixel bajo el título (ámbar las ganadas, oscuras las que faltan): 3 estrellas si la estación no perdió vida, 2 si le queda más de la mitad, 1 si gana con menos; solo se guarda si mejora la marca del nivel (nunca baja). `GameState.get_level_stars(número)` devuelve la mejor marca (0 si no se ha ganado); la usará la selección de nivel.

### Reinicio

`_restart_level()` (que también usa el paso al siguiente nivel) hace primero un barrido a blanco de 0,2 s, con la pantalla tapada quita y libera el `Level` actual, instancia uno nuevo en la misma posición del árbol y repite `_setup_level()`, y vuelve a fundir de blanco a transparente (0,2 s). Mientras dura el barrido, `_transitioning` ignora otro reinicio. El dinero vuelve a su valor inicial porque `LevelState` es hijo del `Level` nuevo. Las conexiones con el `LevelState` y el `Spawner` anteriores las deshace `LevelUI.setup`.

### Salir al menú

`_quit_to_menu()` instancia `scenes/MainMenu.tscn` con `start_on_level_selection = true`, lo añade a la raíz, lo marca como `current_scene` y libera la escena `Game`.

## Cambio de escena

Tanto `MainMenu._open_level` como `Game._quit_to_menu` cambian de escena a mano (añadir a `root`, asignar `current_scene`, `queue_free` de la anterior) porque necesitan asignar una propiedad a la escena nueva antes de que entre en el árbol. No se usa `change_scene_to_file`.

## Enemigos vistos

`Spawner._spawn_enemy` llama a `GameState.mark_enemy_seen(data)`, que guarda en la ranura activa (clave `seen_enemies`) el nombre de archivo del `EnemyData` la primera vez que sale. `reset_progress` los borra. Los usa el Navedex (ver [menu.md](menu.md)).
