# Base: estación espacial

## Escena y script

`scenes/entities/Base.tscn` + `scripts/entities/Base.gd` (clase `Base`).

- Raíz `SpaceStation`: `AnimatedSprite2D` con `resources/sprite_frames/estacion.tres` (tiras de `assets/sprites/base/estacion/`), sin escalar. Empieza en `fase_0` con autoplay.
- `Shield`: `Sprite2D` con `assets/sprites/base/shield.png`, escalado a 1,25. De momento está desactivado con `visible = false` en la escena; el código del parpadeo sigue ahí y vuelve a funcionar al poner `visible = true`. Activado, está oculto (`modulate.a = 0`) salvo mientras parpadea.

Animaciones de `estacion.tres`:

| Animación | Frames | Velocidad | Bucle |
|---|---|---|---|
| `fase_0` a `fase_3` | 8 | 8 fps | sí |
| `explosion` | 10 | 12 fps | no |
| `destruida` | 1 | — | no |

Está instanciada como nodo `SpaceStation` en `scenes/maps/Map.tscn` y en los 9 mapas de nivel (`scenes/maps/levels/`), con una posición distinta en cada uno; el generador de mapas la coloca centrada en una casilla (ver [niveles.md](niveles.md)).

## Qué hace el script

- `max_health` (exportado, 100) y `health`, que empieza al máximo.
- `take_damage(amount)`:
  - Resta vida sin bajar de 0 y emite `health_changed(health, max_health)`.
  - Si la vida llega a 0, oculta el escudo, reproduce `explosion`, emite `destroyed` y al terminar la explosión pasa a `destruida`.
  - Si no, elige la fase por fracción de vida (> 0,75 → `fase_0`; > 0,5 → `fase_1`; > 0,25 → `fase_2`; resto → `fase_3`) y cambia de animación solo si la fase cambia. Después el escudo parpadea 0,5 s con la textura `shield_debil.png` y vuelve a ocultarse, y el sprite destella en rojo 0,2 s (tween de `modulate` a blanco).
- Cada golpe también lanza una explosión (`rocket_launcher_impact.tres`) encima de la estación, con escala de 1,25 a 2 según el daño.
- Con la vida ya a 0, `take_damage` no hace nada.

## Comunicación con el resto

- Todos los mapas de nivel tienen la estación como nodo `SpaceStation`. `Level` la busca por ese nombre.
- Cada enemigo que llega al final del camino le quita su `EnemyData.base_damage` (5, 10, 20 o 40 según el tipo; ver [enemigos.md](enemigos.md)): `Level` conecta `spawner.enemy_reached_end(damage)` directamente a `take_damage`.
- `Level.shake_map(damage)` hace temblar el mapa (no la UI) 0,15 s: 2 px base, hasta 4 px con daño 40, redondeado a píxeles enteros y siguiendo `time_scale`.
- `destroyed` llama a `Level._lose`, que espera al final de la explosión antes de emitir `lost`.

## Dudas

- `assets/sprites/base/space_station.png` (48x48) solo lo usan mapas archivados que no están en ningún nivel (`scenes/maps/archive/Level6.tscn` a `Level10.tscn`).
