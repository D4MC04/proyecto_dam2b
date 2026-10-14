# Niveles: nivel, mapa, cuadrícula y oleadas

## Escena Level

`scenes/Level.tscn` + `scripts/level/Level.gd` (clase `Level`). Nodos hijos:

| Nodo | Script | Función |
|---|---|---|
| `LevelState` | `scripts/level/LevelState.gd` | Dinero, torre seleccionada y lo inspeccionado en la ficha |
| `Grid` | `scripts/level/Grid.gd` | Qué casillas son camino o hueco y cuáles están ocupadas |
| `Spawner` | `scripts/level/Spawner.gd` | Lanza las oleadas, crea sus enemigos y cuenta los vivos |
| `BuildManager` | `scripts/level/BuildManager.gd` | Coloca torres; ver [torres.md](torres.md) |

`Level.setup(data: LevelData)`:

1. Instancia `data.map`, lo llama `Map` y lo pone como primer hijo.
2. `_center_map()`: centra el mapa en horizontal en el área de juego (ver "Centrado del mapa").
3. Guarda `data.towers` en `towers`.
4. `grid.setup(map.logic_map)`.
5. `spawner.setup(map.get_paths(), data.waves)`.

Conexiones hechas en `_ready`:

- `spawner.enemy_died(reward)` llama a `game_state.add_money`.
- `spawner.enemy_reached_end` llama a `_lose`, que emite `lost`.
- `spawner.all_waves_cleared` llama a `_win`, que emite `won`.
- Un nivel acaba una sola vez: `_lose` y `_win` comparten la marca `_finished` y, tras la primera de las dos, ninguna vuelve a emitir. Si el último enemigo de la última oleada llega al final, el `Spawner` emite antes `enemy_reached_end` que `all_waves_cleared`, así que gana la derrota y `won` no se emite.
- `build_manager.state = game_state`.

## LevelState

- `money` empieza en 5000.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, emite `money_changed` y devuelve `true`.
- `selected_tower: TowerData` es la torre que se colocará al hacer clic y la única fuente de la selección. Su setter emite `selected_tower_changed(data)` solo si el valor cambia. Lo escribe `LevelUI` cuando la barra lateral lo pide y `BuildManager` (a `null`) al cancelar con clic derecho.
- `inspected: Resource` es lo que enseña la ficha (de momento un `TowerData`; es `Resource` para que valga también para enemigos) y la única fuente de lo inspeccionado. Su setter emite `inspected_changed(data)` solo si el valor cambia. Empieza en null y solo lo escribe `LevelUI`; deseleccionar no lo toca. Al reiniciar se crea un `LevelState` nuevo, así que vuelve a null.

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

Lleva el ciclo de oleadas del nivel: cuándo se lanzan, qué enemigos quedan vivos y el modo AUTO.

### Ciclo de oleadas

