# Niveles: nivel, mapa, cuadrícula y oleadas

## Escena Level

`scenes/Level.tscn` + `scripts/level/Level.gd` (clase `Level`). Nodos hijos:

| Nodo | Script | Función |
|---|---|---|
| `LevelState` | `scripts/level/LevelState.gd` | Dinero, torre seleccionada, lo inspeccionado en la ficha y los contadores de la partida |
| `Grid` | `scripts/level/Grid.gd` | Qué casillas son camino o hueco y cuáles están ocupadas |
| `Spawner` | `scripts/level/Spawner.gd` | Lanza las oleadas, crea sus enemigos y cuenta los vivos |
| `BuildManager` | `scripts/level/BuildManager.gd` | Coloca torres; ver [torres.md](torres.md) |
| `Powers` | `scripts/level/Powers.gd` | Poderes del jugador (meteorito, congelar y ataque orbital); ver "Poderes" |

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
- `spawner.wave_cleared` llama a `_on_wave_cleared`: menos en la última oleada, si no llegó ningún enemigo a la estación (`_leaks_this_wave`, que `wave_started` pone a 0 y `enemy_reached_end` incrementa) suma `PERFECT_WAVE_BONUS` y enseña "PERFECTA +25€" como `FloatingText` sobre la estación durante 4 s.
- `build_manager.state = game_state`.

`_lose()` llama a `build_manager.stop_building()`, espera a `base.animation_finished` (el final de la explosión) y emite `lost`. Se espera porque la derrota acaba pausando el árbol y cortaría la animación.

Un nivel acaba una sola vez: `_lose` y `_win` comparten la marca `_finished` y, tras la primera de las dos, ninguna vuelve a emitir. `_lose` pone la marca antes de esperar a la explosión, así que durante la explosión el nivel ya no puede ganarse. Si el último enemigo de la última oleada destruye la estación, el `Spawner` emite antes `enemy_reached_end` que `all_waves_cleared`, así que gana la derrota y `won` no se emite.

Detrás del mapa, `Level.tscn` tiene dos nodos de decoración con los scripts del menú: `Comets` y `Satellites` (z_index -1, para que queden por debajo de `Map` y de las barras). Están en x = 128 con `area_size` 704x540, o sea solo cruzan el área de juego. Son menos frecuentes que en el menú: cometas cada 8 a 16 s (`wait_min`/`wait_max`) y satélites con 30 a 60 s entre uno y otro (`gap_min`/`gap_max`). Sobre los mapas de espacio el fondo `SpaceBackground` los tapa.

Tras perder o ganar, el nivel deja de construir por su cuenta, sin depender de la UI: `BuildManager` no coloca torres ni enseña la vista previa (ver [torres.md](torres.md)). Durante la cámara lenta de la derrota y el respiro de la victoria el juego sigue corriendo. Durante la cámara lenta los enemigos siguen moviéndose y las torres disparando; los que mueran aún cuentan y dan dinero, pero el resultado no cambia.

`get_run_stats() -> RunStats` construye el resumen de la partida: oleada alcanzada (`spawner.get_wave_index() + 1`, 0 si no se lanzó ninguna), total de oleadas (`spawner.waves.size()`), enemigos destruidos y dinero gastado (de `LevelState`). Lo usa `Game` al perder.

**`RunStats`** (`scripts/level/RunStats.gd`, `RefCounted`): objeto de datos con `wave_reached`, `wave_total`, `enemies_destroyed` y `money_spent`, todos `int`. Se crea con `RunStats.new(reached, total, destroyed, spent)`. Lo pinta `RunSummary` (ver [ui.md](ui.md)).

## Poderes

`Powers` (`scripts/level/Powers.gd`, `Node2D` con `z_index = 1`, último hijo de `Level`): los poderes del jugador. Su `state` (`LevelState`) se asigna en `Level.tscn`. Como el nivel se crea de nuevo al empezar y al reiniciar, los tres poderes empiezan listos. Las recargas bajan en `_process`, así que siguen `Engine.time_scale` (×2 las acelera) y se paran con la pausa. Los botones están en la ficha (ver [ui.md](ui.md)). Emite `power_used(power)` al lanzar un poder (el meteorito, al caer; el ataque orbital, al empezar el rayo), que escucha el tutorial.

