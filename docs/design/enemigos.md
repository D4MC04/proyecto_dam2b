# Enemigos

## Escena y script

`scenes/entities/Enemy.tscn` + `scripts/entities/Enemy.gd` (clase `Enemy`).

- Raíz `Enemy`: `PathFollow2D` con `rotates = false` y `loop = false`.
- `AnimatedSprite2D`: el sprite.
- `Area2D/CollisionShape2D`: la zona que detectan las torretas y las balas.

El `Spawner` lo añade como hijo de un `Path2D` del mapa y llama a `setup(enemy_data)`, que copia velocidad y vida, asigna `sprite_frames` y `collision_shape`, y mete el nodo en el grupo `enemies`.

## Datos

`EnemyData` (`scripts/resources/EnemyData.gd`): `name`, `hp`, `speed` (px/s), `reward`, `base_damage` (vida que quita a la estación al llegar al final, 10 por defecto), `sprite_frames`, `collision_shape`, `rotate_sprite`, `rotation_offset` (grados), `is_boss` (jefe, ver abajo), `reveal_time` (camuflaje, ver Camuflaje; 0 = no se camufla), `death_sound` (`AudioStream`, ver Daño y muerte), `heal_rate` y `drain_frames` (la Mender, ver Curación), `emp_interval`, `emp_radius` y `emp_disable_time` (pulso EMP, ver Habilidades; `emp_interval` 0 = sin pulso), `split_into` (ver Partirse al morir) y `description` (frase corta para la ficha, ya rellena en todos). Cumple el contrato `InspectableData` de la ficha (ver [ui.md](ui.md)): `get_stats()` da VIDA, VELOCIDAD (px/s), BOTÍN (la recompensa, con €) y DAÑO (`base_damage`); etiqueta "ENEMIGO" y acento `ACCENT_COLOR` (`#f0323c`).

Recursos en `resources/enemy_data/` (los archivos conservan el nombre de antes; los nombres en inglés van en `translations/textos.csv`, igual en `es` y `en`). Velocidad como multiplicador de 60 px/s:

| Archivo | Nombre | Vida | Velocidad | Botín | Daño a la estación | Radio de colisión | Primer nivel en que sale | Papel |
|---|---|---|---|---|---|---|---|---|
| `dart_rojo` | Dart | 25 | 1,5 (90) | 5 | 5 | 8 | 1 | Enjambre: frágil, rápida, en grupos grandes |
| `wasp` | Wasp | 50 | 1,25 (75) | 10 | 10 | 9 | 1 | Rápida algo más dura |
| `streak` | Streak | 50 | 1,75 (105) | 15 | 10 | 8 | 2 | La más rápida; sola o en parejas |
| `vanguard` | Vanguard | 150 | 1,5 (90) | 35 | 15 | 12 | 8 | Rápida y dura: la amenaza rápida de los niveles altos |
| `nave_normal` | Corsair | 100 | 1,0 (60) | 20 | 15 | 12 | 2 | El estándar, la referencia |
| `nave_agresiva` | Frigate | 125 | 1,25 (75) | 30 | 15 | 12 | 3 | Un Corsair mejorado |
| `cruiser` | Cruiser | 200 | 1,0 (60) | 40 | 20 | 13 | 4 | Estándar pesado, entre la Frigate y la Ram |
| `ariete` | Ram | 250 | 0,75 (45) | 45 | 50 | 13 | 5 | Daño enorme a la estación |
| `acorazado` | Juggernaut | 500 | 0,5 (30) | 70 | 25 | 14 | 4 | El tanque |
| `nodriza` | Mothership | 750 | 0,75 (45) | 130 | 50 | 14 | 8 | Miniboss (ver abajo) |
| `reparadora` | Mender | 100 | 0,75 (45) | 25 | 5 | 12 | 6 | Se vacía para curar (ver Curación) |
| `espectro` | Specter | 75 | 60 | 20 | 10 | 12 | 7 | Con mecánica |
| `divisora` | Divisora | 120 | 35 | 20 | 15 | 13 | 5 | Con mecánica |
| `fragmento_divisora_izquierdo`, `_central`, `_derecho` | Fragmento de Divisora | 25 | 50 | 5 | 5 | 7 | 5 (al partirse la Divisora) | Trozos |
| `saboteadora` | Saboteadora | 110 | 30 | 25 | 10 | 13 | 8 | Con mecánica |

Las naves con mecánica (velocidad en px/s) solo tienen ya el botín nuevo; su vida, velocidad y nombre en inglés los cambian sus tickets (ver [naves-plan.md](naves-plan.md)).

