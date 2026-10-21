# Niveles: nivel, mapa, cuadrícula y oleadas

## Escena Level

`scenes/Level.tscn` + `scripts/level/Level.gd` (clase `Level`). Nodos hijos:

| Nodo | Script | Función |
|---|---|---|
| `LevelState` | `scripts/level/LevelState.gd` | Dinero, torre seleccionada, lo inspeccionado en la ficha y los contadores de la partida |
| `Grid` | `scripts/level/Grid.gd` | Qué casillas son camino o hueco y cuáles están ocupadas |
| `Spawner` | `scripts/level/Spawner.gd` | Lanza las oleadas, crea sus enemigos y cuenta los vivos |
| `BuildManager` | `scripts/level/BuildManager.gd` | Coloca torres; ver [torres.md](torres.md) |
| `Powers` | `scripts/level/Powers.gd` | Poderes del jugador (meteorito y congelar); ver "Poderes" |

`Level.setup(data: LevelData)`:

1. Instancia `data.map`, lo llama `Map` y lo pone como primer hijo.
2. `_center_map()`: centra el mapa en el área de juego, en horizontal y en vertical (ver "Centrado del mapa").
3. Guarda `data.towers` en `towers`.
4. `grid.setup(map.logic_map)`.
5. `spawner.setup(map.get_paths(), data.waves)`.
6. Guarda en `base` el nodo `SpaceStation` del mapa, conecta `spawner.enemy_reached_end` a `base.take_damage` (el daño lo trae la señal, de `EnemyData.base_damage`) y `base.destroyed` a `_lose`.

Conexiones hechas en `_ready`:

- `spawner.enemy_died(reward)` llama a `game_state.register_enemy_destroyed`, que cuenta el enemigo y suma la recompensa.
- `spawner.all_waves_cleared` llama a `_win`, que llama a `build_manager.stop_building()` y emite `won`.
- `build_manager.state = game_state`.

`_lose()` llama a `build_manager.stop_building()`, espera a `base.animation_finished` (el final de la explosión) y emite `lost`. Se espera porque la derrota acaba pausando el árbol y cortaría la animación.

Un nivel acaba una sola vez: `_lose` y `_win` comparten la marca `_finished` y, tras la primera de las dos, ninguna vuelve a emitir. `_lose` pone la marca antes de esperar a la explosión, así que durante la explosión el nivel ya no puede ganarse. Si el último enemigo de la última oleada destruye la estación, el `Spawner` emite antes `enemy_reached_end` que `all_waves_cleared`, así que gana la derrota y `won` no se emite.

Tras perder o ganar, el nivel deja de construir por su cuenta, sin depender de la UI: `BuildManager` no coloca torres ni enseña la vista previa (ver [torres.md](torres.md)). Durante la cámara lenta de la derrota y el respiro de la victoria el juego sigue corriendo. Durante la cámara lenta los enemigos siguen moviéndose y las torres disparando; los que mueran aún cuentan y dan dinero, pero el resultado no cambia.

`get_run_stats() -> RunStats` construye el resumen de la partida: oleada alcanzada (`spawner.get_wave_index() + 1`, 0 si no se lanzó ninguna), total de oleadas (`spawner.waves.size()`), enemigos destruidos y dinero gastado (de `LevelState`). Lo usa `Game` al perder.

**`RunStats`** (`scripts/level/RunStats.gd`, `RefCounted`): objeto de datos con `wave_reached`, `wave_total`, `enemies_destroyed` y `money_spent`, todos `int`. Se crea con `RunStats.new(reached, total, destroyed, spent)`. Lo pinta `RunSummary` (ver [ui.md](ui.md)).

## Poderes

`Powers` (`scripts/level/Powers.gd`, `Node2D` con `z_index = 1`, último hijo de `Level`): los poderes del jugador. Su `state` (`LevelState`) se asigna en `Level.tscn`. Como el nivel se crea de nuevo al empezar y al reiniciar, los dos poderes empiezan listos. Las recargas bajan en `_process`, así que siguen `Engine.time_scale` (×2 las acelera) y se paran con la pausa. Los botones están en la ficha (ver [ui.md](ui.md)).