| Poder (`Powers.Power`) | Tecla | Efecto | Recarga |
|---|---|---|---|
| `METEOR` | Q | Modo apuntar; al hacer clic cae un meteorito: `METEOR_DAMAGE` (150) a todos los enemigos a `METEOR_RADIUS` (40 px) o menos del punto | 45 s |
| `FREEZE` | E | Todos los enemigos vivos a `FREEZE_FACTOR` (30 %) de velocidad durante `FREEZE_TIME` (4 s), con `Enemy.slow` y la escarcha del Cryo (`cryo_frost.tres`) | 60 s |
| `ORBITAL` | R | Modo apuntar (una franja horizontal sigue al cursor); al hacer clic, un rayo vertical recorre esa fila de izquierda a derecha de `GAME_AREA_RECT` en `ORBITAL_TIME` (2 s) y daña `ORBITAL_DPS` (400/s) a los enemigos vivos a `ORBITAL_HALF_WIDTH` (6 px) en x y `ORBITAL_HALF_HEIGHT` (16 px) en y de él | 75 s |

- `use(power)`: si el poder no está listo no hace nada. Meteorito y ataque orbital: si ya se apuntaba ese poder, cancela; si no, suelta la torre seleccionada (`state.selected_tower = null`) y entra en modo apuntar. Congelar se lanza ya.
- **Apuntado:** pinta en `_draw` un círculo del radio del área en el cursor (relleno ámbar al 15 % y borde de 1 px `#ecb23c`, sin antialiasing). En `_unhandled_input`, clic izquierdo lanza el meteorito ahí y clic derecho cancela; los dos marcan el evento como gestionado. Mientras se apunta, `BuildManager` ignora la entrada (su `powers`, asignado en la escena), así que no coloca ni selecciona torres. Elegir torre (`selected_tower_changed` con una torre) cancela el apuntado. `cancel_aiming()` lo quita.
- **Ataque orbital:** la recarga empieza al hacer clic. El rayo es un zigzag cian con núcleo blanco y destello (`_draw_bolt`, se re-sortea cada frame para que parpadee) que cae desde arriba en `ORBITAL_FALL_TIME` (0,15 s; hasta entonces no daña) y luego barre. Mientras dura, el mapa tiembla con `Level.shake_map(ORBITAL_SHAKE_DAMAGE)` cada `ORBITAL_SHAKE_INTERVAL` (0,15 s). Se mueve en `_process`, así que sigue la velocidad del juego y la pausa. `get_aimed_power()` da el poder apuntado (-1 si ninguno); `PowerButton` lo usa para el ámbar.
- **Meteorito:** la recarga empieza al hacer clic. El cometa del fondo (`cometa.png`) cae en `METEOR_FALL_TIME` (0,3 s) desde `METEOR_FALL_OFFSET` (-90, -150) respecto al punto; al llegar, explosión del lanzacohetes (`rocket_launcher_impact.tres`) a ×3 y `RocketExplosion.wav` (bus SFX), y el daño a los enemigos del área con `hp > 0`.

## LevelState

- `money` empieza en 5000.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, suma `amount` a `money_spent`, emite `money_changed` y devuelve `true`.
- `PERFECT_WAVE_BONUS` (25): premio por limpiar una oleada sin que llegue ningún enemigo a la estación. Lo aplica `Level._on_wave_cleared` (ver "Escena Level").
- Contadores de la partida: `enemies_destroyed` y `money_spent`, que empiezan en 0. `register_enemy_destroyed(reward)` suma 1 a `enemies_destroyed` y llama a `add_money(reward)`. No hace falta reiniciarlos: al reiniciar se crea un `LevelState` nuevo.
- `selected_tower: TowerData` es la torre que se colocará al hacer clic y la única fuente de la selección. Su setter emite `selected_tower_changed(data)` solo si el valor cambia. Lo escribe `LevelUI` cuando la barra lateral lo pide y `BuildManager` (a `null`) al cancelar con clic derecho.
- `inspected: Resource` es lo que enseña la ficha (de momento un `TowerData`; es `Resource` para que valga también para enemigos) y la única fuente de lo inspeccionado. Su setter emite `inspected_changed(data)` solo si el valor cambia. Empieza en null y solo lo escribe `LevelUI`; deseleccionar no lo toca. Al reiniciar se crea un `LevelState` nuevo, así que vuelve a null.

