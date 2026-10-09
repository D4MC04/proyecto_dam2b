# Enemigos

## Escena y script

`scenes/entities/Enemy.tscn` + `scripts/entities/Enemy.gd` (clase `Enemy`).

- Raíz `Enemy`: `PathFollow2D` con `rotates = false` y `loop = false`.
- `AnimatedSprite2D`: el sprite.
- `Area2D/CollisionShape2D`: la zona que detectan las torres y las balas.

El `Spawner` lo añade como hijo de un `Path2D` del mapa y llama a `setup(enemy_data)`, que copia velocidad y vida, asigna `sprite_frames` y `collision_shape`, y mete el nodo en el grupo `enemies`.

## Datos

`EnemyData` (`scripts/resources/EnemyData.gd`): `name`, `hp`, `speed` (px/s), `reward`, `sprite_frames`, `collision_shape`, `rotate_sprite`, `rotation_offset` (grados).

Recursos en `resources/enemy_data/`:

| Archivo | Nombre | Vida | Velocidad | Recompensa | Radio de colisión | Primer nivel en que sale |
|---|---|---|---|---|---|---|
| `dart_hielo` | Dart de hielo | 25 | 90 | 25 | 8 | 1 |
| `dart_morado` | Dart morado | 25 | 90 | 25 | 8 | 1 |
| `dart_rojo` | Dart rojo | 25 | 90 | 25 | 8 | 1 |
| `dart_verde` | Dart verde | 25 | 90 | 25 | 8 | 1 |
| `wasp` | Wasp | 75 | 60 | 40 | 9 | 1 |
| `nave_normal` | Nave normal | 60 | 36 | 25 | 12 | 2 |
| `ufo` | UFO | 75 | 50 | 28 | 12 | 2 |
| `nave_agresiva` | Nave agresiva | 90 | 48 | 35 | 12 | 3 |
| `spiked_ship` | Spikey | 150 | 25 | 40 | 14 | 3 |
| `acorazado` | Acorazado | 360 | 25 | 110 | 14 | 4 |
| `ariete` | Ariete | 200 | 40 | 70 | 13 | 5 |
| `nodriza` | Nodriza | 400 | 40 | 150 | 14 | 6 |

Los cuatro Dart tienen los mismos valores; solo cambia el sprite.

## Comportamiento

### Movimiento

Cada frame: `progress += speed * _slow * delta`. Cuando `progress_ratio >= 1.0` emite `reached_end` y se libera.

### Animación

Según la dirección del último movimiento reproduce `right`, `left`, `down` o `up`. Si `data.rotate_sprite` es `true`, además gira el sprite en pasos de 90° (el sprite base mira hacia arriba) y suma `rotation_offset`. `ufo` y `spiked_ship` no rotan: tienen un sprite distinto por dirección.

### Daño y muerte

- `take_damage(amount)` resta vida; con vida <= 0 llama a `die()`.
- `die()` emite `died(data.reward)` y libera el nodo.

### Ralentización

`slow(factor, duration, frost_frames)`:

- Pone el multiplicador `_slow` a `factor`.
- Si no tenía escarcha y se pasa `frost_frames`, añade un `AnimatedSprite2D` encima.
- Hace un destello blanco y deja el sprite teñido de azul claro (`SLOW_TINT`).
- Al pasar `duration` segundos vuelve a velocidad y color normales y quita la escarcha.
- Si ya estaba ralentizado se reinicia la duración; no se acumula.

### Efectos visuales

- `flash()`: destello de golpe de 0,15 s; vuelve al color normal o al tinte de ralentización.
- `effect_scale()`: tamaño mayor del frame dividido entre 32. Lo usan los ataques para escalar los efectos de 32 px al tamaño del enemigo.

## Comunicación con el resto

- Señales `died(reward)` y `reached_end`: las recoge `Spawner` y las reenvía a `Level` (dinero y derrota).
- Grupo `enemies`: lo consultan `Beam` y `Chain` para buscar objetivos.
- Las torres lo detectan por el `Area2D` y leen `progress`, `hp` y `global_position`.
- `FocusBeam` modifica directamente `sprite.modulate` y llama a `_rest_color()`.

## Dudas

- `EnemyData.hp` está declarado como `int`, pero varios `.tres` guardan el valor con decimales (`360.0`) y `Enemy.hp` es `float`.
- `EnemyData.name` no se muestra en ninguna parte.
- Al llegar al final el enemigo no hace daño a la base: la derrota es inmediata. Ver [base.md](base.md).