| Poder (`Powers.Power`) | Tecla | Efecto | Recarga |
|---|---|---|---|
| `METEOR` | Q | Modo apuntar; al hacer clic cae un meteorito: `METEOR_DAMAGE` (150) a todos los enemigos a `METEOR_RADIUS` (40 px) o menos del punto | 45 s |
| `FREEZE` | E | Todos los enemigos vivos a `FREEZE_FACTOR` (30 %) de velocidad durante `FREEZE_TIME` (4 s), con `Enemy.slow` y la escarcha del Cryo (`cryo_frost.tres`) | 60 s |

- `use(power)`: si el poder no está listo no hace nada. Meteorito: si ya se apuntaba, cancela; si no, suelta la torre seleccionada (`state.selected_tower = null`) y entra en modo apuntar. Congelar se lanza ya.
- **Apuntado:** pinta en `_draw` un círculo del radio del área en el cursor (relleno ámbar al 15 % y borde de 1 px `#ecb23c`, sin antialiasing). En `_unhandled_input`, clic izquierdo lanza el meteorito ahí y clic derecho cancela; los dos marcan el evento como gestionado. Mientras se apunta, `BuildManager` ignora la entrada (su `powers`, asignado en la escena), así que no coloca ni selecciona torres. Elegir torre (`selected_tower_changed` con una torre) cancela el apuntado. `cancel_aiming()` lo quita.
- **Meteorito:** la recarga empieza al hacer clic. El cometa del fondo (`cometa.png`) cae en `METEOR_FALL_TIME` (0,3 s) desde `METEOR_FALL_OFFSET` (-90, -150) respecto al punto; al llegar, explosión del lanzacohetes (`rocket_launcher_impact.tres`) a ×3 y `RocketExplosion.wav` (bus SFX), y el daño a los enemigos del área con `hp > 0`.

## LevelState

- `money` empieza en 5000.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, suma `amount` a `money_spent`, emite `money_changed` y devuelve `true`.
- Contadores de la partida: `enemies_destroyed` y `money_spent`, que empiezan en 0. `register_enemy_destroyed(reward)` suma 1 a `enemies_destroyed` y llama a `add_money(reward)`. No hace falta reiniciarlos: al reiniciar se crea un `LevelState` nuevo.
- `selected_tower: TowerData` es la torre que se colocará al hacer clic y la única fuente de la selección. Su setter emite `selected_tower_changed(data)` solo si el valor cambia. Lo escribe `LevelUI` cuando la barra lateral lo pide y `BuildManager` (a `null`) al cancelar con clic derecho.
- `inspected: Resource` es lo que enseña la ficha (de momento un `TowerData`; es `Resource` para que valga también para enemigos) y la única fuente de lo inspeccionado. Su setter emite `inspected_changed(data)` solo si el valor cambia. Empieza en null y solo lo escribe `LevelUI`; deseleccionar no lo toca. Al reiniciar se crea un `LevelState` nuevo, así que vuelve a null.

## Datos de nivel

- `LevelData` (`scripts/resources/LevelData.gd`): `map: PackedScene`, `towers: Array[TowerData]`, `waves: Array[WaveData]`.
- `WaveData`: `entries: Array[SpawnEntry]`.
- `SpawnEntry`: `enemy_data: EnemyData`, `time: float` (segundos desde el inicio de la oleada), `path_index: int`.

Niveles registrados en `GameData.levels`:

| Nivel | Mapa | Torres disponibles | Enemigos por oleada (1 + 2 + 3) | Último enemigo de cada una (s) | Caminos usados / en el mapa |
|---|---|---|---|---|---|
| 1 | `maps/Level1.tscn` | Cañón doble, Cañón pesado, Láser | 7 + 12 + 6 | 8,5 / 12 / 7,5 | 1 / 1 |
| 2 | `maps/espacio/Level2_espacio.tscn` | las anteriores + Cryo | 7 + 12 + 13 | 8,5 / 12 / 12,5 | 1 / 2 |
| 3 | `maps/Level3.tscn` | las anteriores + Tesla | 16 + 12 + 12 | 18 / 12,5 / 12,5 | 1 / 1 |
| 4 | `maps/Level4.tscn` | las anteriores + Rail | 19 + 12 + 19 | 22 / 12 / 21 | 2 / 2 |
| 5 | `maps/espacio/Level5_espacio.tscn` | las anteriores + Disintegrator | 19 + 24 + 17 | 22 / 25,5 / 17,5 | 1 / 4 |
| 6 | `maps/espacio/Level6_espacio.tscn` | las 7 | 28 + 24 + 23 | 31,5 / 26 / 25,5 | 4 / 8 |