## Datos de nivel

- `LevelData` (`scripts/resources/LevelData.gd`): `map: PackedScene`, `towers: Array[TowerData]`, `waves: Array[WaveData]`.
- `WaveData`: `entries: Array[SpawnEntry]` y `health_multiplier: float` (1.0 por defecto; multiplica la vida máxima de todos los enemigos de la oleada, también los trozos de la Divisora; la recompensa no cambia).
- `SpawnEntry`: `enemy_data: EnemyData`, `time: float` (segundos desde el inicio de la oleada), `path_index: int`.

Niveles registrados en `GameData.levels`:

| Nivel | Mapa | Torres disponibles | Oleadas | Naves por oleada (1.ª → última) | Naves nuevas (protagonistas) | Caminos |
|---|---|---|---|---|---|---|
| 1 | `maps/levels/Level1.tscn` | Cañón doble, Cañón pesado, Láser | 5 | 7 → 13 | Darts y Wasp | 1 |
| 2 | `maps/levels/Level2.tscn` | las anteriores + Cryo | 6 | 10 → 21 | Nave normal y UFO | 2 |
| 3 | `maps/levels/Level3.tscn` | las anteriores + Tesla | 6 | 11 → 26 | Nave agresiva y Spikey | 2 |
| 4 | `maps/levels/Level4.tscn` | las anteriores + Rail | 7 | 9 → 24 | Acorazado | 2 |
| 5 | `maps/levels/Level5.tscn` | las anteriores + Disintegrator | 7 | 11 → 33 | Ariete y Divisora | 2 |
| 6 | `maps/levels/Level6.tscn` | las 7 | 8 | 17 → 42 (la última con la Nodriza) | Reparadora | 3 |
| 7 | `maps/levels/Level7.tscn` | las 7 | 9 | 21 → 47 | Espectro | 4 |
| 8 | `maps/levels/Level8.tscn` | las 7 | 9 | 19 → 48 | Saboteadora | 4 |
| 9 | `maps/levels/Level9.tscn` | las 7 | 10 | 27 → 60 (la última con la Nodriza) | Espectro, Saboteadora, Divisora y Reparadora (y todas las demás) | 8 |

Las oleadas son `WaveData` en `resources/wave_data/level_N.tres` (la primera) y `level_N_K.tres` (la K). Los niveles 1 a 4 y 6 a 9 están en `resources/level_data/level_N.tres`; el 5 está definido como subrecurso dentro de `scenes/GameData.tscn` (`level_5.tres` también existe y lleva las mismas oleadas).

### Generador de oleadas

Las oleadas no se escriben a mano: las genera `scripts/tools/make_waves.gd` (`godot --headless --path . -s scripts/tools/make_waves.gd`) a partir de su tabla `LEVELS`, y para retocarlas se cambia la tabla y se vuelve a lanzar. Por nivel, la tabla dice: número de oleadas, caminos del mapa, cuántas naves seguidas van por cada camino, presupuesto de la primera oleada, cuánto crece por oleada, separación inicial entre naves, naves nuevas del nivel, naves de niveles anteriores y si sale la Nodriza.

