# Niveles: nivel, mapa, cuadrícula y oleadas

## Escena Level

`scenes/Level.tscn` + `scripts/level/Level.gd` (clase `Level`). Nodos hijos:

| Nodo | Script | Función |
|---|---|---|
| `LevelState` | `scripts/level/LevelState.gd` | Dinero, torreta seleccionada, lo inspeccionado en la ficha y los contadores de la partida |
| `Grid` | `scripts/level/Grid.gd` | Qué casillas son camino o hueco y cuáles están ocupadas |
| `Spawner` | `scripts/level/Spawner.gd` | Lanza las oleadas, crea sus enemigos y cuenta los vivos |
| `BuildManager` | `scripts/level/BuildManager.gd` | Coloca torretas; ver [torretas.md](torretas.md) |
| `Powers` | `scripts/level/Powers.gd` | Poderes del jugador (meteorito, congelar y ataque orbital); ver "Poderes" |

`Level.setup(data: LevelData)`:

1. Instancia `data.map`, lo llama `Map` y lo pone como primer hijo.
2. `_center_map()`: centra el mapa en el área de juego, en horizontal y en vertical (ver "Centrado del mapa").
3. Guarda `data.turrets` en `turrets`.
4. `grid.setup(map.logic_map)`.
5. `spawner.setup(map.get_paths(), data.waves)`.
6. Guarda en `base` el nodo `SpaceStation` del mapa, conecta `spawner.enemy_reached_end` a `base.take_damage` (el daño lo trae la señal, de `EnemyData.base_damage`) y `base.destroyed` a `_lose`.

Conexiones hechas en `_ready`:

- `spawner.enemy_died(reward)` llama a `game_state.add_money`, que suma la recompensa.
- `spawner.all_waves_cleared` llama a `_win`, que llama a `build_manager.stop_building()` y emite `won`.
- `spawner.wave_cleared` llama a `_on_wave_cleared`: menos en la última oleada, si no llegó ningún enemigo a la estación (`_leaks_this_wave`, que `wave_started` pone a 0 y `enemy_reached_end` incrementa) suma `PERFECT_WAVE_BONUS` y enseña "PERFECTA +25€" como `FloatingText` sobre la estación durante 4 s.
- `build_manager.state = game_state`.

`_lose()` llama a `build_manager.stop_building()`, espera a `base.animation_finished` (el final de la explosión) y emite `lost`. Se espera porque la derrota acaba pausando el árbol y cortaría la animación.

Un nivel acaba una sola vez: `_lose` y `_win` comparten la marca `_finished` y, tras la primera de las dos, ninguna vuelve a emitir. `_lose` pone la marca antes de esperar a la explosión, así que durante la explosión el nivel ya no puede ganarse. Si el último enemigo de la última oleada destruye la estación, el `Spawner` emite antes `enemy_reached_end` que `all_waves_cleared`, así que gana la derrota y `won` no se emite.

Detrás del mapa, `Level.tscn` tiene dos nodos de decoración con los scripts del menú: `Comets` y `Satellites` (z_index -1, para que queden por debajo de `Map` y de las barras). Están en x = 128 con `area_size` 704x540, o sea solo cruzan el área de juego. Son menos frecuentes que en el menú: cometas cada 8 a 16 s (`wait_min`/`wait_max`) y satélites con 30 a 60 s entre uno y otro (`gap_min`/`gap_max`). Sobre los mapas de espacio el fondo `SpaceBackground` los tapa.

Tras perder o ganar, el nivel deja de construir por su cuenta, sin depender de la UI: `BuildManager` no coloca torretas ni enseña la vista previa (ver [torretas.md](torretas.md)). Durante la cámara lenta de la derrota y el respiro de la victoria el juego sigue corriendo. Durante la cámara lenta los enemigos siguen moviéndose y las torretas disparando; los que mueran aún cuentan y dan dinero, pero el resultado no cambia.

`get_run_stats() -> RunStats` construye el resumen de la derrota: oleada alcanzada (`spawner.get_wave_index() + 1`, 0 si no se lanzó ninguna), total de oleadas (`spawner.waves.size()`) y el nombre (clave) del enemigo que acabó con la estación. Ese enemigo es `Spawner.last_leaker` (el último que llegó al final del camino), que `_lose` copia en `_killer` en cuanto la estación se destruye, para que los que lleguen durante la explosión no lo cambien. Lo usa `Game` al perder; la victoria no tiene resumen.

**`RunStats`** (`scripts/level/RunStats.gd`, `RefCounted`): objeto de datos con `wave_reached` y `wave_total` (`int`) y `killer_name` (clave de traducción del último enemigo que llegó a la estación; vacío si no consta). Se crea con `RunStats.new(reached, total, killer)`. Lo pinta `RunSummary` (ver [ui.md](ui.md)).

## Poderes

`Powers` (`scripts/level/Powers.gd`, `Node2D` con `z_index = 1`, último hijo de `Level`): los poderes del jugador. Su `state` (`LevelState`) se asigna en `Level.tscn`. Como el nivel se crea de nuevo al empezar y al reiniciar, los poderes empiezan listos. Las recargas bajan en `_process`, así que siguen `Engine.time_scale` (×2 las acelera) y se paran con la pausa. Los botones están en la ficha (ver [ui.md](ui.md)). Emite `power_used(power)` al lanzar un poder (el meteorito, al caer; el ataque orbital, al empezar el rayo).

Los poderes se desbloquean con el progreso y no cuestan nada (solo tienen recarga). `GameState.POWER_UNLOCK_SECTORS` dice qué sector hay que ganar para cada uno: el meteorito al ganar el 2 (sale desde el nivel 3), el ataque orbital al ganar el 4 (desde el 5) y congelar al ganar el 6 (desde el 7). `GameState.unlocked_powers(level_number)` da los del nivel: como las torretas, son permanentes y cuentan el nivel que se juega y el progreso (`maxi(level_number, current_level)` mayor que el sector); el nivel de emergencia (número 0) no tiene ninguno. Solo se ven y se usan los desbloqueados (ver [ui.md](ui.md) › "Poderes"); el primero lo presenta NOVA (ver ui.md › "Mini tutorial de los poderes").

| Poder (`Powers.Power`) | Tecla | Efecto | Recarga |
|---|---|---|---|
| `METEOR` | Q | Modo apuntar; al hacer clic cae un meteorito: `METEOR_DAMAGE` (150) a todos los enemigos cuyo cuerpo toca el círculo de `METEOR_RADIUS` (40 px): centro a `METEOR_RADIUS` + media talla (`effect_scale() * Enemy.EFFECT_SIZE / 2`) o menos | 60 s |
| `FREEZE` | E | Todos los enemigos vivos a `FREEZE_FACTOR` (55 %) de velocidad durante `FREEZE_TIME` (3,5 s), lo mismo que el pulso del Cryo base, con `Enemy.slow` y la escarcha del Cryo (`cryo_frost.tres`); onda de hielo desde la base y escarcha con copos en las esquinas (ver abajo) | 90 s |
| `ORBITAL` | R | Modo apuntar (una franja horizontal ámbar, con línea solo arriba y abajo, sigue al cursor); al hacer clic, un rayo vertical recorre esa fila de izquierda a derecha de `GAME_AREA_RECT` en `ORBITAL_TIME` (2 s) y da un golpe de `ORBITAL_DAMAGE` (150, una sola vez por ataque y enemigo) a los enemigos vivos cuyo cuerpo toca el rayo: a `ORBITAL_HALF_WIDTH` (6 px) en x y `ORBITAL_HALF_HEIGHT` (16 px) en y de él, más media talla de la nave | 75 s |

