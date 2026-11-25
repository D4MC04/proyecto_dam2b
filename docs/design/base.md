# Base: estación espacial

## Escena y script

`scenes/entities/Base.tscn` + `scripts/entities/Base.gd` (clase `Base`).

- Raíz `SpaceStation`: `AnimatedSprite2D` con `resources/sprite_frames/estacion.tres` (tiras de `assets/sprites/base/estacion/`), sin escalar. Empieza en `fase_0` con autoplay.
- `Shield`: `Sprite2D` con `assets/sprites/base/shield.png`, escalado a 1,25. De momento está desactivado con `visible = false` en la escena; el código del parpadeo sigue ahí y vuelve a funcionar al poner `visible = true`. Activado, está oculto (`modulate.a = 0`) salvo mientras parpadea.

Animaciones de `estacion.tres`:

| Animación | Frames | Velocidad | Bucle |
|---|---|---|---|
| `fase_0` a `fase_3` | 96 | 10 fps | sí |
| `explosion` | 10 | 12 fps | no |
| `destruida` | 1 | — | no |

Está instanciada como nodo `SpaceStation` en `scenes/maps/Map.tscn` y en los 9 mapas de nivel (`scenes/maps/levels/`), con una posición distinta en cada uno; el generador de mapas la coloca centrada en una casilla (ver [niveles.md](niveles.md)).

## Qué hace el script

- `max_health` (exportado, 100) y `health`, que empieza al máximo.
- `take_damage(amount)`:
  - Resta vida sin bajar de 0 y emite `health_changed(health, max_health)`.
  - Si la vida llega a 0, oculta el escudo, gira el nodo al ángulo en que iba el anillo (`explosion` empieza en el giro 0 y sigue girando un paso por fotograma, y `destruida` queda en el giro del último, así que no salta), reproduce `explosion`, emite `destroyed` y al terminar la explosión pasa a `destruida`.
  - Si no, elige la fase por fracción de vida (> 0,75 → `fase_0`; > 0,5 → `fase_1`; > 0,25 → `fase_2`; resto → `fase_3`) y cambia de animación solo si la fase cambia, manteniendo el fotograma y su progreso para que el anillo no salte. Después el escudo parpadea 0,5 s con la textura `shield_debil.png` y vuelve a ocultarse, y el sprite destella en rojo 0,2 s (tween de `modulate` a blanco).
- Cada golpe también lanza una explosión (`rocket_launcher_impact.tres`) encima de la estación, con escala de 1,25 a 2 según el daño.
- Diseño: núcleo azul fijo en el centro y, girando a su alrededor, un buje con 4 radios, el anillo (con luces amarillas) y 4 placas solares azules (marco metálico y 6 celdas) colgadas de un mástil corto por fuera del anillo, entre radio y radio. Antes las placas iban sueltas en las esquinas sin girar; ahora están unidas al anillo y giran con él. Las placas son lo único que sale del círculo de 80 px (llegan a r = 46,5, dentro del frame de 96). Solo el núcleo queda quieto. La luz viene siempre de arriba a la izquierda, no gira.
- Daño por fase, acumulado y dibujado en el propio anillo, así que gira con él: `fase_1` zonas quemadas, una placa apagada y dos fuegos; `fase_2` además un trozo de anillo arrancado, un radio partido, una placa arrancada y el núcleo parpadeando; `fase_3` además otra brecha, otro radio partido, otra placa arrancada y el núcleo en rojo de alarma. Los fuegos sueltan humo que se queda atrás al girar. `explosion`: el núcleo se enciende, bola de fuego, los 4 trozos del anillo salen despedidos y queda humo; `destruida` son esos trozos quemados (dos con restos de placa), partidos por las brechas de la fase 3, y el núcleo reventado.
- El giro no rota el nodo: es la propia animación `fase_N` (96 fotogramas a 10 fps = una vuelta entera cada 9,6 s), así que sigue a `time_scale` y se detiene al pasar a `explosion`. La raíz `SpaceStation` tiene `process_mode = ALWAYS`: el giro sigue con la pausa, como el resto de animaciones constantes.
- Todas las tiras y `estacion.tres` salen de `scripts/tools/make_estacion.py` (`python scripts/tools/make_estacion.py`; con `--preview carpeta` solo genera un boceto y GIFs x4). Dibuja cada píxel en coordenadas polares del anillo, con el daño de cada fase en la tabla `DAMAGE`.
- Con la vida ya a 0, `take_damage` no hace nada.

## Comunicación con el resto

- Todos los mapas de nivel tienen la estación como nodo `SpaceStation`. `Level` la busca por ese nombre.
- Cada enemigo que llega al final del camino le quita su `EnemyData.base_damage` (5, 10, 20 o 40 según el tipo; ver [enemigos.md](enemigos.md)): `Level` conecta `spawner.enemy_reached_end(damage)` directamente a `take_damage`.
- `Level.shake_map(damage)` hace temblar el mapa (no la UI) 0,15 s: 2 px base, hasta 4 px con daño 40, redondeado a píxeles enteros y siguiendo `time_scale`. Tiembla al llegar una nave a la estación (daño de la nave), con el ataque orbital y al morir un jefe (`Spawner.boss_died`, como un golpe de `BOSS_SHAKE_DAMAGE` = 80, 6 px). Con la opción `screen_shake` de `Settings` apagada no hace nada.
- `destroyed` llama a `Level._lose`, que espera al final de la explosión antes de emitir `lost`.

## Dudas

- `assets/sprites/base/space_station.png` (48x48) solo lo usan mapas archivados que no están en ningún nivel (`scenes/maps/archive/Level6.tscn` a `Level10.tscn`).