- **Presupuesto**: cada nave cuesta su `reward` más la de sus trozos (la Divisora, 30 + 3 × 10). La oleada K gasta `presupuesto × crecimiento^(K-1)` y saca al menos una nave más que la anterior. El presupuesto inicial de cada nivel es mayor que el del anterior (175, 260, 380, 500, 620, 740, 860, 980 y 1100), así que la primera oleada de un nivel es más dura que la del anterior.
- **Grupos**: las naves salen en grupos del mismo tipo. Los grupos alternan entre las naves nuevas del nivel (los pares) y todas las del nivel, para que las nuevas sean las protagonistas desde la primera oleada. El tamaño del grupo es su valor (100 + 15 por oleada) entre el coste de la nave, de 1 a 6. "dart" es un Dart de color al azar.
- **Tiempos**: la primera nave sale a 3 s en la primera oleada y a 2 s en las demás. La separación entre naves empieza en la de la tabla (de 1 s en el nivel 1 a 0,6 s en el 9), se multiplica por 0,93 en cada oleada (mínimo 0,3 s) y por el coste de la nave entre 35 (de 0,6 a 2), así que las naves caras van más separadas. Entre grupos hay una pausa de 2,5 separaciones. Los tiempos se redondean a décimas.
- **Vida**: `health_multiplier` = 1 + 0,05 por oleada (1,0 la primera, 1,45 la décima).
- **Nodriza**: solo en la última oleada de los niveles 6 y 9, una, al final.
- **Caminos**: las entradas, ordenadas por tiempo, van por turnos a los caminos 0, 1, 2… (`path_index` = posición % caminos). El nivel 4 las reparte de dos en dos (`path_index` = (posición / 2) % 2).
- Las tiradas usan una semilla fija por nivel y oleada: volver a lanzarlo da las mismas naves y tiempos (los ids de los subrecursos sí cambian).
- Los `.tres` que ya existen se cargan y se rellenan, así conservan su uid. Como Godot guarda sin uid desde `-s`, el script los vuelve a escribir en la cabecera y en los `ext_resource` (como `map_generator.gd`). Para el nivel 5 añade a `GameData.tscn` las `ext_resource` que falten (`wave_5_K`) y reescribe su línea `waves`, sin tocar el resto de la escena.
- El dinero inicial (`LevelState.money`, 5000) no se toca: si un nivel no se puede ganar, se ajusta la tabla.

## Spawner

`_spawn_enemy` llama a `Enemy.setup(data, health_multiplier)` con el multiplicador de la oleada en curso (`waves[_wave_index]`).

Lleva el ciclo de oleadas del nivel: cuándo se lanzan, qué enemigos quedan vivos y el modo AUTO.

### Ciclo de oleadas

- `setup(paths, waves)` solo guarda los datos. El nivel empieza en espera, sin enemigos, para dejar construir; la primera oleada se lanza con el botón de la pestaña Oleadas o con AUTO.
- `start_next_wave() -> bool` lanza la siguiente oleada: copia sus entradas, las ordena por `time`, pone el reloj a 0 y emite `wave_started(index, total)` (índice desde 0). Devuelve `false` y no hace nada si el nivel no está limpio (la actual sigue sacando o quedan enemigos vivos) o no quedan oleadas (`can_start_next_wave()`). Así nunca conviven enemigos de dos oleadas.
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_spawn_finished(index)`.
- `_spawn(entry)` llama a `_spawn_enemy(data, path, progress)` con el `Path2D` número `entry.path_index % paths.size()` y `PORTAL_OFFSET`. `_spawn_enemy` instancia `scenes/entities/Enemy.tscn` como hijo de ese camino, lo pone en `progress` (antes de `setup`, para que su primer giro salga del camino), llama a `enemy.setup(data)`, lo apunta como vivo, conecta sus señales `died` y `reached_end` y lo devuelve. `_spawn` llama además a `enemy.spawn_in()` (escala 0→1 en 0,2 s con destello).

### Portales

Al lanzar una oleada, `_open_portals()` crea un `Portal` (`scripts/entities/Portal.gd`) como hijo de cada `Path2D` que use la oleada, a `PORTAL_OFFSET` (40 px) del principio de su curva, media casilla dentro del borde del mapa, porque los caminos empiezan 2 casillas fuera (uno por camino, guardados en `_portals`). Las naves también empiezan ahí (`progress = PORTAL_OFFSET`), así que salen del portal. El portal se gira para quedar atravesado al camino en ese punto (vertical si el camino entra en horizontal y al revés), en múltiplos de 90°. El portal es una grieta horizontal en forma de ojo (30x10 px abierta, acabada en punta a los dos lados), pintada con `draw_rect` columna a columna en píxeles enteros: interior casi negro (`#1a0614`) con píxeles magenta que entran hacia el centro, borde liso de 1 px que late entre `#be30a0` y `#ff5ad2`, halo de 1 px `#be30a0` por fuera y puntas rojas `#f0323c`. Al abrirse (0,3 s) primero es una línea que se alarga y luego se abre en alto; entonces tiembla 1 px durante 0,25 s con un destello. Mientras está abierto, 8 píxeles magenta giran en espiral hacia dentro dentro de la grieta. Cada nave que sale por él provoca un destello blanco en cruz de 0,15 s en el centro del portal (`flash_exit()`, que llama `Spawner._spawn`). Al cerrarse (0,3 s) se cierra en una línea y desaparece. Al crear el último enemigo, `_close_portals()` los cierra y los libera. Usan tweens, así que siguen `Engine.time_scale` y se paran con la pausa.