- `use(power)`: si el poder no está listo no hace nada. Meteorito y ataque orbital: si ya se apuntaba ese poder, cancela; si no, suelta la torreta seleccionada (`state.selected_turret = null`) y entra en modo apuntar. Congelar se lanza ya.
- **Apuntado:** pinta en `_draw` un círculo del radio del área en el cursor (relleno ámbar al 15 % y borde de 1 px `#ecb23c`, sin antialiasing). En `_unhandled_input`, clic izquierdo lanza el meteorito ahí y clic derecho cancela; los dos marcan el evento como gestionado. Mientras se apunta, `BuildManager` ignora la entrada (su `powers`, asignado en la escena), así que no coloca ni selecciona torretas. Elegir torreta (`selected_turret_changed` con una torreta) cancela el apuntado. `cancel_aiming()` lo quita.
- **Ataque orbital:** la recarga empieza al hacer clic. Durante `ORBITAL_FALL_TIME` (0,15 s; hasta entonces no daña) primero sale arriba, sobre el rayo, una retícula que se cierra con un destello (`orbital_charge.tres`, la primera `ORBITAL_CHARGE_PART` = 60 %) y luego el rayo cae hasta la fila en el borde izquierdo de `GAME_AREA_RECT`; después barre la fila hasta el borde derecho en `ORBITAL_TIME` y al llegar sube y se va en `ORBITAL_EXIT_TIME` (0,08 s; ya no daña). En total dura `ORBITAL_END_TIME` (2,23 s). El rayo lo pinta `_draw_beam` en píxeles enteros y re-sorteado cada frame: halo semitransparente, borde `#1c7496`, cuerpo `#40e0f0`, franja `#befaff` y núcleo `#f0faff` que vibra 1 px, pulsos claros que bajan, `ORBITAL_BRANCHES` (3) ramas quebradas que saltan a los lados (más cerca del suelo), el emisor arriba (`orbital_emitter.tres`) y el impacto en el suelo (`orbital_impact.tres`); los frames los dibuja `_draw_frame`. Mientras daña, `_burn_row` deja cada `ORBITAL_SCORCH_STEP` (8 px) un tramo de estela quemada (`orbital_scorch_0..2.png`, hijo del mapa) que se apaga en `ORBITAL_SCORCH_TIME` (1,2 s), y dos chispas (`orbital_spark.tres`) cada `ORBITAL_SPARK_INTERVAL` (0,03 s). Al acabar, un destello (`orbital_flash.tres`, 64x64). Los sprites los genera `scripts/tools/make_orbital.gd`. Mientras dura, el mapa tiembla con `Level.shake_map(ORBITAL_SHAKE_DAMAGE)` cada `ORBITAL_SHAKE_INTERVAL` (0,15 s). Se mueve en `_process`, así que sigue la velocidad del juego y la pausa. `get_aimed_power()` da el poder apuntado (-1 si ninguno); `PowerButton` lo usa para el ámbar.
- **Meteorito:** la recarga empieza al hacer clic. Cae en `METEOR_FALL_TIME` (0,3 s) desde `METEOR_FALL_OFFSET` (-90, -150) respecto al punto una roca en llamas con estela (`meteor_fall.tres`, 48x24, en bucle, girada hacia donde cae). Mientras cae, una marca en el suelo (`meteor_warning.png`: anillo discontinuo del radio del área) se cierra de ×1,4 a ×1 y se aviva, y cada `METEOR_SPARK_INTERVAL` (0,04 s) queda una chispa en la trayectoria (`meteor_spark.tres`). Al llegar: explosión propia de 112x112 (`meteor_explosion.tres`, 12 frames a 24 fps: destello, bola de fuego, onda que llega a `METEOR_RADIUS` y cascotes), `RocketExplosion.wav` (bus SFX), `Level.shake_map(METEOR_SHAKE_DAMAGE)` (60; respeta la opción de temblor), el daño a los enemigos del área con `hp > 0` y una marca de quemado (`meteor_scorch.png`, hija del mapa) que se apaga en `METEOR_SCORCH_TIME` (3 s). Los sprites los genera `scripts/tools/make_meteor.gd`.
- **Congelar:** al lanzarlo, `_freeze_effects()` crea un nodo temporal con: un tinte azul hielo (`FREEZE_TINT`) que se desvanece; una onda de hielo que sale de la base (`Level.base`) y se expande en `FREEZE_WAVE_TIME` (1,2 s) hasta cubrir el área (se recorta a `GAME_AREA_RECT`; la pinta `_draw_freeze_wave` con arcos: frente de tres capas y dos ecos detrás); escarcha en las cuatro esquinas (`freeze_corner.png`: copos de 6 brazos y polvo, volteada por el signo de la escala) que crece en `FREEZE_GROW_TIME` (0,9 s), aguanta `FREEZE_TIME` y se derrite en `FREEZE_MELT_TIME` (0,8 s); y copos (`freeze_flake_*.png`, uno cada `FREEZE_FLAKE_INTERVAL`) que caen mientras dura. Las naves llevan solo `Enemy.slow` con la escarcha del Cryo. Los sprites y el icono `power_freeze.png` los genera `scripts/tools/make_freeze.gd`.

## LevelState

- `money` empieza en 0 y `Level.setup` lo fija con `LevelData.starting_money`.
- `add_money(amount)` suma y emite `money_changed(money)`.
- `spend_money(amount)` devuelve `false` si no alcanza; si alcanza resta, emite `money_changed` y devuelve `true`.
- `PERFECT_WAVE_BONUS` (25): premio por limpiar una oleada sin que llegue ningún enemigo a la estación. Lo aplica `Level._on_wave_cleared` (ver "Escena Level").
- `selected_turret: TurretData` es la torreta que se colocará al hacer clic y la única fuente de la selección. Su setter emite `selected_turret_changed(data)` solo si el valor cambia. Lo escribe `LevelUI` cuando la barra lateral lo pide y `BuildManager` (a `null`) al cancelar con clic derecho.
- `inspected: Resource` es lo que enseña la ficha (de momento un `TurretData`; es `Resource` para que valga también para enemigos) y la única fuente de lo inspeccionado. Su setter emite `inspected_changed(data)` solo si el valor cambia. Empieza en null y solo lo escribe `LevelUI`; deseleccionar no lo toca. Al reiniciar se crea un `LevelState` nuevo, así que vuelve a null.

## Datos de nivel

- `LevelData` (`scripts/resources/LevelData.gd`): `map: PackedScene`, `starting_money: int` (dinero inicial, 500 por defecto), `turrets: Array[TurretData]`, `waves: Array[WaveData]`; y para el radar de la selección de nivel (grupo "Radar", ver [menu.md](menu.md) › "Radar de sectores"): `sector_name` (clave `SECTOR_<n>_NAME`), `radar_distance` (fracción del radio), `radar_bearing` (grados, 0 arriba y en sentido horario; es el rumbo de la ficha), `distance_mkm` (la distancia de la ficha, en millones de km; el radar no la usa), `threat` (`Threat`: `LOW`, `MEDIUM`, `HIGH`, `EXTREME` solo para el jefe) y `radar_ship` (`RadarShip`: `RAIDER` incursor, `FANG` colmillo, `CRUSHER` triturador, `SPECTER` espectro; la nave de su enemigo más peligroso).
- `WaveData`: `groups: Array[SpawnGroup]` (en orden de salida) y `health_multiplier: float` (1.0 por defecto; multiplica la vida máxima de todos los enemigos de la oleada, también los trozos de la Divisora; la recompensa no cambia).
- `SpawnGroup`: naves iguales seguidas por un camino: `enemy_data: EnemyData`, `count: int` (1), `pause_after: float` (3,0 s desde su última nave hasta la primera del siguiente grupo; negativo si se solapan, p. ej. en varios caminos) y `path_index: int`. El primer grupo sale en el tiempo 0, que llega `WAVE_START_DELAY` después de lanzar la oleada. Como los tiempos son relativos, quitar naves o un grupo adelanta solo lo que va detrás.
- `SpawnSpacing` (`scripts/resources/SpawnSpacing.gd`, un único recurso: `resources/spawn_spacing.tres`): la separación entre dos naves seguidas de un grupo depende solo de la velocidad de la nave (con la misma velocidad, la misma separación). `spacing_by_speed: Dictionary[int, float]` da, por `EnemyData.speed` (px/s), los segundos entre naves; `get_spacing(speed)` la devuelve y, si esa velocidad no está, avisa con `push_warning` (una vez por velocidad) y usa `DEFAULT_SPACING` (0,5 s). Por ahora se ajusta a mano en ese `.tres` (o en el inspector de Godot); editarla desde el panel de balanceo (una columna «Separación» en la pestaña Enemigos que cambia a la vez todas las naves de esa velocidad) va en otro ticket. Valores de partida (la separación que más se repetía en los grupos de 2 o más naves de cada velocidad antes de la tabla; en empate, la menor): 30 → 0,68; 35 → 0,5; 45 → 0,21; 50 → 0,5 (los trozos de la Divisora, que no salen en grupos); 60 → 0,18; 90 → 0,3; 100 → 1,0; 125 → 0,6; 150 → 0,4; 250 → 1,0. Con ellos cambió la separación de unos 620 de los ~840 grupos de 2 o más naves (en el nivel 1, todos: Darts de 0,25 a 0,4 s, Wasps y Frigates de 0,3 a 0,6 s y Corsairs de 0,35 a 1 s, así que sus oleadas son más largas).
- `WaveData.get_entries()` calcula a partir de los grupos una `SpawnEntry` por nave (`enemy_data`, `time` en segundos desde el tiempo 0, `path_index`), ordenadas por tiempo; la separación de cada grupo es `WaveData.group_spacing(group)`, la de la tabla para la velocidad de su nave (`WaveData.SPAWN_SPACING`). No se guardan: las usan el Spawner y la pestaña Oleadas (`WaveBlock`).