Cada nivel tiene tres `WaveData` (`resources/wave_data/level_N.tres`, `level_N_2.tres` y `level_N_3.tres`): son la oleada original del nivel partida en tres tramos consecutivos, con los tiempos de cada una desde 3 s (la primera) o 2 s (las otras). Los niveles 1, 2, 3, 4 y 6 están en `resources/level_data/level_N.tres`; el 5 está definido como subrecurso dentro de `scenes/GameData.tscn`.

## Spawner

Lleva el ciclo de oleadas del nivel: cuándo se lanzan, qué enemigos quedan vivos y el modo AUTO.

### Ciclo de oleadas

- `setup(paths, waves)` solo guarda los datos. El nivel empieza en espera, sin enemigos, para dejar construir; la primera oleada se lanza con el botón de la pestaña Oleadas o con AUTO.
- `start_next_wave() -> bool` lanza la siguiente oleada: copia sus entradas, las ordena por `time`, pone el reloj a 0 y emite `wave_started(index, total)` (índice desde 0). Devuelve `false` y no hace nada si el nivel no está limpio (la actual sigue sacando o quedan enemigos vivos) o no quedan oleadas (`can_start_next_wave()`). Así nunca conviven enemigos de dos oleadas.
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_spawn_finished(index)`.
- `_spawn(entry)` instancia `scenes/entities/Enemy.tscn` como hijo del `Path2D` número `entry.path_index % paths.size()`, llama a `enemy.setup(entry.enemy_data)`, lo apunta como vivo y conecta sus señales `died` y `reached_end`.

### Enemigos vivos

`_alive` es un `Dictionary[Enemy, bool]`. Se añade el enemigo al crearlo y se borra al recibir `died` o `reached_end`; solo la primera de esas señales cuenta, así que cada enemigo se descuenta una vez aunque muera dos veces o muera y llegue al final en el mismo frame. Solo entonces se reenvía como `enemy_died(reward)` o `enemy_reached_end(damage)`. No se usa `tree_exiting`: al reiniciar se libera el nivel entero y no se emite nada. `get_alive_count()` devuelve la cuenta.

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
| `enemy_died(reward)`, `enemy_reached_end(damage)` | Reenvío de las señales del enemigo, una vez por enemigo |

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

El área de juego va de x = 128 a x = 832 y de y = 0 a y = 540 (ver [ui.md](ui.md)), con centro en `Level.GAME_AREA_CENTER` = (480, 270). `Level._center_map()` suma a `map.position` la distancia, redondeada a píxeles enteros en los dos ejes, entre ese centro y el centro del rectángulo útil (contando la posición propia de `Map`). Ningún `.tscn` de mapa lleva posiciones de centrado: un mapa nuevo se centra solo, y al reiniciar el nivel se vuelve a centrar.

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

Todos los mapas (y la plantilla `Map.tscn`) llevan `Background`, instancia de `SpaceBackground.tscn`, como primer hijo de `Map`. Hay dos familias de mapas:

- **Hierba** (`scenes/maps/Level1.tscn` a `Level10.tscn` y `scenes/maps/redesign/`): `VisualMap` usa `resources/tilesets/tileset.tres` (hierba, piedra, plantas, objetos, estructuras, muros). `LogicMap` es visible con alfa 0,39.
- **Espacio** (`scenes/maps/espacio/`): añaden las capas `Polvo`, `Planetas` y `Pista`, todas con `resources/tilesets/tileset_espacio.tres`. `LogicMap` tiene `visible = false`. El nodo `Map` está en la posición (8, 0).

### Decoración de los mapas de espacio

La decoración (rocas, chatarra, piezas animadas) está en la capa `VisualMap`. En los niveles 2, 5 y 6 sigue las mismas reglas:

- El camino y las casillas pegadas a él quedan sin rocas: ese hueco es el corredor que se ve en pantalla.
- A 2 casillas del camino hay una hilera de rocas casi continua a cada lado, salvo donde hay un planeta de torre.
- En el nivel 5 los tramos de las filas 1 y 15 van pegados al borde: en las filas 0 y 16 solo hay chatarra y piedras pequeñas.
- Los tiles se dibujan centrados en su casilla: una pieza de 2x2 anclada en (x, y) ocupa de x-0,5 a x+1,5.

La `VisualMap` de los niveles 5 y 6 se generó una vez con `scripts/tools/space_decoration.gd` a partir de las cuadrículas de texto `resources/map_data/level_5_decor.txt` y `level_6_decor.txt` (el formato está descrito en la cabecera del script):

```
godot --headless --path . -s scripts/tools/space_decoration.gd
```

**La fuente de verdad es el `.tscn`**, que se puede retocar a mano en el editor. Los `.txt` no se actualizan con esos retoques: volver a ejecutar el script sobrescribe la `VisualMap` de los dos niveles con lo que digan los `.txt` y se pierde lo cambiado en el editor. El script solo sustituye el `tile_map_data` de las capas que aparecen en cada `.txt`; no toca el resto de la escena.

### SpaceBackground

`scenes/maps/SpaceBackground.tscn` es el fondo común de todos los mapas y cubre los 704x540 px del área de juego. Tiene:

- `Nebula`: `Parallax2D` con desplazamiento automático de -3 px/s y la textura `fondo_nebulosa_tall.png` (640x544, repetida solo en horizontal).
- `GiantPlanet`: planeta de 224x224 abajo a la derecha, cortado por el borde inferior.
- `Stars`: `Parallax2D` a -6 px/s, repetida en los dos ejes (640x272), con un `AnimatedSprite2D` (`Twinkle`) de 8 frames.
- `Comet`: `scripts/level/Comet.gd`, sprite que espera entre 6 y 15 s, aparece a la izquierda a una altura al azar de la mitad de arriba (hasta 270 px), cruza los 704 px con velocidad (150, 22) px/s y vuelve a esperar. Su temporizador se detiene con la pausa.

Lo que sobresale del área queda tapado por las barras, que son opacas.

`Background` no cuenta en `Map.get_used_rect()`, así que no afecta al centrado. Como vive dentro de `Map`, `Level._center_map()` llama a `Map.place_background(GAME_AREA_RECT)` después de mover el mapa: coloca `Background` en coordenadas globales en el origen del área de juego, (128, 0). Un mapa sin `Background` no hace nada.

## Grid

`Grid.setup(logic_map)` recorre las casillas usadas de `LogicMap` y lee el dato personalizado `kind` de cada tile:

- `"slot"`: se guarda en `slot_cells`.
- cualquier otro valor (`"path"` y `"scenery"`, que define el tileset): no se guarda.

Funciones:

- `can_build(c)`: la casilla es `slot` y no tiene torre.
- `register_tower(c, t)`: apunta la torre y la borra del registro cuando el nodo sale del árbol.
- `cell(p)` y `center(c)`: conversión entre posición global y casilla.

## Dudas

- `tileset.tres` declara una capa de datos `buildable` (bool) que ningún script lee.
- Solo la `VisualMap` de los niveles 5 y 6 tiene script y datos de generación; el resto de capas y mapas no.
- En el nivel 6 hay un planeta de torre en la casilla (15, 9), debajo de la estación.
- `Level7.tscn` a `Level10.tscn`, `Level2.tscn`, `Level5.tscn`, `Level6.tscn` y la carpeta `redesign/` no están en ningún `LevelData`. Los mapas 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `redesign/Level6.tscn` tenía el mismo uid que `Level6.tscn` y Godot avisaba `UID duplicate`. Se le dio un uid nuevo; la carpeta `redesign/` se conserva sin cambios.
- `resources/level_data/level_5.tres` existe y tiene el mismo contenido que el subrecurso de `GameData.tscn`, pero `GameData` no lo usa.
- Todos los caminos de los niveles 1 a 6 (`Level1`, `Level3`, `Level4`, `espacio/Level2_espacio`, `Level5_espacio`, `Level6_espacio`) acaban en la posición de `SpaceStation`: se alargó el último punto de cada curva.
- En los niveles 2, 5 y 6 el mapa tiene más caminos de los que usa la oleada.
- Los mapas (como mucho unos 480x272) no llenan el área de juego de 704x540: alrededor se ve el fondo de espacio, y los enemigos aparecen y desaparecen en el borde del mapa.
