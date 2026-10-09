# Niveles: nivel, mapa, cuadrícula y oleadas

## Escena Level

`scenes/Level.tscn` + `scripts/level/Level.gd` (clase `Level`). Nodos hijos:

| Nodo | Script | Función |
|---|---|---|
| `LevelState` | `scripts/level/LevelState.gd` | Dinero y torre seleccionada |
| `Grid` | `scripts/level/Grid.gd` | Qué casillas son camino o hueco y cuáles están ocupadas |
| `Spawner` | `scripts/level/Spawner.gd` | Crea enemigos según la oleada |
| `BuildManager` | `scripts/level/BuildManager.gd` | Coloca torres; ver [torres.md](torres.md) |

`Level.setup(data: LevelData)`:

1. Instancia `data.map`, lo llama `Map` y lo pone como primer hijo.
2. Guarda `data.towers` en `towers`.
3. `grid.setup(map.logic_map)`.
4. `spawner.setup(map.get_paths(), data.waves)`.

Conexiones hechas en `_ready`:

- `spawner.enemy_died(reward)` llama a `game_state.add_money`.
- `spawner.enemy_reached_end` llama a `_lose`, que emite `lost`.
- `build_manager.state = game_state`.

`Level.on_tower_selected(data)` guarda la torre elegida en `game_state.selected_tower`.

## LevelState

- `money` empieza en 1000.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, emite `money_changed` y devuelve `true`.
- `selected_tower: TowerData` es la torre que se colocará al hacer clic.

## Datos de nivel

- `LevelData` (`scripts/resources/LevelData.gd`): `map: PackedScene`, `towers: Array[TowerData]`, `waves: Array[WaveData]`.
- `WaveData`: `entries: Array[SpawnEntry]`.
- `SpawnEntry`: `enemy_data: EnemyData`, `time: float` (segundos desde el inicio de la oleada), `path_index: int`.

Niveles registrados en `GameData.levels`:

| Nivel | Mapa | Torres disponibles | Enemigos en la oleada | Último enemigo (s) | Caminos usados / en el mapa |
|---|---|---|---|---|---|
| 1 | `maps/Level1.tscn` | Cañón doble, Cañón pesado, Láser | 25 | 62,6 | 1 / 1 |
| 2 | `maps/espacio/Level2_espacio.tscn` | las anteriores + Cryo | 32 | 93,63 | 1 / 2 |
| 3 | `maps/Level3.tscn` | las anteriores + Tesla | 40 | 105,07 | 1 / 1 |
| 4 | `maps/Level4.tscn` | las anteriores + Rail | 50 | 125,7 | 2 / 2 |
| 5 | `maps/espacio/Level5_espacio.tscn` | las anteriores + Disintegrator | 60 | 132,83 | 1 / 4 |
| 6 | `maps/espacio/Level6_espacio.tscn` | las 7 | 75 | 210,96 | 4 / 8 |

Cada nivel tiene una sola `WaveData` (`resources/wave_data/level_N.tres`). Los niveles 1, 2, 3, 4 y 6 están en `resources/level_data/level_N.tres`; el 5 está definido como subrecurso dentro de `scenes/GameData.tscn`.

## Spawner

- `setup(paths, waves)` guarda los datos y llama a `start_next_wave()`.
- `start_next_wave()` no hace nada si hay una oleada activa o no quedan más. Si arranca, copia las entradas, las ordena por `time` y pone el reloj a 0.
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_finished(index)` y se desactiva.
- `_spawn(entry)` instancia `scenes/entities/Enemy.tscn` como hijo del `Path2D` número `entry.path_index % paths.size()`, llama a `enemy.setup(entry.enemy_data)` y reenvía sus señales `died` y `reached_end` como `enemy_died` y `enemy_reached_end`.

## Mapa

Base: `scenes/maps/Map.tscn` + `scripts/level/Map.gd` (clase `Map`). Nodos:

- `VisualMap` (`TileMapLayer`): lo que se ve.
- `LogicMap` (`TileMapLayer`, tileset `resources/tilesets/logic_tileset.tres`): marca el tipo de cada casilla.
- `Paths` (`Node2D`): sus hijos son los `Path2D`. `Map.get_paths()` los devuelve en orden.
- `SpaceStation`: instancia de `scenes/entities/Base.tscn`; ver [base.md](base.md).

Hay dos familias de mapas:

- **Hierba** (`scenes/maps/Level1.tscn` a `Level10.tscn` y `scenes/maps/redesign/`): `VisualMap` usa `resources/tilesets/tileset.tres` (hierba, piedra, plantas, objetos, estructuras, muros). `LogicMap` es visible con alfa 0,39.
- **Espacio** (`scenes/maps/espacio/`): añaden `Fondo` (instancia de `FondoEspacio.tscn`) y las capas `Polvo`, `Planetas` y `Pista`, todas con `resources/tilesets/tileset_espacio.tres`. `LogicMap` tiene `visible = false`. El nodo `Map` está en la posición (8, 0).

### FondoEspacio

`scenes/maps/espacio/FondoEspacio.tscn`: `Nebulosa` (`Parallax2D` con desplazamiento automático de -3 px/s), `PlanetaGigante`, `Estrellas` (`Parallax2D` a -6 px/s con un `AnimatedSprite2D` de 8 frames) y `Cometa`.

`scripts/level/Cometa.gd`: sprite que espera entre 6 y 15 s, aparece a la izquierda a una altura al azar, cruza con velocidad (150, 22) px/s y vuelve a esperar. Su temporizador se detiene con la pausa.

## Grid

`Grid.setup(logic_map)` recorre las casillas usadas de `LogicMap` y lee el dato personalizado `kind` de cada tile:

- `"path"`: se guarda en `path_cells`.
- `"slot"`: se guarda en `slot_cells`.
- cualquier otro valor (el tileset define también `"scenery"`): no se guarda.

Funciones:

- `can_build(c)`: la casilla es `slot` y no tiene torre.
- `register_tower(c, t)`: apunta la torre y la borra del registro cuando el nodo sale del árbol.
- `cell(p)` y `center(c)`: conversión entre posición global y casilla.
- `get_kind(c)`: devuelve `"path"`, `"slot"` o `"scenery"`.

## Dudas

- `start_next_wave()` solo se llama desde `setup`, y nadie escucha `wave_finished`. Con los datos actuales no afecta porque cada nivel tiene una única oleada, pero una segunda `WaveData` no llegaría a empezar.
- Al terminar de salir los enemigos no pasa nada más: no hay victoria ni final de nivel.
- `Grid.get_kind` y `Grid.path_cells` no se usan fuera de `Grid`.
- `tileset.tres` declara una capa de datos `buildable` (bool) que ningún script lee.
- No hay en el repositorio ningún script que genere los `TileMapLayer` a partir de datos, que es lo que pide `CLAUDE.md`.
- `Level7.tscn` a `Level10.tscn`, `Level2.tscn`, `Level5.tscn`, `Level6.tscn` y la carpeta `redesign/` no están en ningún `LevelData`. Los mapas 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `resources/level_data/level_5.tres` existe y tiene el mismo contenido que el subrecurso de `GameData.tscn`, pero `GameData` no lo usa.
- En los niveles 2, 5 y 6 el mapa tiene más caminos de los que usa la oleada.
- Hay archivos temporales del editor en `scenes/` (`Level.tscn*.tmp`, `MainMenu.tscn*.tmp`).