Orden de desbloqueo (`GameData.turret_order`, un sector por delante: la torreta N + 1 sale en el nivel N y se anuncia al ganar el anterior; la 2.ª, al ganar el nivel de emergencia): Cañón doble, Cañón pesado, Minigun, Orbitador, Minero, Tesla, Cryo, Amplificador, Disintegrator y Rail (los costes no siguen este orden: ver [torretas.md](torretas.md) › balance). `LevelData.turrets` de cada nivel lleva las N + 1 primeras (el nivel de emergencia, el sector 0, solo el Cañón doble; el 9, las 10). Los desbloqueos son permanentes: `Level.setup` usa `GameState.available_turrets(data)`, las del nivel más las K + 1 primeras con `current_level` K (salvo en el nivel de emergencia), así que un sector anterior también ofrece las que ya se han desbloqueado. La barra de compra enseña siempre las 10; las que no están en `LevelData.turrets` salen bloqueadas.

Niveles registrados en `GameData.levels`:

| Nivel | Mapa | Dinero inicial | Torretas disponibles | Oleadas | Naves por oleada (1.ª → última) | Naves nuevas (protagonistas) | Caminos |
|---|---|---|---|---|---|---|---|
| 1 | `maps/levels/Level1.tscn` | 500 € | Cañón doble | 10 | 20 → 20 (a mano) | Darts y Wasp | 1 |
| 2 | `maps/levels/Level2.tscn` | 500 € | las anteriores + Minigun | 10 | 25 → 67 | Corsair y Streak | 2 |
| 3 | `maps/levels/Level3.tscn` | 700 € | las anteriores + Cryo | 10 | 25 → 45 (a mano) | Frigate | 2 |
| 4 | `maps/levels/Level4.tscn` | 900 € | las anteriores + Cañón pesado | 10 | 32 → 94 (a mano) | Juggernaut y Cruiser | 2 |
| 5 | `maps/levels/Level5.tscn` | 1100 € | las anteriores + Minero | 10 | 12 → 27 | Ram y Divisora | 2 |
| 6 | `maps/levels/Level6.tscn` | 1300 € | las anteriores + Tesla | 10 | 24 → 45 | Mender | 3 |
| 7 | `maps/levels/Level7.tscn` | 1500 € | las anteriores + Orbitador | 10 | 25 → 44 | Espectro | 4 |
| 8 | `maps/levels/Level8.tscn` | 1800 € | las anteriores + Amplificador | 10 | 19 → 42 (la Mothership en la 9 y la 10) | Payload y Vanguard | 4 |
| 9 | `maps/levels/Level9.tscn` | 2200 € | las anteriores + Disintegrator (9 de 10) | 10 | 28 → 62 (la Mothership de la 8 a la 10) | Espectro, Payload, Divisora y Mender (y todas las demás) | 8 |

Datos del radar:

| Nivel | Sector | Distancia | Rumbo | Amenaza | Nave |
|---|---|---|---|---|---|
| 1 | Órbita Baja | 0,20 (800 km) | 315° | Baja | Incursor |
| 2 | Campo Helado | 0,24 (960 km) | 150° | Baja | Incursor |
| 3 | Cinturón Kepler | 0,30 (1.200 km) | 240° | Baja | Colmillo |
| 4 | Grieta Roja | 0,36 (1.440 km) | 295° | Media | Triturador |
| 5 | Nebulosa Gris | 0,42 (1.680 km) | 105° | Media | Triturador |
| 6 | Paso del Eco | 0,48 (1.920 km) | 195° | Media | Triturador |
| 7 | Deriva Tóxica | 0,54 (2.160 km) | 35° | Alta | Espectro |
| 8 | Nido Exterior | 0,60 (2.400 km) | 270° | Alta | Colmillo |
| 9 | Frontera Muerta | 0,66 (2.640 km) | 62° | Alta | Espectro |

### Nivel de emergencia

El nivel de prueba del tutorial, fuera de los sectores: `resources/level_data/emergency.tres`, enlazado en `GameData.emergency_level` (no en `GameData.levels`, así que no sale en el radar, no tiene número y no desbloquea sector; la primera vez que se gana anuncia el Cañón pesado, ver [flujo.md](flujo.md) › "Victoria"). Mapa `scenes/maps/levels/Emergency.tscn`, 300 € y solo el Cañón doble, sin poderes. Lo lanza `MainMenu.open_emergency()` (ver [menu.md](menu.md)) y lleva el tutorial de NOVA (ver [ui.md](ui.md) › "Tutorial del nivel de emergencia").

- **Mapa:** un camino en eses con tres curvas cerradas y una casilla de torreta dentro de cada una (solo 3), para que cada torreta alcance las dos pasadas y la curva. Los tramos verticales van cada 6 casillas (x = 36, 30, 24 y 18): entre dos pasillos queda una franja de roca de 3 casillas y la torreta, en la del medio, queda a 3 casillas (48 px) de las dos pasadas y del fondo de la curva, dentro del alcance del Cañón doble (60 px). Más juntos (cada 4) quedaban filas de piedrecitas; más separados (cada 8) la torreta ya no alcanzaría las dos pasadas. Con 300 € y el Cañón doble a 100 se llenan las 3 y no sobra nada.
- **Oleadas (3):** la 1 da 200 € (lo justo para mejorar un Cañón doble a Cañón cuádruple; con la oleada perfecta, 225), la 2 da 400 € (las otras dos mejoras) y la 3 aprieta, pero se pasa con dos Cañones dobles y uno mejorado. Vida ×0,7, ×0,8 y ×0,8. Las oleadas son cortas (1,5 s entre grupos; antes de la tabla por velocidad las naves iban a 0,4-0,9 s). No salen del presupuesto: se escribieron grupo a grupo (1,5 s de pausa entre grupos) y se editan en sus `.tres` (`emergency_K.tres`) con el panel (ver "Generador de oleadas").
- **Al ganar** sale la pantalla de victoria como en un nivel normal, con sus estrellas, pero no guarda estrellas, no cuenta como victoria ni da logros (`complete_level`, `record_level_stars` y `register_win` no se aplican: no tiene número). Solo tiene "Menú", que vuelve a la oficina. Perder deja reintentar.
- **No se repite:** salir del nivel de emergencia de cualquier forma (ganarlo, "Saltar", salir desde la pausa o desde la derrota) llama a `GameState.complete_tutorial(won)` en `Game._quit_to_menu` (`won`: `_emergency_won`, que pone `_on_level_won`; así NOVA sabe si felicitar en la oficina) y vuelve a la oficina, no a la selección de nivel, donde sigue el tutorial de la oficina (ver [menu.md](menu.md) › "Tutorial de la oficina").
- El nivel 1 ya no lleva tutorial.

Las oleadas son `WaveData` en `resources/wave_data/level_N.tres` (la primera) y `level_N_K.tres` (la K). Todos los niveles (1 a 9) están en `resources/level_data/level_N.tres`, y `scenes/GameData.tscn` los enlaza.

### Generador de oleadas

Las oleadas son sus `.tres` de `resources/wave_data/`: son los datos de verdad y se editan con el panel de balanceo (`tools/balance/`, pestaña Niveles; ver [CLAUDE-CODE.md](../CLAUDE-CODE.md) › "Panel de balanceo"). El panel enseña por nivel y por oleada el dinero (también el de antes de cada oleada), las naves, la recompensa, la vida total y la duración de la salida (ya no enseña el ratio de "Dificultad frente a dinero": no servía y llevaba a error), y deja cambiar `starting_money`, `health_multiplier` y los grupos (nave, cuántas, pausa y camino; añadir, quitar, reordenar, copiar, pegar y duplicar). **Pendiente de otro ticket:** el panel aún enseña la columna de separación de los grupos (ya no existe en `SpawnGroup`: sale vacía y no se guarda) y su duración de la salida y "Sale a" no usan todavía la tabla por velocidad (ver "Datos de nivel"); ese ticket quita la columna y pone la separación en la pestaña Enemigos. Al guardar solo toca las líneas cambiadas: un grupo nuevo es un `sub_resource` con id nuevo, una nave que la oleada no usaba es un `ext_resource` nuevo (y se quita el de una nave que ya no usa ningún grupo); los ids y uid que ya existen no cambian.