- `setup(paths, waves)` solo guarda los datos. El nivel empieza en espera, sin enemigos, para dejar construir; la primera oleada se lanza con el botón de la pestaña Oleadas o con AUTO.
- `start_next_wave() -> bool` lanza la siguiente oleada: copia sus entradas, las ordena por `time`, pone el reloj a 0 y emite `wave_started(index, total)` (índice desde 0). Devuelve `false` y no hace nada si el nivel no está limpio (la actual sigue sacando o quedan enemigos vivos) o no quedan oleadas (`can_start_next_wave()`). Así nunca conviven enemigos de dos oleadas.
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_spawn_finished(index)`.
- `_spawn(entry)` instancia `scenes/entities/Enemy.tscn` como hijo del `Path2D` número `entry.path_index % paths.size()`, llama a `enemy.setup(entry.enemy_data)`, lo apunta como vivo y conecta sus señales `died` y `reached_end`.

### Enemigos vivos

`_alive` es un `Dictionary[Enemy, bool]`. Se añade el enemigo al crearlo y se borra al recibir `died` o `reached_end`; solo la primera de esas señales cuenta, así que cada enemigo se descuenta una vez aunque muera dos veces o muera y llegue al final en el mismo frame. Solo entonces se reenvía como `enemy_died(reward)` o `enemy_reached_end`. No se usa `tree_exiting`: al reiniciar se libera el nivel entero y no se emite nada. `get_alive_count()` devuelve la cuenta.

### Estados

| Función | Significado |
|---|---|
| `get_wave_index()` | Última oleada lanzada; -1 antes de la primera |
| `is_spawning()` | La oleada actual aún tiene entradas pendientes |
| `has_finished_spawning()` | No quedan entradas (o no se ha lanzado ninguna); puede haber enemigos vivos |
| `is_clear()` | No quedan entradas ni enemigos vivos |
| `has_waves_left()` | Quedan oleadas por lanzar |
| `can_start_next_wave()` | Está limpio y quedan oleadas |

### Señales

| Señal | Cuándo |
|---|---|
| `wave_started(index, total)` | Al lanzar una oleada |
| `wave_spawn_finished(index)` | Al crear el último enemigo de la oleada |
| `wave_cleared(index)` | Cuando, tras lanzar la oleada `index`, el nivel pasa a limpio |
| `all_waves_cleared` | Cuando se limpia la última oleada. La escucha `Level` (emite `won`) |
| `auto_waves_changed(enabled)` | Al cambiar `auto_waves` |
| `enemy_died(reward)`, `enemy_reached_end` | Reenvío de las señales del enemigo, una vez por enemigo |

### Modo AUTO

`auto_waves: bool` vive en el `Spawner` y empieza en `false`; como el nivel se instancia de nuevo al reiniciar, también vuelve a `false`. La UI solo lo lee y lo cambia.

- Con AUTO activo, cuando el nivel queda limpio y quedan oleadas, empieza una cuenta atrás de `AUTO_WAVE_DELAY` (1,5 s) y después se lanza la siguiente.
- Activarlo estando limpio (también antes de la primera oleada) arranca esa misma cuenta atrás.
- Desactivarlo la cancela. Lanzar una oleada a mano también.
- La cuenta atrás corre en `_process` del `Spawner`, con `process_mode` heredado, así que la pausa del juego la congela.

## Mapa

Base: `scenes/maps/Map.tscn` + `scripts/level/Map.gd` (clase `Map`). Nodos:

- `VisualMap` (`TileMapLayer`): lo que se ve.
- `LogicMap` (`TileMapLayer`, tileset `resources/tilesets/logic_tileset.tres`): marca el tipo de cada casilla.
- `Paths` (`Node2D`): sus hijos son los `Path2D`. `Map.get_paths()` los devuelve en orden.
- `SpaceStation`: instancia de `scenes/entities/Base.tscn`; ver [base.md](base.md).

`Map.get_used_rect()` devuelve el rectángulo útil en coordenadas locales de `Map`: la unión del rectángulo de casillas usadas de `LogicMap` (en píxeles) y del sprite de `SpaceStation` con su escala.

### Centrado del mapa

El área de juego va de x = 80 a x = 560 (ver [ui.md](ui.md)), con centro en `Level.GAME_AREA_CENTER_X` = 320. `Level._center_map()` suma a `map.position.x` la distancia, redondeada a píxeles enteros, entre ese centro y el centro del rectángulo útil (contando la posición propia de `Map`). En vertical no se mueve. Ningún `.tscn` de mapa lleva posiciones de centrado: un mapa nuevo se centra solo, y al reiniciar el nivel se vuelve a centrar.

`Grid`, `BuildManager` y los enemigos no necesitan saberlo: `Grid` convierte con `to_local`/`to_global` de `LogicMap`, las torres y la vista previa se colocan con `grid.center` y los enemigos son hijos de los `Path2D` del mapa.

Resultado con los mapas actuales (px de pantalla):

| Nivel | Posición de `Map` | Rectángulo útil | `VisualMap` |
|---|---|---|---|
| 1 | (24, 0) | 136..504 | 24..520 |
| 2 | (56, 0) | 104..536 | 40..568 |
| 3 | (88, 0) | 104..536 | 88..584 |
| 4 | (88, 0) | 104..536 | 88..552 |
| 5 | (88, 0) | 136..504 | 72..600 |
| 6 | (88, 0) | 136..504 | 72..600 |

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

- `Grid.get_kind` y `Grid.path_cells` no se usan fuera de `Grid`.
- `tileset.tres` declara una capa de datos `buildable` (bool) que ningún script lee.
- No hay en el repositorio ningún script que genere los `TileMapLayer` a partir de datos, que es lo que pide `CLAUDE.md`.
- `Level7.tscn` a `Level10.tscn`, `Level2.tscn`, `Level5.tscn`, `Level6.tscn` y la carpeta `redesign/` no están en ningún `LevelData`. Los mapas 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `resources/level_data/level_5.tres` existe y tiene el mismo contenido que el subrecurso de `GameData.tscn`, pero `GameData` no lo usa.
- En los niveles 2, 5 y 6 el mapa tiene más caminos de los que usa la oleada.
- Mapas de hierba que no cubren de lado a lado el área de juego (80..560) y dejan fondo negro: nivel 1, 40 px a la derecha (`VisualMap` acaba en 520); nivel 3, 8 px a la izquierda; nivel 4, 8 px a cada lado. Los de espacio tienen `FondoEspacio` detrás y no dejan huecos.
- Hay archivos temporales del editor en `scenes/` (`Level.tscn*.tmp`, `MainMenu.tscn*.tmp`).