### Enemigos vivos

`_alive` es un `Dictionary[Enemy, bool]`. Se añade el enemigo al crearlo y se borra al recibir `died` o `reached_end`; solo la primera de esas señales cuenta, así que cada enemigo se descuenta una vez aunque muera dos veces o muera y llegue al final en el mismo frame. Solo entonces se reenvía como `enemy_died(reward)` o `enemy_reached_end(damage)`. No se usa `tree_exiting`: al reiniciar se libera el nivel entero y no se emite nada. `get_alive_count()` devuelve la cuenta.

Si el enemigo muerto se parte (`EnemyData.split_into`, ver [enemigos.md](enemigos.md)), `_on_enemy_died` suma 1 a `_pending_splits` y llama a `_crack(enemy)`: deja un sprite suelto (sin área, así que se puede crear dentro de una señal de física como el `area_entered` de la bala) con su frame agrietado y, al acabar su tween, `_split(...)` resta 1 y crea los trozos con `_spawn_enemy` (sin `spawn_in()`). Mientras `_pending_splits` > 0, `is_clear()` es false, así que la oleada no se da por limpia entre la muerte y la salida de los trozos.

### Estados

| Función | Significado |
|---|---|
| `get_wave_index()` | Última oleada lanzada; -1 antes de la primera |
| `is_spawning()` | La oleada actual aún tiene entradas pendientes |
| `has_finished_spawning()` | No quedan entradas (o no se ha lanzado ninguna); puede haber enemigos vivos |
| `is_clear()` | No quedan entradas, enemigos vivos ni piezas por soltar |
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

Todos los mapas de nivel miden 43x33 casillas (688x528 px), así que todos quedan igual: `Map` en (136, 6) y rectángulo útil de x = 136 a 824 y de y = 6 a 534. Sobran 8 px a cada lado y 6 px arriba y abajo, que cubre la decoración del margen (ver abajo).

Todos los mapas (y la plantilla `Map.tscn`) llevan `Background`, instancia de `SpaceBackground.tscn`, como primer hijo de `Map`.

### Mapas de los niveles

Los 9 mapas están en `scenes/maps/levels/` (`Level1.tscn` a `Level9.tscn`). Los caminos no se dibujan: cada camino es un **pasillo de espacio libre** de 3 casillas que atraviesa un campo de asteroides que llena todo lo demás. El campo tiene gravilla de roca por el suelo y el pasillo no, así que el pasillo se ve limpio y oscuro y cualquier claro del campo se ve sucio. Sus capas, de abajo arriba, todas con `resources/tilesets/tileset_espacio.tres` menos `LogicMap`:

| Capa | Contenido |
|---|---|
| `Gravel` | Gravilla y estrellas que parpadean en todo el campo; nada en el pasillo |
| `Lights` | Luces del centro del pasillo en los tramos rectos |
| `VisualMap` | Rocas, chatarra, piezas especiales y balizas |
| `TowerSlots` | Los asteroides con plataforma de las casillas de torre |
| `LogicMap` | `visible = false`; cubre las 43x33 casillas: camino (`path`), hueco de torre (`slot`) o decorado (`scenery`) |