- **Naves base**: 10 naves sin mecánica que se distinguen por sus números, por nichos con escalones (rápidas: Dart, Wasp, Streak y Vanguard; estándar: Corsair, Frigate y Cruiser; pesadas: Ram, Juggernaut y Mothership). Vida en saltos de 25 y velocidad en saltos de 0,25. Solo hay un Dart (antes había cuatro de colores).
- **Mothership**: miniboss, sin aviso de jefe (`is_boss` apagado). Como mucho una por oleada, entre las demás naves, en las oleadas 9 y 10 del nivel 8 y de la 8 a la 10 del nivel 9 (ver [niveles.md](niveles.md)).
- **Botín**: `reward` ≈ vida / 5 × √(velocidad / 60) × un factor por habilidad (1,2-1,5), redondeado a 5 (el 40 % de lo que daban antes, más o menos). La Divisora y sus tres trozos suman 35 €.
- **Jefes**: `is_boss` marca a un jefe: su oleada empieza con el `BossAlert` (con su nombre), su portal tiembla más y al morir el `Spawner` emite `boss_died` (sacude el mapa). Ahora mismo no lo tiene ninguna nave.

### Sprites de las naves base

Las 10 naves base no se dibujan a mano: las genera `scripts/tools/make_base_ships.gd` (`godot --headless --path . -s scripts/tools/make_base_ships.gd`), que también escribe sus `SpriteFrames`. Las naves con mecánica tienen su propio dibujo. Ver [art.md](art.md).

## Comportamiento

### Movimiento

Cada frame: `progress += speed * _slow * delta`. Cuando `progress_ratio >= 1.0` emite `reached_end(data.base_damage)` y se libera.

### Animación

Según la dirección del último movimiento sobre su camino (posición local, así que el temblor del mapa no la cambia) reproduce `right`, `left`, `down` o `up`. Si `data.rotate_sprite` es `true`, además gira el sprite hacia esa dirección (el sprite base mira hacia arriba), así que en las curvas del camino gira poco a poco, y suma `rotation_offset`.

### Camuflaje

Si `data.reveal_time > 0` (la Specter: 3), `setup()` la deja camuflada desde que sale: `cloaked = true`, el sprite disuelto con `resources/shaders/cloak_dissolve.gdshader` (un `ShaderMaterial` propio de cada Specter) y la barra de vida al 20 %. Cualquier daño mientras sigue viva (`take_damage()`, también el de los ataques de área que le dan camuflada) la destapa: `cloaked = false` al momento y la animación de reaparecer; a los `reveal_time` s sin más daño se vuelve a camuflar. Cada golpe reinicia la cuenta (mata el tween y empieza otro desde donde iba la disolución). La animación dura 0,3 s (`CLOAK_DISSOLVE_TIME`): píxel a píxel de la punta a la cola, en franjas de interferencia (las filas pares van algo por detrás) y con un borde morado `#aa78ff` que avanza; los píxeles disueltos quedan al 20 % (`CLOAK_ALPHA`). La barra de vida baja y sube a la vez. En grupo, el área que les da a las demás la destapa; sola, hay que darle con algo de área. Todo va sobre la rejilla de píxeles de la textura, sin antialiasing, y no toca el `modulate` del sprite (destello y tinte de ralentización siguen igual).

Mientras está camuflado las torretas no lo eligen: `Turret._best_enemy()` lo salta y `_get_target()` suelta al objetivo que se camufla. Los ataques de área sí le dan: la onda del Cryo (solo sale si hay alguna nave visible a tiro, pero da también a las camufladas), el meteorito, el haz del Rail, la explosión del Cañón pesado y los saltos del rayo Tesla.

El sprite (`assets/sprites/enemies/espectro/espectro_0` a `_2`, 32x32, mirando hacia arriba, `rotate_sprite = true`) lo genera `scripts/tools/make_espectro.gd` (`godot --headless --path . -s scripts/tools/make_espectro.gd`) con la plantilla y la paleta de las naves base: ala volante furtiva que ocupa casi los 32 px de ancho, en flecha, con borde de salida en dientes de sierra, una arista clara en cada ala, joroba central con costura granate, visor rojo estrecho y toberas ocultas con una llama pequeña. Su acento es el violeta de la disolución del camuflaje: borde de ataque violeta (`#7a5ae6`, en sombra `#3c2a8a`) y un emisor claro (`#c0aaff`, `#f4f0ff`) en cada punta. Los frames mueven un brillo `#c0aaff` por el borde de ataque, de la proa a la punta, y cambian la llama. Usa la colisión de la Frigate (`nave_agresiva`, radio 12). Sale en las tres oleadas del nivel 7.

