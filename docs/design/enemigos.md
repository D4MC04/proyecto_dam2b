# Enemigos

## Escena y script

`scenes/entities/Enemy.tscn` + `scripts/entities/Enemy.gd` (clase `Enemy`).

- Raíz `Enemy`: `PathFollow2D` con `rotates = false` y `loop = false`.
- `AnimatedSprite2D`: el sprite.
- `Area2D/CollisionShape2D`: la zona que detectan las torres y las balas.

El `Spawner` lo añade como hijo de un `Path2D` del mapa y llama a `setup(enemy_data)`, que copia velocidad y vida, asigna `sprite_frames` y `collision_shape`, y mete el nodo en el grupo `enemies`.

## Datos

`EnemyData` (`scripts/resources/EnemyData.gd`): `name`, `hp`, `speed` (px/s), `reward`, `base_damage` (vida que quita a la estación al llegar al final, 10 por defecto), `sprite_frames`, `collision_shape`, `rotate_sprite`, `rotation_offset` (grados), `death_sound` (`AudioStream`, ver Daño y muerte) `description` (frase corta para la ficha, ya rellena en todos), y `split_into` (ver Partirse al morir). Cumple el contrato `InspectableData` de la ficha (ver [ui.md](ui.md)): `get_stats()` da VIDA, VELOCIDAD (px/s), BOTÍN (la recompensa, con €) y DAÑO (`base_damage`); etiqueta "ENEMIGO" y acento `ACCENT_COLOR` (`#f0323c`).

Recursos en `resources/enemy_data/`:

| Archivo | Nombre | Vida | Velocidad | Recompensa | Daño a la estación | Radio de colisión | Primer nivel en que sale |
|---|---|---|---|---|---|---|---|
| `dart_hielo` | Dart de hielo | 25 | 90 | 25 | 5 | 8 | 1 |
| `dart_morado` | Dart morado | 25 | 90 | 25 | 5 | 8 | 1 |
| `dart_rojo` | Dart rojo | 25 | 90 | 25 | 5 | 8 | 1 |
| `dart_verde` | Dart verde | 25 | 90 | 25 | 5 | 8 | 1 |
| `wasp` | Wasp | 75 | 60 | 40 | 5 | 9 | 1 |
| `nave_normal` | Nave normal | 60 | 36 | 25 | 10 | 12 | 2 |
| `ufo` | UFO | 75 | 50 | 28 | 10 | 12 | 2 |
| `nave_agresiva` | Nave agresiva | 90 | 48 | 35 | 10 | 12 | 3 |
| `spiked_ship` | Spikey | 150 | 25 | 40 | 10 | 14 | 3 |
| `acorazado` | Acorazado | 360 | 25 | 110 | 20 | 14 | 4 |
| `ariete` | Ariete | 200 | 40 | 70 | 20 | 13 | 5 |
| `nodriza` | Nodriza | 400 | 40 | 150 | 40 | 14 | 6 |
| `divisora` | Divisora | 120 | 35 | 30 | 15 | 13 | 5 |
| `fragmento_divisora_izquierdo`, `_central`, `_derecho` | Fragmento de Divisora | 25 | 50 | 10 | 5 | 7 | 5 (al partirse la Divisora) |

Los cuatro Dart tienen los mismos valores; solo cambia el sprite.

## Comportamiento

### Movimiento

Cada frame: `progress += speed * _slow * delta`. Cuando `progress_ratio >= 1.0` emite `reached_end(data.base_damage)` y se libera.

### Animación

Según la dirección del último movimiento sobre su camino (posición local, así que el temblor del mapa no la cambia) reproduce `right`, `left`, `down` o `up`. Si `data.rotate_sprite` es `true`, además gira el sprite en pasos de 90° (el sprite base mira hacia arriba) y suma `rotation_offset`. `ufo` y `spiked_ship` no rotan: tienen un sprite distinto por dirección.

### Daño y muerte

