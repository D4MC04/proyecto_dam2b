# Flujo de juego y autoloads

## Autoloads

Definidos en `project.godot`, en este orden:

| Nombre | Origen | Qué guarda |
|---|---|---|
| `GameData` | `scenes/GameData.tscn` + `scripts/autoloads/GameData.gd` | `levels: Array[LevelData]`, la lista de niveles del juego |
| `GameState` | `scripts/autoloads/GameState.gd` | `current_level: int` y las funciones `is_unlocked(i)` (`i <= current_level`) e `is_completed(i)` (`i < current_level`) |
| `MusicManager` | `scripts/autoloads/MusicManager.gd` | La música; ver [menu.md](menu.md) |

`GameData.levels` tiene 6 entradas. Su contenido está en [niveles.md](niveles.md).

`GameState.current_level` vale 50 y ningún script lo modifica. Nada se guarda en disco.

## Escena Game

`scenes/Game.tscn` + `scripts/screens/Game.gd` (clase `Game`). Nodos hijos:

- `LevelUI`: instancia de `scenes/level_ui/LevelUI.tscn`.
- `Level`: instancia de `scenes/Level.tscn`.

`Game` tiene la propiedad `level_data: LevelData`, que le asigna el menú antes de añadirlo al árbol.

### Arranque

En `_ready`:

1. Guarda la `PackedScene` de `Level` para poder volver a instanciarla.
2. Conecta `ui.restart_requested` y `ui.quit_requested`.
3. Llama a `_setup_level()`:
   - `level.setup(level_data)`
   - conecta `level.lost` a `_on_level_lost`
   - conecta `ui.sidebar.tower_selected` a `level.on_tower_selected`
   - `ui.setup(level.game_state, level.towers)`

### Derrota

`Level` emite `lost` y `Game` llama a `ui.show_game_over()`, que muestra la pantalla y pausa el árbol.

### Reinicio

`_restart_level()` oculta el game over, desconecta la señal de la barra lateral, quita y libera el `Level` actual, instancia uno nuevo en la misma posición del árbol y repite `_setup_level()`. El dinero vuelve a su valor inicial porque `LevelState` es hijo del `Level` nuevo.

### Salir al menú

`_quit_to_menu()` instancia `scenes/MainMenu.tscn` con `start_on_level_selection = true`, lo añade a la raíz, lo marca como `current_scene` y libera la escena `Game`.

## Cambio de escena

Tanto `MainMenu._open_level` como `Game._quit_to_menu` cambian de escena a mano (añadir a `root`, asignar `current_scene`, `queue_free` de la anterior) porque necesitan asignar una propiedad a la escena nueva antes de que entre en el árbol. No se usa `change_scene_to_file`.

## Dudas

- `current_level = 50` deja desbloqueados todos los niveles. No hay código que lo suba al completar un nivel.
- `GameState.is_completed` no se llama desde ningún sitio.
- No existe condición de victoria: `Level` solo emite `lost`.
- El archivo en git es `scenes/level.tscn` (minúscula), pero `Game.tscn` lo referencia como `res://scenes/Level.tscn`. En Windows funciona; en un sistema que distinga mayúsculas la ruta no coincide.
- `project.godot` tiene `config/name="DAM_Game"`; el título que muestra el menú es "ASTRO ARTILLERY".
