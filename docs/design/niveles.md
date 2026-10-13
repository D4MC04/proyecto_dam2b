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
2. `_center_map()`: centra el mapa en horizontal en el área de juego (ver "Centrado del mapa").
3. Guarda `data.towers` en `towers`.
4. `grid.setup(map.logic_map)`.
5. `spawner.setup(map.get_paths(), data.waves)`.

Conexiones hechas en `_ready`:

- `spawner.enemy_died(reward)` llama a `game_state.add_money`.
- `spawner.enemy_reached_end` llama a `_lose`, que emite `lost`.
- `build_manager.state = game_state`.

## LevelState

- `money` empieza en 1000.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, emite `money_changed` y devuelve `true`.
- `selected_tower: TowerData` es la torre que se colocará al hacer clic y la única fuente de la selección. Su setter emite `selected_tower_changed(data)` solo si el valor cambia. Lo escribe `LevelUI` cuando la barra lateral lo pide y `BuildManager` (a `null`) al cancelar con clic derecho.

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
- `start_next_wave()` no hace nada si hay una oleada activa o no quedan más. Si arranca, copia las entradas, las ordena por `time`, pone el reloj a 0 y emite `wave_started(index, total)` (índice desde 0). Como `setup` arranca la primera oleada, esa emisión ocurre antes de que la UI se conecte: `LevelUI.setup` lee el estado actual con `get_wave_index()` (-1 si no ha empezado ninguna).
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_finished(index)` y se desactiva.
- `_spawn(entry)` instancia `scenes/entities/Enemy.tscn` como hijo del `Path2D` número `entry.path_index % paths.size()`, llama a `enemy.setup(entry.enemy_data)` y reenvía sus señales `died` y `reached_end` como `enemy_died` y `enemy_reached_end`.

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

- `start_next_wave()` solo se llama desde `setup`, y nadie escucha `wave_finished`. Con los datos actuales no afecta porque cada nivel tiene una única oleada, pero una segunda `WaveData` no llegaría a empezar.
- Al terminar de salir los enemigos no pasa nada más: no hay victoria ni final de nivel.
- `Grid.get_kind` y `Grid.path_cells` no se usan fuera de `Grid`.
- `tileset.tres` declara una capa de datos `buildable` (bool) que ningún script lee.
- No hay en el repositorio ningún script que genere los `TileMapLayer` a partir de datos, que es lo que pide `CLAUDE.md`.
- `Level7.tscn` a `Level10.tscn`, `Level2.tscn`, `Level5.tscn`, `Level6.tscn` y la carpeta `redesign/` no están en ningún `LevelData`. Los mapas 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `resources/level_data/level_5.tres` existe y tiene el mismo contenido que el subrecurso de `GameData.tscn`, pero `GameData` no lo usa.
- En los niveles 2, 5 y 6 el mapa tiene más caminos de los que usa la oleada.
- Mapas de hierba que no cubren de lado a lado el área de juego (80..560) y dejan fondo negro: nivel 1, 40 px a la derecha (`VisualMap` acaba en 520); nivel 3, 8 px a la izquierda; nivel 4, 8 px a cada lado. Los de espacio tienen `FondoEspacio` detrás y no dejan huecos.
- Hay archivos temporales del editor en `scenes/` (`Level.tscn*.tmp`, `MainMenu.tscn*.tmp`).