- `take_damage(amount)` resta vida; con vida <= 0 llama a `die()`.
- `die()` emite `died(data.reward)`, reproduce `data.death_sound` en el bus `SFX` y libera el nodo. El `AudioStreamPlayer` se crea como hijo del padre (el `Path2D`) porque el enemigo se libera enseguida, y se libera solo al terminar (`finished`). Si llega a la estación (`reached_end`) no suena.
- Decidido: las naves no suenan al morir (el usuario lo pidió: sonaba demasiado fuerte y tapaba el resto). Las `resources/enemy_data/*.tres` no asignan `death_sound`, así que `_play_death_sound()` no hace nada. El campo `death_sound` de `EnemyData` y el código siguen por si se quiere volver a poner.
- Los `.wav` de `assets/audio/effects/SpaceShips/` se quedan en `assets/` sin usar (los 4 `dart_*` compartían `DartShip.wav`).

### Partirse al morir

`split_into` es la lista de trozos que suelta al morir (no al llegar a la estación), de izquierda a derecha según su dibujo. Lo hace el `Spawner` (ver [niveles.md](niveles.md)):

1. En el sitio de la nave queda un instante (`CRACK_TIME`, 0,15 s) su animación `crack` (el frame agrietado), con el mismo giro, pasando de destello blanco a su color.
2. Salen los trozos en su punto del camino, cada uno en su sitio del dibujo (separados `SPLIT_GAP`, 11 px, de lado según hacia dónde mira la nave) y con `flash()`. Se alejan `SPLIT_PUSH` (6 px) más en 0,12 s y vuelven al camino en 0,35 s. Lo que se mueve es el sprite, no el enemigo, para que el empujón no cambie hacia dónde mira.
3. Cuentan como vivos, así que la oleada no se limpia hasta matarlos también.

Solo la Divisora lo usa: se parte en sus tres módulos (`fragmento_divisora_izquierdo`, `_central` y `_derecho`, mismos valores; cambia el sprite). En el ARCHIVO sale solo el central, como "Fragmento de Divisora".

Sprites: `assets/sprites/enemies/divisora/` (`divisora_0..2.png` de 32x32, `divisora_crack.png` y `fragmento_<lado>_0..2.png` de 20x20), todos mirando hacia arriba con `rotate_sprite = true`. Los genera `scripts/tools/make_divisora_sprites.gd` (`godot --headless --path . -s scripts/tools/make_divisora_sprites.gd`). Ver [art.md](art.md).

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
- Al morir (no al llegar a la estación), `die()` lanza `FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.money(reward))` (`scripts/entities/FloatingText.gd`, estática, sin escena): un `Label` con la fuente Monogram a 16 px, sin suavizado, dorado `#ffe082` y `z_index` 10, centrado en la posición global del enemigo, que sube 12 px, se desvanece en 0,6 s y se libera. Cuelga del padre y su tween sigue el `time_scale` del juego. También lo usa la venta de torres.
- Barra de vida (`scripts/entities/HealthBar.gd`, hija del enemigo creada en `setup()`): `draw_rect` sin suavizado encima del sprite, del ancho del frame (`effect_scale() * 32`), 2 px de alto con contorno negro y fondo `#14060a`. Relleno verde, ámbar `#ecb23c` por debajo del 50 % y rojo `#f0323c` por debajo del 25 %. Oculta con la vida llena; `take_damage()` la actualiza. No gira (el `PathFollow2D` tiene `rotates = false`; solo gira el sprite).

## Comunicación con el resto

- Señales `died(reward)` y `reached_end(damage)`: las recoge `Spawner` y las reenvía a `Level` (dinero y derrota).
- Grupo `enemies`: lo consultan `Beam` y `Chain` para buscar objetivos.
- Las torres lo detectan por el `Area2D` y leen `get_remaining_distance()` (longitud del camino - `progress`), `hp` y `global_position`.
- `FocusBeam` modifica directamente `sprite.modulate` y llama a `_rest_color()`.