### Daño y muerte

- `setup(data, health_multiplier = 1.0)` fija `max_hp = data.hp * multiplicador` y `hp = max_hp`; la barra de vida y la curación de la Mender usan `max_hp`. La ficha de la pestaña Oleadas sigue enseñando la vida base (`data.hp`); las naves en juego no son inspeccionables.
- `take_damage(amount)` resta vida; con vida <= 0 llama a `die()`.
- Con la opción `show_damage_numbers` de `Settings` (apagada por defecto), `take_damage()` suma el daño realmente hecho y, pasados `DAMAGE_TEXT_WINDOW` (0,25 s) desde el primer golpe, o al morir, lo enseña con `FloatingText` (blanco, `UiFormat.number`) sobre la nave; los golpes seguidos salen agrupados en un solo número.
- `die()` emite `died(data.reward)`, reproduce `data.death_sound` en el bus `SFX` y libera el nodo. El `AudioStreamPlayer` se crea como hijo del padre (el `Path2D`) porque el enemigo se libera enseguida, y se libera solo al terminar (`finished`). Si llega a la estación (`reached_end`) no suena.
- Decidido: las naves no suenan al morir (el usuario lo pidió: sonaba demasiado fuerte y tapaba el resto). Las `resources/enemy_data/*.tres` no asignan `death_sound`, así que `_play_death_sound()` no hace nada. El campo `death_sound` de `EnemyData` y el código siguen por si se quiere volver a poner.
- Los audios de `assets/audio/effects/SpaceShips/` (`.ogg` los largos, `.wav` los cortos) se quedan en `assets/` sin usar (los antiguos 4 Dart compartían `DartShip.wav`).

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
  - Al acabar, la nave recupera velocidad, da un destello (`flash()`) y `EmpWave.spawn(enemy)` crea en el padre de la nave (el camino, así que no la sigue) un destello blanco de 12 px durante 0,08 s y un anillo de 4 px de grueso (`RING_COLORS`, de fuera a dentro: `#e6f6ff`, dos de `#78bcff` y estela `#2a6ae6`) que sale de golpe hasta `emp_radius` (96 px, 6 casillas: el anillo llega justo hasta ese radio) en 0,3 s, rápido al principio y frenando al final, y se desvanece en 0,2 s. Cada torreta del grupo `turrets` por la que pasa el borde recibe `Turret.disable(emp_disable_time)` (3 s; ver [torretas.md](torretas.md)) una sola vez por pulso.
- Sprite: `assets/sprites/enemies/saboteadora/saboteadora_0` a `_2.png` (32x32, mirando hacia arriba, `rotate_sprite = true`), generados por `scripts/tools/make_saboteadora.gd` (`godot --headless --path . -s scripts/tools/make_saboteadora.gd`) a partir de una cuadrícula de texto con la mitad izquierda. Casco gris de enemigo, dos antenas delante, dos bobinas laterales con anillos azul eléctrico (`#16307a`, `#2a6ae6`, `#78bcff`, `#e6f6ff`), núcleo redondo en el centro y dos motores rojos. En los 3 frames laten el núcleo, las chispas de las antenas y las llamas.

### Efectos visuales

- `flash()`: destello de golpe de 0,15 s; vuelve al color normal o al tinte de ralentización.
- `effect_scale()`: tamaño mayor del frame dividido entre 32. Lo usan los ataques para escalar los efectos de 32 px al tamaño del enemigo.
- Al morir (no al llegar a la estación), `die()` lanza `FloatingText.spawn(get_parent(), global_position, "+" + UiFormat.money(reward))` (`scripts/entities/FloatingText.gd`, estática, sin escena): un `Label` con la fuente Monogram a 16 px, sin suavizado, dorado `#ffe082` y `z_index` 10, centrado en la posición global del enemigo (el tamaño del texto se mide con `Font.get_string_size`, no con el `Label`), que sube 12 px, se desvanece en 0,6 s y se libera. Cuelga del padre y su tween sigue el `time_scale` del juego. También lo usa la venta de torretas.
- Al morir, `die()` también lanza `Debris.spawn()` (`scripts/entities/Debris.gd`, `Node2D` que cuelga del padre y se libera solo; sigue el `time_scale`): un destello blanco de 16 px en el primer frame, un anillo de humo gris (`draw_arc`) que crece y se desvanece, y 5-8 trozos cuadrados de 2-3 px con colores sacados del frame actual del sprite. Salen en direcciones al azar a 50-130 px/s, giran, frenan y se desvanecen en 0,5 s. Con `effect_scale()` mayor que 1 (naves grandes) salen más trozos, más grandes y más lejos, y el destello y el anillo crecen. No sale al llegar a la estación.
- Barra de vida (`scripts/entities/HealthBar.gd`, hija del enemigo creada en `setup()`): `draw_rect` sin suavizado encima del sprite, del ancho del frame (`effect_scale() * 32`), 2 px de alto con contorno negro y fondo `#14060a`. Relleno verde, ámbar `#ecb23c` por debajo del 50 % y rojo `#f0323c` por debajo del 25 %. Oculta con la vida llena; `take_damage()` la actualiza. No gira (el `PathFollow2D` tiene `rotates = false`; solo gira el sprite).