- **Copiar, pegar y duplicar** (portapapeles propio del panel, uno para grupos y otro para una oleada; vale entre niveles):
  - **Grupos**: "⧉" en un grupo lo duplica justo debajo. Con las casillas se eligen uno o varios; "Copiar grupos" los guarda y "Pegar grupos" los mete, en el orden copiado, detrás del último elegido de la oleada abierta (o al final si no hay ninguno elegido), en cualquier oleada de cualquier nivel. Los pegados quedan elegidos.
  - **Oleadas**: "+ Nueva oleada" crea una sin grupos detrás de la elegida (o al final) y "✕ Quitar oleada" la quita del nivel (pregunta antes): se quita su `ext_resource` del `level_N.tres` y su `.tres` se borra al guardar, salvo que otro nivel la use. "⧉ Duplicar oleada" crea una oleada igual detrás de la elegida. "Copiar oleada" guarda sus grupos y su `health_multiplier`; "Pegar detrás" crea con ellos una oleada nueva detrás de la elegida (en el nivel abierto) y "Pegar encima" sustituye los grupos y el `health_multiplier` de la elegida, preguntando antes.
  - Una oleada nueva es un `.tres` nuevo en `resources/wave_data/` con el siguiente nombre libre del nivel (`level_N_K.tres` o `emergency_K.tres`, con K desde 2), sin `uid` (Godot le pone uno al guardarlo en el editor), y se añade a la lista `waves` del nivel con un `ext_resource` nuevo. Sale marcada en la tabla hasta guardar.
  - Todo queda pendiente hasta Guardar; Descartar lo deshace, también los archivos nuevos (no se llegan a escribir) y los borrados. Los niveles 1-4 y el de emergencia se hicieron a mano; los 5-9 son todavía los que dejó el generador (con las naves base nuevas, ver "Presupuesto") y se rehacen a mano, con el panel, cada uno en su ticket.

`scripts/tools/make_waves.gd` es solo una herramienta de pruebas: genera oleadas automáticas para un nivel y **sobrescribe** los `.tres` de sus oleadas (y la lista `waves` de `level_N.tres`), así que lo hecho a mano en ese nivel se pierde. Se lanza con `godot --headless --path . -s scripts/tools/make_waves.gd -- --level N` (N de 1 a 9): solo escribe ese nivel, y sin `--level` no hace nada. El generador es la tabla `LEVELS` y `_make_level()`. Por nivel, la tabla dice: número de oleadas (10 en todos), caminos del mapa, presupuesto de la primera oleada, cuánto crece por oleada, `gap` inicial (la base de la pausa entre grupos), multiplicador de vida de la primera y de la última oleada (`health`), naves nuevas del nivel, naves de niveles anteriores (ordenadas de más fáciles a más duras) y desde qué oleada sale la Mothership.

- **Un solo Dart**: en los niveles a mano el único Dart es `dart_rojo` (`DART` en el generador); donde antes había Darts de colores salen los mismos Darts, iguales.
- **Nivel 1 a mano**: las oleadas usan vida ×1; de la 6 a la 10, cada tramo de Darts es su propio grupo. Se hicieron con separaciones propias por grupo (0,25-0,35 s); desde la tabla por velocidad usan las de la tabla, más separadas (ver "Datos de nivel"), y se ajustan con ella.
- **Separaciones en los niveles 2-4**: se escribieron con separaciones propias por grupo (las que se citan abajo, como "muy separadas" o "0,3 s entre naves"); desde la tabla por velocidad cada nave sale con la de su velocidad, así que los respiros y los enjambres ya no cambian la separación entre naves, solo el número de naves, las pausas y los caminos.
- **Nivel 2 a mano**: por oleada, `health_multiplier` y grupos con nave, cuántas, camino y pausa después (pausa negativa = solapa con el siguiente grupo, para usar los dos caminos a la vez). La 1 va entera por el camino 0 (el de la izquierda, que sube por la columna 5) y presenta el Corsair entre Darts, muy separadas (1-1,8 s); la 2 se reparte entre los dos caminos. Dentro de cada oleada los grupos son cortos (2-6 naves) y alternan tipos, caminos y ritmos: Darts y Wasps rápidos entre Corsairs lentos, y grupos "escolta" (2-3 Darts, un Corsair y 2-3 Darts seguidos por el mismo camino). Nunca hay más de 6 naves iguales seguidas. Forma en dientes de sierra: 3, 6 y 9 son respiros (naves más separadas y caminos de uno en uno, sin bajar la vida); 4 y 7 suben; 5, 8 y 10 son picos (Corsairs por los dos caminos a la vez, más juntos); la 10 es la más dura. Vida: 0,6, 0,7, 0,8, 1,1, 1,3, 1,6, 1,8, 2,3, 2,4, 3,2 (siempre sube; los respiros se notan por la densidad). Desde la oleada 2, el primer grupo de Wasps de cada oleada es una pareja de Streaks. Recompensas por oleada: 290, 310, 290, 380, 430, 450, 550, 630, 640, 815 (subieron con el botín del Corsair, de 15 a 20, y la Streak). Si se cambian las naves o sus recompensas hay que retocar sus oleadas con el panel.
- **Nivel 3 a mano**: igual que el 2. Protagonista: la Frigate (125 PV, 30 €), con Darts, Wasps y Corsairs de apoyo. Camino 0 = rama de arriba y 1 = rama de abajo (entran juntas arriba a la derecha). La 1 va entera por el camino 0 y presenta Frigates sueltas (una cada vez, entre grupos de Darts, Wasps y Corsairs, con 2,5-3 s de pausa); la 2 se reparte entre los dos. Escoltas con una Frigate (o un Corsair) entre 2-3 Darts. Respiros 3, 6 y 9 (más separadas); picos 5, 8 y 10, con grupos de 3-4 Frigates por las dos ramas a la vez; la 10 es la más dura. Ninguna rama ve más de 6 naves iguales seguidas. Vida: 0,75, 0,85, 1,2, 1,35, 1,7, 2,1, 2,15, 2,4, 2,7, 3,2 (un 20 % menos que al hacerla, porque con el rediseño de las naves base la Frigate da menos dinero y tiene más vida). Recompensas: 305, 330, 335, 405, 430, 520, 575, 570, 700, 730.
- **Nivel 4 a mano**: igual. Protagonista: el Juggernaut (`acorazado`, 500 PV, 30 px/s, 70 €), con el Cruiser (200 PV, 40 €) como segunda nave nueva y Darts, Wasps, Streaks, Corsairs y Frigates de apoyo. Camino 0 = el que baja por la izquierda y 1 = el de la derecha (se juntan abajo en el centro y suben juntos por la columna central). La 1 va entera por el camino 0 y presenta Juggernauts sueltos (uno cada vez, entre grupos fáciles, con 3,5 s de pausa); la 2 se reparte entre los dos. Escoltas con una Frigate o un Juggernaut entre 2-3 Darts. Respiros 3, 6 y 9 (más separadas); picos 5, 8 y 10, con un Juggernaut por cada camino a la vez y enjambres apretados de Darts y Wasps (0,3 s entre naves) por los dos caminos, para que el Cañón pesado (área) tenga sentido. Desde la 5 hay pocos Juggernauts (2 por oleada) y muchas naves: la dificultad sale del número de naves más que de la vida, para que no sean esponjas. **Dinero:** el nivel 4 da el de antes del rediseño de las naves base (Renzo murió con el presupuesto bajado): recompensas 440, 500, 560, 625, 705, 790, 885, 975, 1130 y 1310 (440 × 1,125^(K-1), ±3 %), en vez del presupuesto de `LEVELS` (270). Se consigue con más naves (sobre todo Cruisers, Frigates y enjambres), sin tocar el botín de cada nave ni `starting_money` (900 €). Naves por oleada: 32, 30, 32, 33, 52, 53, 65, 89, 77 y 100. La 10 es la más larga (49 s de salida, frente a 21 s la 8 y 34 s la 9), con todo por los dos caminos a la vez y en cuatro fases: un Juggernaut por camino con escoltas de Frigate y Wasps; Cruisers con enjambres de Darts y Streaks; Frigates con más enjambres; y el golpe final, otra pareja de Juggernauts y un enjambre de Darts que sale 12 s después y los alcanza cerca del cruce. **Momento para Congelar** en la 8 y la 10: al final salen 4-5 Streaks por cada camino unos 39 s después del último Juggernaut (lo que tarda en sacarle ventaja una Streak, 105 px/s frente a 30, en los 1.664 px del camino), así que llegan a la estación a la vez que él. Ningún camino ve más de 6 naves iguales seguidas. Vida: 0,7, 0,8, 1,0, 1,25, 1,8, 2,5, 3,6, 5,0, 4,8, 7,0 (baja al principio porque las primeras oleadas traen el doble de naves con el mismo dinero inicial).
  - **Simulación** (script aparte, no está en el repo: mapa real, Minigun con sobrecalentamiento, Cryo que frena, Cañón pesado con área, sin poderes). Sin mejorar torretas (Miniguns de nivel 1 en todos los huecos y una Cryo de nivel 2) se pierde en la 8. Con Cañones pesados en los 5 huecos del cruce, Miniguns en el resto y mejorando con lo que sobra, se escapan naves en la 8, la 9 y la 10, y la estación acaba con 30 de vida. Con un 15 % más de vida, por si se juega peor que la simulación, sin poderes se pierde en la 10. Solo Miniguns pesadas no deja escapar nada: la simulación da a la Minigun un cambio de objetivo perfecto, así que es lo menos fiable. Se probó también a sacar la vida del dinero acumulado (vida total de la oleada ∝ dinero^α, con forma de dientes de sierra): con α = 1 el principio sale duro y el final fácil, porque la defensa rinde más por euro cuanto más se mejora; α ≈ 1,3 se parece a lo que hay, y sirvió de guía para subir la 7-10. El siguiente ajuste se hará con lo que pase en las partidas de Renzo, oleada a oleada. Versiones anteriores: con la 10 larga y vida 4,4 / 4,5 / 6,6 en la 8-10, al final ya no hacían falta poderes; con el dinero de antes y la 10 corta (94 naves, vida ×4,6), Renzo llegaba a la 10 con muchas mejoras y se le hacía fácil; con 4 Juggernauts por pico y vida hasta ×5,2 se perdía en la 8 también con Cañones pesados (demasiada vida por nave); con el presupuesto bajado (270) Renzo murió con Cañones y Miniguns mejorados.
