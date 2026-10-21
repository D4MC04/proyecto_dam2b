# Enemigos

## Escena y script

`scenes/entities/Enemy.tscn` + `scripts/entities/Enemy.gd` (clase `Enemy`).

- Raíz `Enemy`: `PathFollow2D` con `rotates = false` y `loop = false`.
- `AnimatedSprite2D`: el sprite.
- `Area2D/CollisionShape2D`: la zona que detectan las torres y las balas.

El `Spawner` lo añade como hijo de un `Path2D` del mapa y llama a `setup(enemy_data)`, que copia velocidad y vida, asigna `sprite_frames` y `collision_shape`, y mete el nodo en el grupo `enemies`.

## Datos

`EnemyData` (`scripts/resources/EnemyData.gd`): `name`, `hp`, `speed` (px/s), `reward`, `base_damage` (vida que quita a la estación al llegar al final, 10 por defecto), `sprite_frames`, `collision_shape`, `rotate_sprite`, `rotation_offset` (grados), `cloak_interval` y `cloak_time` (camuflaje, ver Camuflaje; 0 = no se camufla), `death_sound` (`AudioStream`, ver Daño y muerte), `heal_aura` (solo la Reparadora, ver Curación), `emp_interval`, `emp_radius` y `emp_disable_time` (pulso EMP, ver Habilidades; `emp_interval` 0 = sin pulso), `split_into` (ver Partirse al morir) y `description` (frase corta para la ficha, ya rellena en todos). Cumple el contrato `InspectableData` de la ficha (ver [ui.md](ui.md)): `get_stats()` da VIDA, VELOCIDAD (px/s), BOTÍN (la recompensa, con €) y DAÑO (`base_damage`); etiqueta "ENEMIGO" y acento `ACCENT_COLOR` (`#f0323c`).

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
| `reparadora` | Reparadora | 90 | 38 | 50 | 5 | 12 | 6 |
| `espectro` | Espectro | 70 | 55 | 40 | 10 | 12 | 7 |
| `divisora` | Divisora | 120 | 35 | 30 | 15 | 13 | 5 |
| `fragmento_divisora_izquierdo`, `_central`, `_derecho` | Fragmento de Divisora | 25 | 50 | 10 | 5 | 7 | 5 (al partirse la Divisora) |
| `saboteadora` | Saboteadora | 110 | 30 | 55 | 10 | 13 | 8 |

Los cuatro Dart tienen los mismos valores; solo cambia el sprite.

## Comportamiento

### Movimiento

Cada frame: `progress += speed * _slow * delta`. Cuando `progress_ratio >= 1.0` emite `reached_end(data.base_damage)` y se libera.

### Animación

Según la dirección del último movimiento sobre su camino (posición local, así que el temblor del mapa no la cambia) reproduce `right`, `left`, `down` o `up`. Si `data.rotate_sprite` es `true`, además gira el sprite en pasos de 90° (el sprite base mira hacia arriba) y suma `rotation_offset`. `ufo` y `spiked_ship` no rotan: tienen un sprite distinto por dirección.

### Camuflaje

Si `data.cloak_interval > 0`, `setup()` arranca un tween en bucle: visible `cloak_interval` s y camuflado `cloak_time` s (el Espectro: 4 y 2). Al camuflarse pone `cloaked = true` y el sprite se disuelve en 0,3 s (`CLOAK_DISSOLVE_TIME`) con `resources/shaders/cloak_dissolve.gdshader`, un `ShaderMaterial` propio de cada Espectro: píxel a píxel de la punta a la cola, en franjas de interferencia (las filas pares van algo por detrás) y con un borde morado `#aa78ff` que avanza; los píxeles disueltos quedan al 20 % (`CLOAK_ALPHA`). La barra de vida baja al 20 % a la vez. Al reaparecer, la misma animación al revés. Todo va sobre la rejilla de píxeles de la textura, sin antialiasing, y no toca el `modulate` del sprite (destello y tinte de ralentización siguen igual).

