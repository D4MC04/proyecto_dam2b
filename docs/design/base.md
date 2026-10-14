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

Está instanciada como nodo `SpaceStation` en `scenes/maps/Map.tscn` y en los mapas que usan los 6 niveles, con una posición distinta en cada mapa.

## Qué hace el script

- `max_health` (exportado, 100) y `health`, que empieza al máximo.
- `take_damage(amount)`:
  - Resta vida sin bajar de 0 y emite `health_changed(health, max_health)`.
  - Si la vida llega a 0, oculta el escudo, reproduce `explosion`, emite `destroyed` y al terminar la explosión pasa a `destruida`.
  - Si no, elige la fase por fracción de vida (> 0,75 → `fase_0`; > 0,5 → `fase_1`; > 0,25 → `fase_2`; resto → `fase_3`) y cambia de animación solo si la fase cambia. Después el escudo parpadea 0,5 s con la textura `shield_debil.png` y vuelve a ocultarse.
- Con la vida ya a 0, `take_damage` no hace nada.

## Comunicación con el resto

- Todos los mapas de nivel tienen la estación como nodo `SpaceStation`. `Level` la busca por ese nombre.
- Cada enemigo que llega al final del camino le quita 10 de vida (`Level.ENEMY_BASE_DAMAGE`): con 100 de vida, la estación aguanta 9 y el décimo la destruye.
- `destroyed` llama a `Level._lose`, que espera al final de la explosión antes de emitir `lost`.

## Dudas

- La vida de la base no se muestra en la interfaz: solo se ve por la fase de daño. Nadie escucha `health_changed`.
- Todos los enemigos quitan lo mismo; no hay daño por tipo de enemigo.
- Los caminos no terminan en la posición de la base. En `Level1.tscn` el camino acaba en (376, 216) y la base está en (440, 216); no he comprobado el resto de mapas.
- `assets/sprites/base/space_station.png` (48x48) solo lo usan mapas que no están en ningún nivel (`Level6.tscn` a `Level10.tscn`).