- **Presupuesto**: cada nave cuesta su `reward` más la de sus trozos (la Divisora, 20 + 3 × 5). La oleada K gasta `presupuesto × crecimiento^(K-1)` y saca al menos una nave más que la anterior. El presupuesto inicial de cada nivel (150, 270, 230, 270, 300, 410, 370, 460 y 550: los de antes multiplicados por lo que bajó el botín de las naves de cada nivel al rediseñar las naves base, así que no crecen siempre) y crece un 12-13 % por oleada, así que la última oleada gasta unas 3 veces la primera. El presupuesto marca cuánto dinero dan las oleadas, no lo difíciles que son: la dificultad se sube con la vida y la densidad (ver "Dificultad frente a dinero").
- **Naves del nivel**: las nuevas del nivel salen desde la primera oleada y las de niveles anteriores se van sumando por orden de la lista (de las fáciles a las duras) hasta estar todas en la oleada 7. Un grupo nunca repite el tipo del anterior (si hay otro posible).
- **Grupos**: las naves salen en grupos del mismo tipo. Los grupos alternan entre las naves nuevas del nivel (los pares) y las disponibles del nivel, para que las nuevas sean las protagonistas. El tamaño del grupo es su valor (100 + 15 por oleada, como mucho `presupuesto / caminos` para que haya al menos un grupo por camino) entre el coste de la nave, de 1 a 6.
- **Tiempos**: la primera nave de cada oleada va en 0 s; la espera antes de que salga la pone el Spawner (`WAVE_START_DELAY`, 2,5 s). La separación entre naves de un grupo es la de la tabla por velocidad (`spawn_spacing.tres`, ver "Datos de nivel"): el generador no la calcula ni la guarda. El `gap` de la tabla `LEVELS` (de 1 s en el nivel 1 a 0,6 s en el 9) se multiplica por 0,91 en cada oleada (mínimo 0,3 s) y solo marca la pausa entre grupos: 2,5 × `gap`. En niveles con varios caminos el siguiente grupo sale cuando el anterior lleva el 100 % de su duración en la primera oleada y el 30 % en la última, así que los grupos de distintos caminos se solapan cada vez más. Cada grupo de la tabla se guarda como un `SpawnGroup`; las pausas se redondean a centésimas.
- **Vida**: `health_multiplier` sube del primer al segundo valor de `health` con una curva `(oleada / última)^1,4` (`HEALTH_CURVE`): sube poco al principio y mucho al final. La recompensa no cambia con él, así que la vida crece más rápido que el dinero. Valores (1.ª → 10.ª oleada): nivel 1 ×1,0 → ×2,8 (a mano); nivel 2 ×0,6 → ×3,2 (a mano, en dientes de sierra); nivel 3 ×0,75 → ×3,2 (a mano); nivel 4 ×0,7 → ×7,0 (a mano, con el dinero de antes del rediseño); nivel 5 ×0,4 → ×0,95; nivel 6 ×0,8 → ×1,7; nivel 7 ×0,9 → ×1,9; nivel 8 ×0,7 → ×1,6; nivel 9 ×1,25 → ×2,7 (los de 5-9 son provisionales: se bajaron al bajar el botín para que el ratio de "Dificultad frente a dinero" volviera a su sitio; las oleadas se rehacen a mano en sus tickets).
- **Mothership**: miniboss, sin aviso de jefe. Desde la oleada `mothership_from` de la tabla (la 9 en el nivel 8 y la 8 en el 9; 0 = nunca), una por oleada, como un grupo más hacia el 60 % de la oleada (`MOTHERSHIP_SPOT`). Su botín cuenta en el presupuesto.
- **Caminos**: cada grupo va entero por un camino, sacado de una bolsa mezclada con todos los caminos del mapa: se usan todos antes de repetir y nunca el mismo camino en dos grupos seguidos. Cada oleada usa todos los caminos del nivel.
- Las tiradas usan una semilla fija por nivel y oleada: volver a lanzarlo da las mismas naves y tiempos (los ids de los subrecursos sí cambian).
- Los `.tres` que ya existen se cargan y se rellenan, así conservan su uid. Como Godot guarda sin uid desde `-s`, el script los vuelve a escribir en la cabecera y en los `ext_resource` (como `map_generator.gd`).
- El dinero inicial (`LevelData.starting_money`), las recompensas de las naves y `PERFECT_WAVE_BONUS` no se tocan: si un nivel no se puede ganar, se ajustan sus oleadas (sobre todo `health_multiplier`).
- El presupuesto cuenta en recompensas (`reward`). Si cambian las recompensas de las naves (ver [enemigos.md](enemigos.md)), hay que retocar los presupuestos de la tabla.

#### Dificultad frente a dinero

Palancas usadas: la vida (`health`, curva convexa y más alta en cada nivel; es la principal porque no da dinero), la densidad (separación que se encoge más rápido y solape de caminos mayor en las últimas oleadas, para tener menos tiempo de disparo por nave) y, sin tocarlos, los presupuestos de la tabla (el dinero que dan las oleadas). No se han tocado recompensas, dinero inicial ni `PERFECT_WAVE_BONUS`, y tampoco se ha añadido velocidad por oleada (`WaveData` no la tiene).

Estimación (no una simulación) por nivel y oleada (se queda como explicación; el panel de balanceo ya no la calcula):

- Dinero antes de la oleada K = dinero inicial + recompensas de las K-1 anteriores + 25 por oleada perfecta.
- DPS que se monta = dinero × 0,17 (DPS efectivo por € de las torretas, ver [torretas.md](torretas.md)) × 0,75 (colocación y sobreataque).
- DPS que exige la oleada = vida total (con el multiplicador) / (duración de la salida + 2 × 85 px / velocidad media de la oleada).
- Ratio = exigido / montado: por encima de 1 se pierde vida. Se mide gastando todo el dinero en cada oleada ("construyendo") y con el DPS congelado tras la oleada 5 ("sin construir").

Antes del cambio el ratio construyendo era de 0,2 a 0,35 al final (hasta 0,9 en la primera oleada del nivel 1) y, sin construir desde la 5, se quedaba en 0,4-0,9: se ganaba parando de construir. Ahora (oleada 1 / 5 / 8 / 10):

| Nivel | Construyendo | Sin construir desde la 5 (oleada 8 / 10) |
|---|---|---|
| 1 (a mano) | 0,75 / 0,38 / 0,72 / 0,82 | 1,13 / 1,54 |
| 2 (a mano) | 0,33 / 0,64 / 0,70 / 0,75 (todas: 0,33 0,35 0,28 0,44 0,64 0,41 0,51 0,70 0,43 0,75) | 1,27 / 1,89 |
| 3 (a mano) | 0,28 / 0,66 / 0,77 / 0,86 (todas: 0,28 0,35 0,26 0,49 0,66 0,42 0,61 0,77 0,44 0,86) | 1,34 / 2,01 |
| 4 (a mano) | 0,28 / 0,79 / 0,79 / 0,65 (todas: 0,28 0,37 0,26 0,61 0,79 0,49 1,02 0,79 0,90 0,65; la 8 y la 10 bajan en este modelo porque las Streaks del final alargan la salida) | 1,41 / 1,60 |
| 5 | 0,33 / 0,37 / 0,51 / 0,73 | 0,87 / 1,66 |
| 6 | 0,41 / 0,44 / 0,53 / 0,76 | 0,99 / 1,83 |
| 7 | 0,43 / 0,56 / 0,68 / 0,81 | 1,10 / 1,75 |
| 8 | 0,40 / 0,47 / 0,71 / 0,80 | 1,20 / 1,79 |
| 9 | 0,48 / 0,63 / 0,84 / 0,85 | 1,42 / 1,91 |