Mientras está camuflado las torres no lo eligen: `Tower._best_enemy()` lo salta y `_get_target()` suelta al objetivo que se camufla. Los ataques de área sí le dan: la onda del Cryo (sale aunque en rango solo haya naves camufladas), el meteorito, el haz del Rail, la explosión del Cañón pesado y los saltos del rayo Tesla.

El sprite (`assets/sprites/enemies/espectro/espectro_0` a `_2`, 32x32, mirando hacia arriba, `rotate_sprite = true`) lo genera `scripts/tools/make_espectro.gd` (`godot --headless --path . -s scripts/tools/make_espectro.gd`): caza furtivo en forma de manta raya que ocupa los 32 px de ancho: alas anchas en flecha con costuras de panel, dos aletas delanteras, cabina pequeña, dos motores grises con llama y luces tenues (rojas en la punta de las alas, violeta en las alas); morado oscuro y casi negro, con la mitad derecha en sombra. Los frames cambian las llamas y la luz violeta. Usa la colisión de la Nave agresiva (radio 12). Sale en las tres oleadas del nivel 7.

### Daño y muerte

- `setup(data, health_multiplier = 1.0)` fija `max_hp = data.hp * multiplicador` y `hp = max_hp`; la barra de vida y la curación de la Reparadora usan `max_hp`. La ficha de la pestaña Oleadas sigue enseñando la vida base (`data.hp`); las naves en juego no son inspeccionables.
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

### Habilidades

- **Pulso EMP** (Saboteadora; `emp_interval` > 0): `setup()` llama a `EmpWave.attach(self)` (`scripts/entities/EmpWave.gd`, sin escena), que cuelga de la nave un `Timer` de `emp_interval` s (5). En cada vuelta empieza una carga de 1 s (`EmpCharge.start(enemy)`, `scripts/entities/EmpCharge.gd`, hijo del sprite para girar con él), toda en píxeles sin antialiasing:
  - En el núcleo crece una bola de energía de un punto de 2x2 a unos 13 px (se sale del núcleo), en capas que pasan de azul eléctrico a blanco por pasos (`#16307a`, `#2a6ae6`, `#78bcff`, `#e6f6ff`) con centro blanco. Las bobinas se iluminan con los mismos pasos.
  - Es inestable y va a más con la carga: late cada vez más rápido (de 12 a 60 rad/s), cambia de tamaño a tirones (medios píxeles y saltos de 1 px), vibra 1 px y chispea con píxeles blancos, morados `#aa78ff` y rojizos `#f0323c`.
  - Suelta hasta 4 rayos de 1 px en zigzag desde su borde hacia fuera, en `#78bcff` y `#e6f6ff`, cada vez más largos (de 3 a 12 px) y frecuentes.
  - En los últimos 0,3 s la nave tiembla 1 px (posición del sprite) y va al 25 % de su velocidad.
  - Al acabar, la nave recupera velocidad, da un destello (`flash()`) y `EmpWave.spawn(enemy)` crea en el padre de la nave (el camino, así que no la sigue) un destello blanco de 12 px durante 0,08 s y un anillo de 4 px de grueso (`RING_COLORS`, de fuera a dentro: `#e6f6ff`, dos de `#78bcff` y estela `#2a6ae6`) que sale de golpe hasta `emp_radius` (96 px, 6 casillas: el anillo llega justo hasta ese radio) en 0,3 s, rápido al principio y frenando al final, y se desvanece en 0,2 s. Cada torre del grupo `towers` por la que pasa el borde recibe `Tower.disable(emp_disable_time)` (3 s; ver [torres.md](torres.md)) una sola vez por pulso.