| Nivel | Idea | Estación (casilla del centro) | Caminos | Rocas (`rocks`) |
|---|---|---|---|---|
| 1 | Un camino en zigzag por toda la pantalla | centro izquierda (5, 16) | 1 | grey, brown, ice |
| 2 | Un camino que se parte en dos rutas largas (norte en eses verticales, sur en eses horizontales) y se junta bajo la estación | arriba derecha (37, 4) | 2 | brown, grey, ore |
| 3 | Un camino que entra arriba a la derecha y se divide en dos ramas en espejo que no se vuelven a juntar | abajo izquierda (5, 28) | 2 | grey, ice, crystal |
| 4 | Dos caminos simétricos desde las esquinas de arriba que se juntan abajo en el centro y suben juntos por la columna central | arriba centro (21, 4) | 2 | dark, lava, grey |
| 5 | Dos caminos que entran por la izquierda y se cruzan dos veces sin juntarse | centro derecha (37, 16) | 2 | brown, ore, ice |
| 6 | Un anillo exterior (A) y dos caminos (B por la derecha, C por abajo) que lo cruzan y se juntan en el centro | arriba izquierda (5, 4) | 3 | grey, crystal, dark |
| 7 | Dos caminos, cada uno partido en una ruta recta y otra en eses | abajo derecha (37, 28) | 4 | dark, ice, brown |
| 8 | Dos entradas arriba que se parten en un atajo y una vuelta larga, con caminos simétricos | abajo centro (21, 28) | 4 | dark, lava, crystal |
| 9 | Una entrada en cada esquina partida en dos rutas, con caminos simétricos en los dos ejes | centro (21, 16) | 8 | dark, crystal, lava, ice |

En los niveles 4, 8 y 9 los caminos y las casillas de torre son simétricos; la decoración y la forma y la familia de cada asteroide de casilla de torre, no.

Los caminos empiezan 2 casillas fuera del mapa (los enemigos entran desde fuera de la pantalla, tapados por las barras o el borde) y acaban 40 px antes del centro de la estación, dentro de su borde. Los caminos que comparten tramo pasan por los mismos puntos.

Los mapas anteriores (los de hierba, los de espacio `Level2_espacio`, `Level5_espacio` y `Level6_espacio`, y los de `redesign/`) están en `scenes/maps/archive/` y no los usa ningún nivel.

### Generador de mapas

Los 9 mapas los genera `scripts/tools/map_generator.gd` a partir de `resources/map_data/level_N.txt` (el formato está en la cabecera del script):

```
godot --headless --path . -s scripts/tools/map_generator.gd -- [N ...]
```

Sin números genera los 9. **La fuente de verdad es el `.txt`**: el script reescribe el `.tscn` entero (conserva su uid), así que los retoques hechos en el editor se pierden al regenerar. Cada `.txt` da la semilla de la decoración, las familias de roca del nivel (`rocks`; la primera es la principal), la casilla de la estación, los caminos (puntos en casillas, con tramos horizontales o verticales) y las casillas de torre (`slots`).

Con eso, el script:

- Pone la estación en el centro de su casilla. Mide 96x96 px, así que sobresale media casilla por cada lado.
- Llena `LogicMap` y pone en cada casilla de torre un asteroide con plataforma (pieza de 2x2 de `espacio_casillas_torre.png`, ver [art.md](art.md)) de la familia de roca de su zona; las casillas a 8 o menos usan formas distintas (si quedan: hay 4 por familia).
- Calcula el **pasillo** (las casillas a 1 casilla o menos de un camino, en distancia de Chebyshev) y la **orilla** (las que están a 2, justo al lado del pasillo). Todo lo que no es pasillo es **campo**. Donde dos caminos se juntan o se cruzan, los pasillos se funden.
- La **densidad** del campo sale de un ruido (de 0,65 a 1), no baja de 0,9 en las 2 casillas del borde del mapa y se multiplica por 1,25 a 3 casillas del camino y por 1,5 a 4 o más: el campo se espesa al alejarse del pasillo, para que ninguna bolsa de campo rodeada de orilla parezca vacía.
- En `Lights`, una luz cada 2 casillas en los tramos rectos del centro del pasillo (dos piezas que alternan en los horizontales y otras dos en los verticales), sin luces en esquinas, cruces ni dentro de la estación.
- En `VisualMap` no pone nada en el pasillo ni en la estación ni en las casillas de torre (ni en sus 8 casillas de alrededor). En el campo, por este orden:
  1. **Balizas** a los dos lados de la boca de cada pasillo, en la casilla del borde.
  2. **Piezas especiales**: 3 o 4 entre la nave estrellada, el satélite con astronauta, la roca con ovni y el satélite animado, a 3 casillas o más del camino, fuera de las 2 casillas del borde, a 10 o más entre ellas y con una casilla libre alrededor.
  3. **Restos**: de 1 a 3 restos grandes (casco roto, contenedor, depósito, viga o antena), a 3 casillas o más del camino, fuera del borde y a 8 o más entre ellos, con chatarra pequeña alrededor, cada vez menos al alejarse.
  4. **Rocas de 3x3**: en el margen y la casilla del borde, de la familia principal (o su pareja), asomando desde fuera del mapa; en el resto, de la familia de la zona (o su pareja) y más cuanto más denso es el campo.
  5. **Rocas de 2x2** de la familia de la zona: en la orilla con probabilidad fija (para que el pasillo no quede bordeado solo de piedras pequeñas) y en el resto según la densidad.
  6. **Rocas pequeñas y piedrecitas**: la orilla casi llena y el resto según la densidad.
  7. **Huecos**: en cada cuadrado de 3x3 del campo con menos de 2 casillas tapadas por algo que se vea bien (todo menos las piedrecitas) pone rocas pequeñas hasta llegar a 2, para que ningún claro parezca un pasillo.