Con el rediseño de las naves base (botín más bajo) los ratios de los niveles 3 a 9 subieron mucho al final; se bajó `health` en proporción para volver al objetivo (en los 5-9, la de la tabla `LEVELS`; en el 3, la de sus oleadas, un 20 %). Es provisional: las oleadas de los niveles 5-9 se rehacen a mano en sus tickets.


El nivel 4 queda por encima de 1 en los picos porque este modelo se queda corto en él: no cuenta lo que tardan en cruzar el alcance los Juggernauts (30 px/s) ni la Cryo, y Renzo pasó el nivel provisional (ratio 0,78) sin poderes. Para el 4 manda la simulación de su apartado.
Objetivo: construyendo bien el ratio final va de 0,6 (nivel 1) a 0,85 (nivel 9) y sin construir pasa de 1 hacia la oleada 7-8 en todos los niveles. La oleada 7 del nivel 7 sale ligera (0,51) porque la mezcla de naves de esa oleada es barata; el modelo no cubre cobertura de caminos (en el nivel 9 hay 8 caminos, así que es el que más puede resultar más duro que su ratio) ni el valor de la ralentización de la Cryo.

## Spawner

`_spawn_enemy` llama a `Enemy.setup(data, health_multiplier)` con el multiplicador de la oleada en curso (`waves[_wave_index]`).

Lleva el ciclo de oleadas del nivel: cuándo se lanzan, qué enemigos quedan vivos y el modo AUTO.

### Ciclo de oleadas

- `setup(paths, waves)` solo guarda los datos. El nivel empieza en espera, sin enemigos, para dejar construir; la primera oleada se lanza con el botón de la pestaña Oleadas o con AUTO.
- `start_next_wave() -> bool` lanza la siguiente oleada: toma sus entradas (`get_entries()`, ya ordenadas por `time`), pone el reloj a `-WAVE_START_DELAY` (2,5 s de espera hasta el tiempo 0) y emite `wave_started(index, total)` (índice desde 0). Devuelve `false` y no hace nada si el nivel no está limpio (la actual sigue sacando o quedan enemigos vivos) o no quedan oleadas (`can_start_next_wave()`). Así nunca conviven enemigos de dos oleadas.
- En `_process` suma el tiempo y crea cada enemigo cuando su `time` se cumple. Al crear el último emite `wave_spawn_finished(index)`.
- `_spawn(entry)` llama a `_spawn_enemy(data, path, progress)` con el `Path2D` número `entry.path_index % paths.size()` y `progress` 0: los caminos empiezan 2 casillas fuera del mapa, así que las naves entran volando desde fuera de la pantalla. `_spawn_enemy` instancia `scenes/entities/Enemy.tscn` como hijo de ese camino, lo pone en `progress` (antes de `setup`, para que su primer giro salga del camino), llama a `enemy.setup(data)`, lo apunta como vivo, conecta sus señales `died` y `reached_end` y lo devuelve.

### Enemigos vivos

`_alive` es un `Dictionary[Enemy, bool]`. Se añade el enemigo al crearlo y se borra al recibir `died` o `reached_end`; solo la primera de esas señales cuenta, así que cada enemigo se descuenta una vez aunque muera dos veces o muera y llegue al final en el mismo frame. Solo entonces se reenvía como `enemy_died(reward)` o `enemy_reached_end(damage)`. No se usa `tree_exiting`: al reiniciar se libera el nivel entero y no se emite nada. `get_alive_count()` devuelve la cuenta.

Si el enemigo muerto se parte (`EnemyData.split_into`, ver [enemigos.md](enemigos.md)), `_on_enemy_died` suma 1 a `_pending_splits` y llama a `_crack(enemy)`: deja un sprite suelto (sin área, así que se puede crear dentro de una señal de física como el `area_entered` de la bala) con su frame agrietado y, al acabar su tween, `_split(...)` resta 1 y crea los trozos con `_spawn_enemy` . Mientras `_pending_splits` > 0, `is_clear()` es false, así que la oleada no se da por limpia entre la muerte y la salida de los trozos.

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

`Grid`, `BuildManager` y los enemigos no necesitan saberlo: `Grid` convierte con `to_local`/`to_global` de `LogicMap`, las torretas y la vista previa se colocan con `grid.center` y los enemigos son hijos de los `Path2D` del mapa.

Todos los mapas de nivel miden 43x33 casillas (688x528 px), así que todos quedan igual: `Map` en (136, 6) y rectángulo útil de x = 136 a 824 y de y = 6 a 534. Sobran 8 px a cada lado y 6 px arriba y abajo, que cubre la decoración del margen (ver abajo).

Todos los mapas (y la plantilla `Map.tscn`) llevan `Background`, instancia de `SpaceBackground.tscn`, como primer hijo de `Map`.

### Mapas de los niveles

Los 9 mapas están en `scenes/maps/levels/` (`Level1.tscn` a `Level9.tscn`). Los caminos no se dibujan: cada camino es un **pasillo de espacio libre** de 3 casillas que atraviesa un campo de asteroides que llena todo lo demás. El campo tiene gravilla de roca por el suelo y el pasillo no, así que el pasillo se ve limpio y oscuro y cualquier claro del campo se ve sucio. Sus capas, de abajo arriba, todas con `resources/tilesets/tileset_espacio.tres` menos `LogicMap`:

| Capa | Contenido |
|---|---|
| `Gravel` | Gravilla y estrellas que parpadean en todo el campo; nada en el pasillo |
| `Lights` | Luces del centro del pasillo en los tramos rectos |
| `VisualMap` | Rocas, chatarra, piezas especiales y balizas |
| `TurretSlots` | Los asteroides con plataforma de las casillas de torreta |
| `LogicMap` | `visible = false`; cubre las 43x33 casillas: camino (`path`), hueco de torreta (`slot`) o decorado (`scenery`) |

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

En los niveles 4, 8 y 9 los caminos y las casillas de torreta son simétricos; la decoración y la forma y la familia de cada asteroide de casilla de torreta, no.

En el nivel 1, las casillas de dentro de sus tres curvas en U (16,7, 24,19 y 18,25) van en su franja a 2 casillas del centro del arco: a 3 casillas (48 px) de los dos tramos y a 5 (80 px) del fondo de la curva. El Cañón doble (60 px) da a los dos tramos pero no a la curva, y el Cañón pesado (88 px) la cubre entera: se puede poner el doble, pero rinde menos. A 1 casilla del centro el doble llegaba al fondo contando el tamaño de la nave y entre la casilla y la curva quedaba un claro con una piedrecita; en el centro, el doble lo cubría todo. A 2 casillas, la punta de la U la cierra la orilla de dentro de la curva (una roca de 2x2 y, si cabe, algo pequeño al lado, distinto en cada U; ver la orilla de las curvas), sin tocar el asteroide de la casilla, y la gravilla del medio de la franja llega hasta la punta. Hay además 6 **casillas de alcance largo**, a unas 4 casillas (64-68 px) del camino: por fuera de la punta de las U de la izquierda (7,7 y 9,25), por fuera de las dos esquinas de la derecha (39,9 y 39,29) y por dentro de ellas (32,15 y 32,23). Desde ahí el Cañón doble (60 px) casi no llega o solo roza la curva, y el Cañón pesado (88 px) cubre la curva (y en 39,9 también el pasillo de arriba): enseñan que hay sitios que solo aprovecha una torreta de mucho alcance. Entre las dos casillas de dentro de las esquinas de la derecha, junto al pasillo de la derecha, va fija la roca con ovni (`landmark = ufo 34,18`), para que esa franja no quede como un claro vacío.