- Sprite: `assets/sprites/enemies/saboteadora/saboteadora_0` a `_2.png` (32x32, mirando hacia arriba, `rotate_sprite = true`), generados por `scripts/tools/make_saboteadora.gd` (`godot --headless --path . -s scripts/tools/make_saboteadora.gd`) a partir de una cuadrícula de texto con la mitad izquierda. Casco gris de enemigo, dos antenas delante, dos bobinas laterales con anillos azul eléctrico (`#16307a`, `#2a6ae6`, `#78bcff`, `#e6f6ff`), núcleo redondo en el centro y dos motores rojos. En los 3 frames laten el núcleo, las chispas de las antenas y las llamas.

### Efectos visuales

- `flash()`: destello de golpe de 0,15 s; vuelve al color normal o al tinte de ralentización.
- `effect_scale()`: tamaño mayor del frame dividido entre 32. Lo usan los ataques para escalar los efectos de 32 px al tamaño del enemigo.
- Al morir (no al llegar a la estación), `die()` lanza `FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.money(reward))` (`scripts/entities/FloatingText.gd`, estática, sin escena): un `Label` con la fuente Monogram a 16 px, sin suavizado, dorado `#ffe082` y `z_index` 10, centrado en la posición global del enemigo, que sube 12 px, se desvanece en 0,6 s y se libera. Cuelga del padre y su tween sigue el `time_scale` del juego. También lo usa la venta de torres.
- Barra de vida (`scripts/entities/HealthBar.gd`, hija del enemigo creada en `setup()`): `draw_rect` sin suavizado encima del sprite, del ancho del frame (`effect_scale() * 32`), 2 px de alto con contorno negro y fondo `#14060a`. Relleno verde, ámbar `#ecb23c` por debajo del 50 % y rojo `#f0323c` por debajo del 25 %. Oculta con la vida llena; `take_damage()` la actualiza. No gira (el `PathFollow2D` tiene `rotates = false`; solo gira el sprite).

### Curación (Reparadora)

- `heal(amount)`: suma vida sin pasar de `data.hp`; con la vida llena (o ya muerto) no hace nada. Si cura, actualiza la `HealthBar`, saca lo curado ("+9") con `FloatingText` en verde `#7ee89a`, hace un destello verde de 0,4 s sobre el sprite (como `flash()`, vuelve a `_rest_color()`) y añade las chispas de `HealEffect`.
- Con `data.heal_aura`, `setup()` crea un `Timer` de `HEAL_INTERVAL` (3 s). En cada disparo `_heal_nearby()` suelta el anillo de `HealEffect` y llama a `heal(data.hp * HEAL_RATIO)` (10 % de la vida máxima de la Reparadora, 9) en los demás enemigos del grupo `enemies` a `HEAL_RADIUS` (48 px) o menos. No se cura a sí misma.
- `HealEffect` (`scripts/entities/HealEffect.gd`, estático, sin escena) pinta en rectángulos de 1 px, sin antialiasing, con la rampa verde `#1c7440`, `#3cb860`, `#7ee89a`, `#c4f5d0`:
  - `spawn_ring()`: anillo de 1 px claro con otro oscuro por dentro que crece del 25 % al 100 % de 48 px en 0,5 s. Cuelga del camino, en la posición global de la Reparadora.
  - `spawn_sparks()`: 6 chispas (cabeza clara y estela de 1 px debajo) que suben unos 10 px en 0,4 s. Cuelga de la nave curada (`z_index` 5) para seguirla.
  - Las dos son opacas la primera mitad y se desvanecen en la segunda.
- En el nivel 6 salen cuatro, detrás de una nave del mismo camino (oleadas 2 y 3).

## Comunicación con el resto

- Señales `died(reward)` y `reached_end(damage)`: las recoge `Spawner` y las reenvía a `Level` (dinero y derrota).
- Grupo `enemies`: lo consultan `Beam` y `Chain` para buscar objetivos.
- Las torres lo detectan por el `Area2D` y leen `get_remaining_distance()` (longitud del camino - `progress`), `hp` y `global_position`.
- `FocusBeam` modifica directamente `sprite.modulate` y llama a `_rest_color()`.