- La familia de cada roca sale de la zona en la que cae: el mapa se parte en 6 zonas alrededor de puntos al azar, y cada familia del nivel tiene al menos una. Las rocas sueltas son a veces de la familia pareja (`grey` y `brown` con `dark`; `dark`, `ore` e `ice` con `grey`; `crystal` y `lava` con `dark`).
- En `Gravel`, una pieza de gravilla (`espacio_gravilla.png`, ver [art.md](art.md)) en cada casilla del campo y del margen, con la paleta de la familia de su zona (`grey`, `ore` e `ice` gris; `brown` marrón; `dark`, `crystal` y `lava` oscura): en la orilla, una de las de poca gravilla; en el resto, una de las de mucha con probabilidad igual a la densidad. Alguna casilla (1,4 %) lleva en su lugar una estrella que parpadea. El pasillo queda limpio.

Las piezas se ponen tapando casillas enteras: las de lado impar se anclan en su casilla central y las de lado par (2x2, 2x1, 1x2, 3x2) usan la alternativa 1 del tileset, desplazada media casilla, anclada en su primera casilla. Así una roca de 2x2 puede quedar pegada al borde del pasillo sin taparlo. Las piezas de 1x1 del atlas de rocas usan al azar la alternativa 0 o una de la 1 a la 4, desplazadas 2 o 3 px, para que no queden en filas; no se usan las que las acercarían al pasillo. La decoración llega una casilla más allá del mapa (de -1 a 43 y de -1 a 33) para cubrir el margen, y las rocas grandes del borde pueden salirse más; solo `LogicMap` cuenta para el centrado.

Familias de roca (`rocks`), del atlas de rocas: `grey`, `brown` y `dark` (1x1, 2x2 y 3x3), `ore` (gris con vetas doradas), `ice` (hielo), `crystal` (cristal morado, con una de 2x2 animada) y `lava` (con una de 2x2 animada); estas cuatro sin 3x3.

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
- En `scenes/maps/archive/`, los mapas de hierba 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `archive/redesign/Level6.tscn` tenía el mismo uid que `archive/Level6.tscn` y Godot avisaba `UID duplicate`. Se le dio un uid nuevo.
- `resources/level_data/level_5.tres` existe y tiene el mismo contenido que el subrecurso de `GameData.tscn`, pero `GameData` no lo usa.
- Las oleadas de los niveles 7 a 9 son copias de las del nivel 6, solo con los `path_index` repartidos: falta equilibrarlas. Tampoco se ha revisado el equilibrio de los niveles 1 a 6 con los mapas nuevos, que tienen caminos mucho más largos.
- Al regenerar un mapa cambian los `id` de sus `ext_resource` y los `unique_id` de sus nodos, aunque el contenido sea el mismo.
- En los mapas con caminos que se cruzan (5 y 6) los pasillos se funden en los cruces: el espacio libre enseña por dónde pasan enemigos, no qué camino sigue cada uno.