Los caminos van en tramos rectos con las esquinas redondeadas: cada giro es un arco de 5 casillas de radio (menos si el tramo es corto), así que dos giros seguidos en un tramo corto forman una curva en U o en S, y las naves giran poco a poco. El pasillo sigue la misma curva: su orilla la dibujan rocas variadas (de 2x2, de 3x3 por fuera, pequeñas, alguna piedrecita y algo de chatarra) cuyo borde queda a la misma distancia del camino que la orilla de un tramo recto, así que la curva se ve con su forma, parece un campo de asteroides y no una fila de piedras, y las naves tienen el mismo margen que en las rectas. Las casillas de torreta siguen el criterio del nivel 2, que se colocó a partir de una captura de referencia: **pocas y repartidas**, más o menos una por cada 11 casillas de camino, separadas de 6 a 8 casillas entre ellas (nunca menos de 5,5) y con ningún tramo a más de unas 6 casillas de la más cercana, sin tramos vacíos ni montones y por toda la pantalla, también junto a los bordes y en las esquinas del mapa. Van **centradas en su franja de roca**: entre dos pasillos, en el medio (a unas 4 casillas de cada uno, y cubre los dos); en el campo, a 3 o 4 casillas del camino (al alcance de las torretas básicas). Las primeras que se ponen son las de las **curvas**: una dentro de cada curva en U, centrada entre sus dos rectas, y otras por fuera de las esquinas, donde cubren los dos tramos; pueden tocar la orilla de la curva, y entonces su asteroide hace de orilla. Las demás llenan los huecos que quedan. En los niveles 4, 8 y 9 son simétricas. El nivel de emergencia ya lo cumplía (una dentro de cada una de sus tres curvas). En el nivel 8 no hay casilla de torreta arriba en el centro, donde se juntan las dos curvas de arriba. En el nivel 7, la ruta en eses de abajo entra en la estación en una rampa en diagonal. Los caminos empiezan 2 casillas fuera del mapa (los enemigos entran desde fuera de la pantalla, tapados por las barras o el borde) y acaban 40 px antes del centro de la estación, dentro de su borde. Los caminos que comparten tramo pasan por los mismos puntos, también en las curvas.

Los mapas anteriores (los de hierba, los de espacio `Level2_espacio`, `Level5_espacio` y `Level6_espacio`, y los de `redesign/`) están en `scenes/maps/archive/` y no los usa ningún nivel.

### Generador de mapas

Los 9 mapas los genera `scripts/tools/map_generator.gd` a partir de `resources/map_data/level_N.txt` (el formato está en la cabecera del script):

```
godot --headless --path . -s scripts/tools/map_generator.gd -- [N | navedex ...]
```

Sin argumentos genera los 9, los mapas de la vitrina de la Navedex (`navedex*.txt` -> `scenes/maps/<Nombre>Map.tscn`, p. ej. `navedex_cryo.txt` -> `NavedexCryoMap.tscn`, ver [menu.md](menu.md)) y el del nivel de emergencia (`emergency.txt` -> `scenes/maps/levels/Emergency.tscn`); `-- emergency` genera solo este. Los de la Navedex llevan además `size` (tamaño en casillas, 43 33 por defecto) y, salvo el del Minero, no tienen `station`: sin estación el mapa no lleva `SpaceStation` ni script `Map`, no pone balizas y su camino acaba en su última casilla. Al regenerar, los `.tscn` de los niveles solo cambian en los `unique_id` de los nodos, que Godot reparte al guardar. **La fuente de verdad es el `.txt`**: el script reescribe el `.tscn` entero (conserva su uid), así que los retoques hechos en el editor se pierden al regenerar. Cada `.txt` da la semilla de la decoración, las familias de roca del nivel (`rocks`; la primera es la principal), la casilla de la estación, los caminos (puntos en casillas unidos por tramos rectos, con un radio de giro opcional por punto, `x,y:r`), el radio de giro del mapa (`radius`, 5 casillas si falta; la vitrina del Rail usa 3 para que las naves sigan en la recta del haz) las casillas de torreta (`slots`) y, si hace falta, piezas especiales fijas (`landmark = ufo 34,18`, una por línea: `ship`, `astronaut`, `ufo` o `satellite`, tapando esa casilla).

Con eso, el script:

- Hace la `Curve2D` de cada camino (`_make_curves()`): tramos rectos entre los centros de las casillas de sus puntos (el último, a 40 px del centro de la estación) y, en cada esquina, un arco de circunferencia tangente a los dos tramos, hecho con una Bézier cúbica (puntos de control `in`/`out`). El radio se acorta si no cabe: como mucho hasta la mitad de un tramo entre dos esquinas, el tramo entero en el último y, en el primero, el tramo menos 3 casillas (`ENTRY_STRAIGHT`), que quedan en recto para la boca del pasillo. Los puntos en mitad de un tramo recto se quitan. Un mismo giro (mismo punto y mismas direcciones de entrada y salida) sale igual en todos los caminos que lo tienen, con el menor de sus radios, para que los caminos que comparten tramo pasen por los mismos puntos. Las curvas llevan `bake_interval` de 2 px, para que el giro de las naves sea suave. Comprueba las casillas de torreta (`_check_slots()`) y da un error y no guarda ese mapa si alguna queda a menos de 2 casillas (`SLOT_CLEARANCE`) de la curva contando desde su centro, si no está centrada en su franja (a menos de 3 casillas, `SLOT_CENTER`, del camino teniendo al lado una casilla más lejos que no esté fuera del mapa ni toque una curva). Junto a una curva sí puede ir (cuenta como curva toda casilla a 2 o menos del camino cuyo punto más cercano está en un arco o un tramo en diagonal, `_near_bend`): su asteroide hace de orilla en lugar de las piezas de la orilla de la curva. Hay que moverla en el `.txt` (o bajar el radio de esa esquina). En las vitrinas de la Navedex, con la casilla puesta a mano para su escena, solo mira la distancia.
- Pone la estación en el centro de su casilla. Mide 96x96 px, así que sobresale media casilla por cada lado.
- Llena `LogicMap` y pone en cada casilla de torreta un asteroide con plataforma (pieza de 2x2 de `espacio_casillas_torreta.png`, ver [art.md](art.md)) de la familia de roca de su zona; las casillas a 8 o menos usan formas distintas (si quedan: hay 4 por familia).
- Calcula la distancia de cada casilla al camino, en pasos: es **pasillo** (1 o menos) toda casilla con algún punto a 1,45 casillas (`CORRIDOR_CLEARANCE`) o menos de la curva más cercana, **orilla** (2) si está a una casilla más, y así. Junto a un tramo recto sale lo mismo que contando casillas (el camino y una a cada lado); en una curva el pasillo se abre lo justo para que lo que hay a los lados quede igual de lejos que en una recta (rocas a 24 px o más del centro del camino). Las rocas de 1x1 tampoco se desplazan en diagonal hacia el pasillo. En `LogicMap` son camino (`path`) las casillas por las que pasa la curva. Todo lo que no es pasillo es **campo**. Donde dos caminos se juntan o se cruzan, los pasillos se funden.
- La **densidad** del campo sale de un ruido (de 0,65 a 1), no baja de 0,9 en las 2 casillas del borde del mapa y se multiplica por 1,25 a 3 casillas del camino y por 1,5 a 4 o más: el campo se espesa al alejarse del pasillo, para que ninguna bolsa de campo rodeada de orilla parezca vacía.
- En la orilla de cada curva (`_place_bend_edges()`), a los dos lados, piezas variadas que siguen la línea a 24,5 px del centro del camino (`BEND_EDGE_CLEARANCE`), medida al píxel con el dibujo de cada pieza (sacado de su textura): ningún píxel opaco queda más cerca del camino (el borde, a 24 px, como en la orilla de una recta) ni ninguna pieza con el centro a menos de 31 px (`BEND_EDGE_MIN`), y cada una se pone donde lo más cercano queda como mucho 5 px más allá (`BEND_EDGE_TOLERANCE`; las de 1x1 se miden por el centro), con el desplazamiento que mejor encaja (las de 1x1, los de `JITTER`; las de 2x2 y 3x3, sus alternativas desplazadas 4 px). Cada lado empieza por el medio y sigue hacia los dos extremos; cada pieza se elige al azar: por fuera, rocas de 3x3 (22 %), de 2x2 (42 %), pequeñas (26 %), piedrecitas y chatarra; por dentro, solo de 2x2 y pequeñas. Si no cabe, se prueba una más pequeña y al final una pequeña con más holgura (8 px), para que no queden huecos grandes. Las rocas son de la familia de la zona o de su pareja. Entre pieza y pieza queda un hueco al azar (casi siempre de 0 a 5 px, a veces de 8 a 12), y tras 2 piezas de 1x1 seguidas solo va una de 2x2 o un hueco, así que las pequeñas van en grupos y no en fila. En el lado de dentro de una curva cerrada (la punta de una U, que gira más de 2,5 rad) se empieza por la roca más grande que quepa, para que la punta acabe en una roca redondeada; no se empieza justo en el medio sino a hasta 1/5 de la orilla hacia un lado u otro al azar (`EDGE_TIGHT_SPREAD`), así que cada punta sale distinta y suele caber algo pequeño al otro lado. Una U cerrada es un solo tramo de curva: los pocos puntos de su punta que van por el eje (donde se juntan sus dos giros, de 6 puntos o menos) cuentan como curva; antes se partía en dos giros de 90° y nunca era cerrada. Las casillas de la línea que quedan en un hueco se reservan para que el campo no las llene de piedras. Nada va en las casillas de torreta ni a su alrededor, donde la orilla la hace su asteroide. Un tramo de curva que comparten varios caminos se hace una vez.
- Las **esquinas de los cruces** (bifurcaciones, uniones y cruces) también se redondean, aunque ninguna nave gire por ellas (`_make_fillets()`): donde dos tramos rectos salen de un mismo punto en direcciones perpendiculares y ningún camino gira entre ellos, se hace un **arco de relleno** tangente a los dos, del radio de giro del mapa (menos si un tramo es más corto). No es camino (no cambia `LogicMap`, ni los `Path2D`, ni las luces, ni la comprobación de las casillas de torreta): solo abre el pasillo hasta él y lleva la orilla del lado de dentro, con las mismas piezas y el mismo criterio que la orilla de las curvas, así que la esquina de roca se ve curva como el lado de dentro de una curva. Si una casilla de torreta cae en la esquina, su asteroide hace de orilla.
- En `Lights`, una luz cada 2 casillas en los tramos rectos del centro del pasillo (dos piezas que alternan en los horizontales y otras dos en los verticales), sin luces en las curvas, en los cruces, junto a ellos ni dentro de la estación.
- En `VisualMap` no pone nada en el pasillo ni en la estación ni en las casillas de torreta (ni en sus 8 casillas de alrededor). En el campo, por este orden:
  1. **Balizas** a los dos lados de la boca de cada pasillo, en la casilla del borde.
  2. **Piezas especiales**: 3 o 4 entre la nave estrellada, el satélite con astronauta, la roca con ovni y el satélite animado, a 3 casillas o más del camino, fuera de las 2 casillas del borde, a 10 o más entre ellas y con una casilla libre alrededor. Primero van las fijas del `.txt` (`landmark`), que cuentan en esos 3 o 4 y no se repiten.
  3. **Restos**: de 1 a 3 restos grandes (casco roto, contenedor, depósito, viga o antena), a 3 casillas o más del camino, fuera del borde y a 8 o más entre ellos, con chatarra pequeña alrededor, cada vez menos al alejarse.
  4. **Rocas de 3x3**: en el margen y la casilla del borde, de la familia principal (o su pareja), asomando desde fuera del mapa; en el resto, de la familia de la zona (o su pareja) y más cuanto más denso es el campo.
  5. **Rocas de 2x2** de la familia de la zona: en la orilla con probabilidad fija (para que el pasillo no quede bordeado solo de piedras pequeñas) y en el resto según la densidad.
  6. **Rocas pequeñas y piedrecitas**: la orilla casi llena y el resto según la densidad.
  7. **Huecos**: en cada cuadrado de 3x3 del campo con menos de 2 casillas tapadas por algo que se vea bien (todo menos las piedrecitas) pone rocas pequeñas hasta llegar a 2, para que ningún claro parezca un pasillo.