### Curación (Mender)

La Mender se vacía para curar: pasa su propia vida a otra nave con un rayo. Si nadie la toca, se gasta sola y muere (con su botín normal), pero habrá salvado a otra.

- Con `data.heal_rate` > 0 (10 en la Mender), `setup()` le crea un `HealBeam` y en cada `_process` `_update_heal_beam()` busca la curada si no tiene una válida: la nave del grupo `enemies` con menos vida en proporción (`hp / max_hp`) que no sea ella, esté viva, dañada y a `HEAL_RANGE` (64 px) o menos. La mantiene hasta que muere, se aleja o queda llena; entonces busca otra (sin ninguna, el rayo se oculta y no gasta nada).
- Cada frame le pasa `data.heal_rate * delta` de vida: `heal()` la suma sin pasar de `max_hp` y devuelve lo curado, que es lo que pierde la Mender (`set_health()`). Si llega a 0, `die()`.
- `set_health(value)`: pone la vida sin golpe ni efectos y actualiza la barra y el dibujo (`_update_drain_frames()`).
- `show_heal(amount)`: en la curada, al engancharse (solo la onda) y cada `HEAL_PULSE` (1 s) con lo acumulado ("+10"): número con `FloatingText` en verde `#7ee89a`, chispas de `HealEffect` y la onda verde: el shader del Amplificador en las torretas (`amp_scan.gdshader`, ver [torretas.md](torretas.md)) con `#f0fff4` y `#7ee89a`, 0,45 s y estela de 3 filas. No pisa otro material (la disolución del camuflaje).
- `data.drain_frames` (opcional): `SpriteFrames` de más llena a casi vacía. Con N, el nivel es `int((1 - hp / max_hp) * (N + 1))`; el 0 es `sprite_frames`. Al cambiar se conserva la animación y el frame. En la Mender son los 5 tamaños del saco; también encoge al recibir daño.
- `HealBeam` (`scripts/entities/HealBeam.gd`, hijo de la Mender con `top_level`, `z_index` 5): línea de 1 px por píxeles (Bresenham, sin antialiasing) de la punta de la aguja (`NEEDLE_TIP`, girada con el sprite) al centro de la curada, en `#3cb860` al 55 % de opacidad, con pulsos `#c4f5d0` y `#7ee89a` cada 8 px que viajan a 40 px/s hacia la curada.
- `HealEffect` (`scripts/entities/HealEffect.gd`, estático, sin escena, con la rampa `#1c7440`, `#3cb860`, `#7ee89a`, `#c4f5d0`): `spawn_sparks()`, 6 chispas de 1 px (cabeza clara y estela debajo) que suben unos 10 px en 0,4 s, opacas la primera mitad y se desvanecen en la segunda. Cuelga de la nave curada (`z_index` 5) para seguirla.
- En el nivel 6 salen cuatro, detrás de una nave del mismo camino (oleadas 2 y 3).

## Comunicación con el resto

- Señales `died(reward)` y `reached_end(damage)`: las recoge `Spawner` y las reenvía a `Level` (dinero y derrota).
- Grupo `enemies`: lo consultan `Beam` y `Chain` para buscar objetivos.
- Las torretas lo detectan por el `Area2D` y leen `get_remaining_distance()` (longitud del camino - `progress`), `hp` y `global_position`.
- `FocusBeam` modifica directamente `sprite.modulate` y llama a `_rest_color()`.

## Plan de naves

Las naves de arriba se van a rediseñar por nichos (10 base y 10 con mecánica, con nombres en inglés): ver [naves-plan.md](naves-plan.md), provisional hasta que estén todas hechas.