- La familia de cada roca sale de la zona en la que cae: el mapa se parte en 6 zonas alrededor de puntos al azar, y cada familia del nivel tiene al menos una. Las rocas sueltas son a veces de la familia pareja (`grey` y `brown` con `dark`; `dark`, `ore` e `ice` con `grey`; `crystal` y `lava` con `dark`).
- En `Gravel`, una pieza de gravilla (`espacio_gravilla.png`, ver [art.md](art.md)) en cada casilla del campo y del margen, con la paleta de la familia de su zona (`grey`, `ore` e `ice` gris; `brown` marrón; `dark`, `crystal` y `lava` oscura): en la orilla, una de las de poca gravilla (salvo la casilla del medio de la punta de una U, con el centro a 2,5 casillas o más del camino, que va como el medio de la franja); en el resto, una de las de mucha con probabilidad igual a la densidad. Alguna casilla (1,4 %) lleva en su lugar una estrella que parpadea. El pasillo queda limpio.

Las piezas se ponen tapando casillas enteras: las de lado impar se anclan en su casilla central y las de lado par (2x2, 2x1, 1x2, 3x2) usan la alternativa 1 del tileset, desplazada media casilla, anclada en su primera casilla. Así una roca de 2x2 puede quedar pegada al borde del pasillo sin taparlo. Las piezas de 1x1 del atlas de rocas usan al azar la alternativa 0 o una de la 1 a la 4, desplazadas 2 o 3 px, para que no queden en filas; no se usan las que las acercarían al pasillo. La decoración llega una casilla más allá del mapa (de -1 a 43 y de -1 a 33) para cubrir el margen, y las rocas grandes del borde pueden salirse más; solo `LogicMap` cuenta para el centrado.

Familias de roca (`rocks`), del atlas de rocas: `grey`, `brown` y `dark` (1x1, 2x2 y 3x3), `ore` (gris con vetas doradas), `ice` (hielo), `crystal` (cristal morado, con una de 2x2 animada) y `lava` (con una de 2x2 animada); estas cuatro sin 3x3.

### SpaceBackground

`scenes/maps/SpaceBackground.tscn` es el fondo común de todos los mapas y cubre los 704x540 px del área de juego. Tiene:

- `Nebula`: `Parallax2D` con desplazamiento automático de -3 px/s y la textura `fondo_nebulosa_tall.png` (640x544, repetida solo en horizontal).
- `GiantPlanet`: planeta de 224x224 abajo a la derecha, cortado por el borde inferior.
- `Stars`: `Parallax2D` a -6 px/s, repetida en los dos ejes (640x272), con un `AnimatedSprite2D` (`Twinkle`) de 8 frames.
- `Comet`: `scripts/level/Comet.gd`, sprite que espera entre 6 y 15 s, aparece a la izquierda a una altura al azar de la mitad de arriba (hasta 270 px), cruza los 704 px con velocidad (150, 22) px/s y vuelve a esperar. Su temporizador se detiene con la pausa.

Lo que sobresale del área queda tapado por las barras, que son opacas.

Bucle sin saltos: en `Nebula` y `Stars`, `repeat_size` es exactamente el tamaño de la textura (640x0 y 640x272) y `repeat_times = 3` en los dos, o sea 3 copias a cada lado del original (el margen sobra: el área mide 704x540 y la textura 640 de ancho). Medido en un escenario aislado (704x540, 240 s a velocidad x8, con `Map` desplazado) el fondo no deja huecos y el salto de `repeat_size` (las estrellas cada ~107 s, la nebulosa cada ~213 s) es invisible, porque cae justo en el borde de una copia. No se pudo reproducir el negro dentro de una partida; si vuelve a verse, sospechar de `repeat_times` insuficiente (con 2 el margen era justo para el desfase de `Twinkle`, -12 px) y de cómo se mueve `Map` (temblor al recibir daño) más que de las texturas.

`Background` no cuenta en `Map.get_used_rect()`, así que no afecta al centrado. Como vive dentro de `Map`, `Level._center_map()` llama a `Map.place_background(GAME_AREA_RECT)` después de mover el mapa: coloca `Background` en coordenadas globales en el origen del área de juego, (128, 0). Un mapa sin `Background` no hace nada.

## Grid

`Grid.setup(logic_map)` recorre las casillas usadas de `LogicMap` y lee el dato personalizado `kind` de cada tile:

- `"slot"`: se guarda en `slot_cells`.
- cualquier otro valor (`"path"` y `"scenery"`, que define el tileset): no se guarda.

Funciones:

- `can_build(c)`: la casilla es `slot` y no tiene torreta.
- `register_turret(c, t)`: apunta la torreta y la borra del registro cuando el nodo sale del árbol.
- `cell(p)` y `center(c)`: conversión entre posición global y casilla.

## Dudas

- `tileset.tres` declara una capa de datos `buildable` (bool) que ningún script lee.
- En `scenes/maps/archive/`, los mapas de hierba 7 a 10 usan un `Sprite2D` como estación en vez de `Base.tscn`, y `Level6.tscn` tiene las dos cosas.
- `archive/redesign/Level6.tscn` tenía el mismo uid que `archive/Level6.tscn` y Godot avisaba `UID duplicate`. Se le dio un uid nuevo.
- Las oleadas de los niveles 7 a 9 son copias de las del nivel 6, solo con los `path_index` repartidos: falta equilibrarlas. Tampoco se ha revisado el equilibrio de los niveles 1 a 6 con los mapas nuevos, que tienen caminos mucho más largos.
- Al regenerar un mapa cambian los `id` de sus `ext_resource` y los `unique_id` de sus nodos, aunque el contenido sea el mismo.
- En los mapas con caminos que se cruzan (5 y 6) los pasillos se funden en los cruces: el espacio libre enseña por dónde pasan enemigos, no qué camino sigue cada uno.
