# Torretas y ataques

## Colocación: BuildManager

`scripts/level/BuildManager.gd` (clase `BuildManager`), nodo hijo de `Level`. Exporta `grid: Grid` y `turret_scene` (`scenes/entities/Turret.tscn`). `Level` le asigna `state: LevelState`.

En `_unhandled_input`:

- **Mover el ratón**: si hay torreta seleccionada y la casilla bajo el cursor es construible, muestra una vista previa en el centro de la casilla: el icono de la torreta al 60 % de opacidad y su rango dibujado en blanco al 15 % (el Amplificador, su aura en ámbar, ver "Amplificador"). Si no, la oculta.
- **Clic izquierdo**: si hay torreta seleccionada, `grid.can_build(cell)` y `state.spend_money(data.cost)`, instancia la torreta como hija de `BuildManager`, la coloca en el centro de la casilla y la registra en `Grid`.
- **Clic izquierdo sobre una torreta ya colocada** (se mira antes que lo de colocar): siempre `state.inspect_placed(turret)` (no fusiona por clic); la ficha enseña la torreta y sale encima de ella el recuadro `TurretActions` con vender y, si tiene `fusion`, mejorar (ver abajo).
- **Clic izquierdo donde no se puede construir** (el espacio, o cualquier casilla vacía sin torreta de la tienda elegida): `_deselect_all()` suelta todo, como el clic derecho y además la torreta colocada: `state.selected_turret = null`, `state.inspected = null` (la ficha vuelve al escáner, sin botones ni alcance) y oculta la vista previa.
- **Clic derecho**: pone `state.selected_turret = null` y oculta la vista previa.

`stop_building()` oculta la vista previa y hace que `_unhandled_input` deje de hacer nada el resto de la partida. Lo llama `Level` al perder o ganar.

Tras colocar una torreta la selección se mantiene, así que se pueden colocar varias seguidas.

## Mejorar (fusión)

Se selecciona una torreta colocada que tenga `TurretData.fusion` y se pulsa "Mejorar (-X€)" en el recuadro `TurretActions` sobre la torreta (`TurretActions.upgrade_requested` -> `LevelUI` -> `LevelState.upgrade_requested` -> `BuildManager.upgrade_selected`, solo en `PLAYING`). Gasta `fusion.cost`, siempre 2 × el coste de la base (sin dinero el botón se ve apagado y no hace nada), quita la torreta vieja (`remove_child` + `queue_free`, para que `Grid` libere la casilla antes de registrar la nueva), instancia la fusionada en la misma casilla con `invested = vieja.invested + fusion.cost`, la registra en `Grid` y la inspecciona. La selección de la tienda no cambia. La fusionada no tiene `fusion`, así que no enseña el botón ni se vuelve a mejorar, y no sale en la tienda.

La fusionada es otro `TurretData` (`resources/turret_data/<x>_fusion.tres`) con sprites en `assets/sprites/turrets/<x>_fusion/` y ataque propio; el campo `fusion` de la base la enlaza:

| Fusionada | Sustituye a | Coste | Daño | Alcance | Cadencia (s) | Diferencia |
|---|---|---|---|---|---|---|
| Cañón cuádruple | Cañón doble | 200 | 9 | 72 | 0,15 | Cuatro cañones, ráfaga rápida |
| Minigun pesada | Minigun | 400 | 16 | 96 | 0,3 → 0,04 | Sobrecalentamiento mejor: 90 disparos, parada de 2 s |
| Cryo ventisca | Cryo | 500 | 30 | 96 | 2,0 | Onda mayor (`wave_scale` 1,5), frena al 35 % durante 4,5 s |
| Cañón de asedio | Cañón pesado | 600 | 110 | 96 | 1,6 | Explota en área de 40 px (`splash_radius`) |
| Tormenta | Tesla | 800 | 80 | 120 | 1,3 | Cadena de 6 objetivos, saltos de 80 px |
| Rail Gauss | Rail | 1500 | 600 | 176 | 4,5 | Haz de 900 px y `half_width` 16 |
| Aniquilador | Disintegrator | 1300 | 100/220/450 por s | 128 | no se usa | Sube de nivel en la mitad de tiempo (`level_time` 0,75) |
| Amplificador mayor | Amplificador | 1000 | no ataca | aura 100 | no se usa | Las torretas de su aura ganan el efecto mayor |

## Vender

Al construir en una casilla libre, `BuildManager` emite `LevelState.turret_placed` (no al mejorar); la escucha el tutorial.

`LevelState.sellable_turret` es la torreta colocada seleccionada. `inspect_placed` la fija junto con `inspected`; cualquier otro cambio de `inspected` la suelta. `LevelState.sell_selected_turret()` suma `Turret.get_sell_value()` (mitad de `Turret.invested`, redondeada hacia abajo; `invested` es el coste al colocar y suma `fusion.cost` al fusionar), hace `queue_free` de la torreta (al salir del árbol `Grid.register_turret` libera la casilla) y suelta la selección. Al vender sale un `+X€` flotante sobre la casilla (`FloatingText`, ver [enemigos.md](enemigos.md)). No cuenta en el resumen de partida. Solo vende en `PLAYING` (lo comprueba `LevelUI`).

## Escena y script

`scenes/entities/Turret.tscn` + `scripts/entities/Turret.gd` (clase `Turret`).

- `AnimatedSprite2D`: base fija.
- `Cannon` (`AnimatedSprite2D`): cañón, dibujado mirando hacia arriba.
- `RangeDetector/CollisionShape2D` (`Area2D`): rango de ataque.
- `Timer`: cooldown.

En `_ready` copia de `data: TurretData` los sprites, la forma del rango y `attack_cooldown`, y arranca el temporizador.

Si la opción `show_turret_range` de `Settings` está activada, `_draw` pinta el rango de la torreta bajo sus sprites (la forma del detector, que crece con el efecto de alcance del Amplificador), con el mismo estilo que la vista previa: relleno cian casi transparente y borde cian `#40e0f0` de 1 px sin antialias, dibujado por `BuildManager.draw_range_circle` (`RANGE_FILL_COLOR`, `RANGE_BORDER_COLOR`). Con `TurretData.min_range` > 0 (Orbitador) el alcance es un anillo: el relleno va solo entre `min_range` y el radio del detector, y el borde se pinta en los dos radios; igual en la vista previa. Cada torreta escucha `Settings.changed` y se redibuja, así que el rango aparece o desaparece al cambiar la opción en plena partida. Además, con el ratón sobre la torreta (`_physics_process`, casilla de 16 px) también lo dibuja aunque la opción esté apagada, esté seleccionada o no. La selección en el mapa (`selected`, que pone `LevelState.sellable_turret`) no dibuja el alcance: pinta un contorno ámbar `#ecb23c` de 1 px pegado por fuera a la silueta opaca de la base y el cañón, sin antialias (nodo hijo `_selection_border`, `z_index` 1, por encima de los sprites; se recalcula cada frame desde las imágenes de las texturas, cacheadas, para seguir el giro y la animación del cañón), el mismo color que el `TurretButton` seleccionado.

### Objetivo

- `enemies_in_range` se mantiene con las señales `area_entered` y `area_exited` del detector.
- `_get_target()` conserva el objetivo mientras siga vivo y dentro del rango. Si no, elige el enemigo al que menos le falta para llegar a la estación (`Enemy.get_remaining_distance()`), aunque esté en otro camino.
- Con `TurretData.min_range` > 0 el rango es un anillo: `_is_too_close()` descarta como objetivo a los enemigos a menos de `min_range` del centro.

### Apuntado

Cada frame el cañón gira hacia el objetivo a `turn_speed` grados/s (0 = al instante). Sin objetivo se queda donde está. Se considera alineado dentro de 12° (`AIM_TOLERANCE`).

### Disparo

Al cumplirse el cooldown:

- Sin objetivo: no hace nada.
- Si el cañón está alineado: dispara.
- Si no lo está: para el temporizador y dispara en cuanto se alinee (`_pending_shot`), y entonces lo reinicia.

### Sobrecalentamiento

Opcional, solo torretas de bala (Minigun y Minigun pesada). Lo activa `TurretData.overheat_shots > 0`; sin configurar no cambia nada.

- `Turret._heat` va de 0 a 1 y sube `1 / overheat_shots` en cada disparo. El siguiente cooldown es `lerp(attack_cooldown, overheat_min_cooldown, t²)` con `t = min(_heat / FULL_SPEED_HEAT, 1)`: empieza lento, acelera, y desde la mitad del calor (`FULL_SPEED_HEAT` 0,5) dispara a tope hasta sobrecalentarse (se reinicia el `Timer` con ese valor).
- Al llegar a 1 se sobrecalienta: para el `Timer`, no apunta ni dispara durante `overheat_time` s y base y cañón parpadean entre rojo (`HEAT_TINT`) y rojo brillante (`OVERHEAT_FLASH`) cada 0,12 s. Luego `_heat` vuelve a 0 y dispara a la cadencia base.
- Calor visible: `HeatGlow` (`scripts/entities/HeatGlow.gd`, hijo del cañón en `muzzle_offset`, se crea con el primer calor) pinta en píxeles un halo naranja `#ff7326` que crece de 4 a 14 px de radio y se hace más opaco con `_heat`, y chispas de 1 px (amarillo → naranja → rojo, 0,5 s de vida) que salen en todas direcciones a `heat² × 30` por segundo. Sobrecalentada, el halo palpita y salen 60 chispas más por segundo.
- Sin objetivo se enfría poco a poco: pierde todo el calor en `overheat_cool_time` s.
- Base y cañón se tiñen de blanco a rojo según el calor. Con el EMP todo esto se congela (no se enfría ni cuenta la parada).
- Valores: Minigun 0,4 → 0,05 s, 60 disparos, parada 3 s; Minigun pesada 0,3 → 0,04 s, 90 disparos, parada 2 s. Ambas se enfrían en 3 s. El halo de calor sale en la boca de los tubos (`muzzle_offset` (0, -13)).

### Tubos rotativos

Opcional, solo torretas de bala (Minigun y Minigun pesada). Lo activa `TurretData.spin_up_time > 0`; el cañón tiene, en vez de `fire_0`/`fire_1`, una animación `spin` en bucle (4 frames a 12 FPS) que se reproduce siempre y cuya velocidad (`speed_scale`) lleva `Turret._update_spin`.

- `Turret._spin` va de 0 (parados) a 1 (listos). Con objetivo y sin sobrecalentar sube en `spin_up_time` s (Minigun 0,35, Minigun pesada 0,3); si no, baja en `SPIN_DOWN_TIME` (0,6 s).
- Hasta que `_spin` llega a 1 no dispara: el cooldown cumplido queda pendiente (`_pending_shot`) y la bala sale en cuanto los tubos están a tope y el cañón alineado. Así los tubos empiezan a girar un momento antes del primer disparo.
- La velocidad de la animación es `_spin × attack_cooldown / cooldown actual` (con sobrecalentamiento, el de `_heat_cooldown`), con tope `SPIN_MAX_SCALE` (5, unos 60 FPS): gira más deprisa cuanto más rápido dispara, y frena al enfriarse o quedarse sin objetivo.
- Sobrecalentada frena hasta pararse y, al volver, tiene que arrancar otra vez. Un EMP los para en seco (`_spin = 0`).

### Apagada por EMP

`Turret.disable(seconds)` (lo llama el pulso EMP de la Saboteadora, ver [enemigos.md](enemigos.md)). Todas las torretas están en el grupo `turrets`.

- `disabled = true`: `_process` no apunta, el `Timer` de cooldown se pausa (`paused`, así conserva lo que le quedaba) y el haz continuo (`FocusBeam`) se corta. Si el cañón estaba cargando o disparando vuelve a `default`, y el frame de disparo de onda, cadena o haz no se lanza.
- Base y cañón se tiñen de azul muy oscuro (`DISABLED_TINT`) y el cañón se queda quieto (`speed_scale` 0).
- Mientras dura, `EmpSparks` (`scripts/entities/EmpSparks.gd`) pinta en píxeles sin antialiasing 4 zigzags de chispas en `#2a6ae6`, `#78bcff` y `#e6f6ff` que cambian de sitio cada 0,06 s, y encima de la torreta un icono de "sin energía" de 9x10 (rayo ámbar `#ecb23c`/`#ffe082` con contorno `#0c0e16`, tachado en diagonal con 2 px de `#f0323c`) que parpadea cada 0,25 s. En los últimos 2 s el parpadeo se acelera poco a poco hasta 0,06 s, como aviso de que la torreta está a punto de volver. `Turret.disable` le pasa la duración con `EmpSparks.start(seconds)`, también al renovarla.
- A los `seconds` segundos (tween de la torreta, sigue la velocidad del juego) vuelve a funcionar con un destello blanco de 0,3 s en base y cañón. Otro pulso mientras está apagada renueva la duración, no se acumula.

### Sonido

`Turret` crea un `AudioStreamPlayer2D` (bus `SFX`, polifonía 2) con `TurretData.shoot_sound`. Suena en cada disparo: al lanzar la bala, y en el `fire_frame` de la onda, la cadena y el haz (así el sonido va con el efecto, no con la carga). En el haz continuo (`FocusBeam`) suena mientras el haz está activo: se repite si el audio acaba antes y se corta al soltar. `BulletData.hit_sound` (opcional, solo el Cañón pesado y su fusión) suena al impactar, en un reproductor aparte porque la bala se libera.

**Corte del disparo:** cuando la torreta se queda sin objetivo (en `_process` para las de bala, en `_on_attack_timeout` para todas) o la apaga un EMP, el disparo que siga sonando baja `volume_db` a -40 dB en 0,12 s (`Tween`) y se para. Un disparo nuevo cancela el fundido y devuelve `volume_db` a 0. El Rail (haz) no se corta en `_process`, para que su disparo no se apague justo al matar al objetivo; el haz continuo lo gestiona `FocusBeam`.

**Carga:** `TurretData.charge_sound` (opcional) crea un segundo reproductor (bus `SFX`). Suena al empezar `fire_0` (en `_shoot` del haz y en `_on_attack_timeout` de las estáticas) y se para en el `fire_frame`, cuando sale el disparo, o al apagarla un EMP. Lo llevan el Rail y la Tesla con sus fusiones (`RailgunCharging`, `CharginTurret`). La Cryo no, porque `IceCharging` dura 9,6 s. Los sonidos son más largos que la carga (Rail: 1,6 s de 4,1 s; Tesla: 0,19 s de 1,16 s), así que se oye solo su inicio.

Las torretas de onda y de cadena no giran el cañón ni usan `_process`.

## Datos

`TurretData` (`scripts/resources/TurretData.gd`): `name`, `cost`, `attack_cooldown`, `icon`, `sprite_frames`, `attack_range`, `muzzle_flash`, `muzzle_offset`, `cannon`, `turn_speed`, y uno de estos campos, que decide el tipo de ataque: `bullet_data`, `pulse`, `chain`, `beam`, `focus_beam`, `orbit`. `min_range`: radio mínimo opcional; con más de 0 el alcance es un anillo entre él y `attack_range` (ver Objetivo). `overheat_shots`, `overheat_min_cooldown`, `overheat_time`, `overheat_cool_time`: sobrecalentamiento opcional (ver Disparo). `spin_up_time`: tubos rotativos opcionales (ver Tubos rotativos). `shoot_sound`: sonido del disparo. `amp_effect`: lo que gana dentro del aura de un Amplificador; `amplifier_level`: mayor que 0 en los Amplificadores (ver "Amplificador"). `money_amount`: mayor que 0 en los Mineros, el dinero que dan cada `attack_cooldown` s (ver "Minero"). `fusion`: el `TurretData` en el que se convierte al fusionarla con otra igual (null en las fusionadas). Además `description`, una frase corta opcional que sale al final de la ficha (ver [ui.md](ui.md)); las 8 torretas que atacan la tienen. La ficha pinta todas las torretas en cian `#40e0f0` (`TurretData.ACCENT_COLOR`, ver [ui.md](ui.md)).

Funciones para la ficha:

- `get_stats() -> Array[StatEntry]`: en el Amplificador solo COSTE y AURA (radio de `attack_range`). En el Minero, COSTE, GANANCIA (`money_amount`, icono `reward`) e INTERVALO (`attack_cooldown`). En las demás, filas comunes (COSTE con `€`, ALCANCE = radio del `CircleShape2D` de `attack_range` (con `min_range`, "mínimo-máximo", p. ej. `40-64`), CADENCIA = `attack_cooldown` en segundos salvo en el haz continuo; con sobrecalentamiento, además CAD. MÁX, AGUANTE (disparos) y PARADA) seguidas de las del ataque. Los nombres de fila son cortos y en mayúsculas (9 caracteres como mucho, ver `StatEntry` en [ui.md](ui.md)).
- `get_attack() -> Resource`: el `*Data` de ataque que tenga (o null).
- `get_attack_label()`: "BALA", "ONDA", "CADENA", "HAZ", "HAZ CONT.", "ÓRBITA" o "APOYO" (Amplificador, `is_amplifier()`, y Minero, `is_miner()`).
- Cada `*Data` de ataque tiene su `get_stats()`:

| Clase | Filas |
|---|---|
| `BulletData` | DAÑO, VEL. BALA, y PERFORA (`pierce`) y ÁREA (`splash_radius`) solo si son > 0 |
| `PulseData` | DAÑO, FRENADO (`-45%` con `slow_factor` 0,55), DURACIÓN (de la ralentización) |
| `ChainData` | DAÑO, OBJETIVOS (`max_targets`), SALTO (`jump_range`) |
| `BeamData` | DAÑO, PERFORA ("TODOS") |
| `OrbitData` | DAÑO, ÁREA (`splash_radius`), CARGAS (`max_orbs`), GIRO (`orbit_speed`, en °/s) |
| `FocusBeamData` | DPS (`45/90` si cabe en `StatEntry.MAX_VALUE_CHARS`, 7 caracteres; si no, una fila por nivel: DPS N1 `45`, DPS N2 `90`, DPS N3 `180`), T. NIVEL |

Los valores usan `UiFormat.abbreviate`, `UiFormat.number` y `UiFormat.seconds`. Un stat nuevo es una entrada más en el `get_stats()` que toque; la ficha no cambia.

Recursos en `resources/turret_data/`:

| Archivo | Nombre | Coste | Cooldown (s) | Rango (px) | Giro (°/s) | Ataque |
|---|---|---|---|---|---|---|
| `turret` | Cañón doble | 100 | 0,25 | 56 | 240 | Bala: 5 de daño, 300 px/s |
| `minigun` | Minigun | 200 | 0,4 | 80 | 270 | Bala trazadora: 8 de daño, 400 px/s. Sobrecalentamiento: 0,4 → 0,05 s, 60 disparos (a tope desde el 30), parada de 3 s. Sonido provisional: `Turret/DobleLaserShoot.wav` |
| `cryo` | Cryo | 250 | 2,0 | 64 | no gira | Onda: 12 de daño, velocidad al 55 % durante 3,5 s |
| `rocket_launcher` | Cañón pesado | 300 | 1,5 | 88 | 180 | Bala: 45 de daño y explota en área de 30 px, 200 px/s |
| `tesla` | Tesla | 400 | 1,3 | 110 | no gira | Cadena: 45 de daño, 3 enemigos, saltos de 64 px |
| `rail` | Rail | 750 | 5,0 | 160 | 45 | Haz: 300 de daño a toda la línea, 700 px de largo |
| `disintegrator` | Disintegrator | 650 | no se usa | 112 | 140 | Haz continuo: 45, 90 y 180 de daño/s |
| `orbiter` | Orbitador | 450 | 1,6 | anillo 40-64 | no gira | Órbita: cargas de 80 de daño en área de 22 px, hasta 4, a 90°/s. Mejora: Cinturón (`orbiter_fusion`, 900): 1,0 s, 140 de daño, área 26, hasta 5, a 110°/s. Sin sonido |
| `amplifier` | Amplificador | 500 | no se usa | aura 100 | no gira | Ninguno: amplifica a las torretas de alrededor |
| `miner` | Minero | 300 | 5,0 (intervalo) | no tiene | no gira | Ninguno: +10€ cada 5 s de oleada (la Excavadora, +20€) |

Balance de costes: los costes suben con el orden de desbloqueo (100, 200, 250, 300, 300, 400, 450, 500, 650 y 750 €) y cada mejora cuesta el doble que su base (la torreta fusionada suma 3 × la base). Las torretas no destacan por tener más números que las anteriores, sino por su mecánica:

- **Precio ≈ valor.** El daño útil por euro es parecido en todas las que atacan: ronda 0,17-0,20 DPS/€ (el Cañón doble, 0,20). Tres Cañones dobles (300 €) rinden como un Cañón pesado (60 de DPS útil los dos), aunque el pesado ocupa una sola casilla y tiene más alcance y área.
- **Lo que justifica la cara es la casilla.** Los huecos son limitados: una torreta cara saca mucho más daño de una casilla y suma alcance, área o perforación. Por eso en niveles avanzados se prefiere la cara, no porque las baratas sean malas por euro.
- **Cañón doble:** básico pero digno. Más barato y fácil de entender, pero con poco alcance (56 px), poco daño por bala y sin área; su mejora llega a 72 px. Sirve para aprender y en niveles avanzados ya no tiene argumentos.
- **Las de mecánica** (Cryo, Tesla, Orbitador, Amplificador, Disintegrator, Rail, Minero) tienen su sitio en combos, contra ciertos enemigos o en ciertas posiciones: la Cryo frena a todo lo que hay en su alcance (por eso su DPS/€ es bajo a propósito y vale lo que multiplica a las demás), el Orbitador pega a los camuflados, el Rail y la Tormenta atraviesan o encadenan grupos, el Disintegrator crece contra un único enemigo duro, y el Amplificador y el Minero no atacan.

DPS útil = daño por segundo contra un objetivo × objetivos que se estiman golpeados (1 si pega a uno, 2 el Cañón pesado, 2,5 el Rail, etc.). La Minigun usa la media de una ráfaga completa (disparo + parada), el Disintegrator la de los 6 primeros segundos sobre el mismo enemigo, y el Orbitador el ritmo al que genera cargas. DPS/€ divide por lo invertido (base + mejora). Al ser una sola casilla, DPS/casilla = DPS útil. Valores de ahora, con los de antes entre paréntesis:

| Torreta | Invertido (€) | Objetivos | DPS útil | DPS/€ | DPS/casilla |
|---|---|---|---|---|---|
| Cañón doble | 100 | 1 | 20 (20) | 0,20 (0,20) | 20 |
| Cañón cuádruple | 300 | 1 | 60 (47) | 0,20 (0,16) | 60 |
| Minigun | 200 | 1 | 37 (28) | 0,18 (0,14) | 37 |
| Minigun pesada | 600 | 1 | 107 (67) | 0,18 (0,11) | 107 |
| Cryo | 250 | 3 | 18 (8) | 0,07 (0,03) | 18 + frena 45 % |
| Cryo ventisca | 750 | 4 | 60 (16) | 0,08 (0,02) | 60 + frena 65 % |
| Cañón pesado | 300 | 2 | 60 (60) | 0,20 (0,20) | 60 |
| Cañón de asedio | 900 | 2,5 | 172 (156) | 0,19 (0,17) | 172 |
| Tesla | 400 | 2,2 | 76 (51) | 0,19 (0,13) | 76 |
| Tormenta | 1200 | 3,5 | 215 (121) | 0,18 (0,10) | 215 |
| Rail | 750 | 2,5 | 150 (100) | 0,20 (0,13) | 150 |
| Rail Gauss | 2250 | 3 | 400 (267) | 0,18 (0,12) | 400 |
| Disintegrator | 650 | 1 | 124 (110) | 0,19 (0,17) | 124 |
| Aniquilador | 1950 | 1 | 378 (267) | 0,19 (0,14) | 378 |
| Orbitador | 450 | 1,5 | 75 (38) | 0,17 (0,08) | 75 |
| Cinturón | 1350 | 1,8 | 252 (108) | 0,19 (0,08) | 252 |

Los efectos del Amplificador (`amp_effect`) no cambian: multiplican lo que ya hace cada torreta (más alcance, más área, más objetivos, calentarse antes, cargar antes, subir de nivel antes, girar antes, frenar más), así que mantienen la proporción entre ellas. El Minero (+10 €/5 s) y la Excavadora (+20 €/5 s) devuelven en unos 150 y 225 s de oleada lo que cuestan.

## Amplificador

Torreta de apoyo (`amplifier.tres`, mejora `amplifier_fusion.tres`, desde el nivel 8). Su `TurretData` no tiene ataque y lleva `amplifier_level` 1 (2 el mayor). `Turret._ready` la deja sin apuntar, con el `Timer` parado, sin sonido y con el emisor (`cannon`, animación `default` en bucle) siempre animado; el EMP la apaga igual que a las demás.

- **Aura**: círculo de `attack_range` (100 px, `collision_shapes/amplifier.tres`, igual en el mayor) alrededor del Amplificador. Una torreta está amplificada si su centro cae dentro del aura de un Amplificador encendido. Varios no se suman: cuenta el de más nivel. Lo calcula `Grid._update_amplification()`, que llama a `Turret.set_amplification(nivel)` en todas las torretas; se pide (`_queue_amplification`, una vez por frame como mucho) al registrar una torreta, al salir una del árbol (vender, mejorar) y cuando un Amplificador emite `Turret.power_changed` (se apaga por un EMP o vuelve). Las casillas de torreta de los mapas están separadas 5 o 6 casillas, así que el aura no se mide en casillas.
- **Efecto**: cada torreta que ataca tiene en `TurretData.amp_effect` un `AmpEffect` (`scripts/resources/AmpEffect.gd`, recursos en `resources/amp_effects/`) con `kind`, `normal` (Amplificador) y `major` (Amplificador mayor). Las fusionadas usan el de su base. `Turret.amp_value(kind, fallback)` da el valor si está amplificada y su efecto es de ese tipo; si no, `fallback`. **Toda torreta nueva que ataque necesita su efecto.**

| Torreta | `kind` | Normal / mayor | Dónde se aplica |
|---|---|---|---|
| Cañón doble | `RANGE` | +25 % / +40 % de alcance | `Turret._update_range`: el detector usa un círculo propio más grande (la forma de `data` es compartida) |
| Cañón pesado | `SPLASH` | +50 % / +80 % de área | `Bullet`: radio de la explosión y escala del impacto |
| Minigun | `HEAT` | ×2 / ×3 | `Turret._heat_cooldown`: `FULL_SPEED_HEAT` se divide; llega a la cadencia máxima en 15 / 10 disparos (la pesada en 22 / 15) |
| Cryo | `SLOW` | +20 % / +30 % de frenado | `Pulse._slow_factor`: velocidad × (1 − valor), sin bajar de `AmpEffect.MIN_SLOW_FACTOR` (0,25) |
| Tesla | `TARGETS` | +2 / +3 objetivos | `Chain.spawn` |
| Rail | `CHARGE` | ×2 / ×3 | `Turret._shoot`: `fire_0` va a esa velocidad hasta el `fire_frame` y luego a 1 |
| Disintegrator | `LEVEL_TIME` | ×2 / ×3 | `FocusBeam`: `level_time` se divide |
| Orbitador | `ORBIT_SPEED` | ×1,5 / ×2 | `Orbit._process`: las cargas giran más rápido |

- **Visual**: `AmpAura` (`scripts/entities/AmpAura.gd`, hijo del Amplificador, detrás de sus sprites, como la onda de la Cryo) suelta una onda cada 2,5 s (la primera a los 0,4 s): un anillo de 1 px sin antialias que crece en 1,1 s desde el borde del emisor (10 px) hasta el radio del aura, frenando al final, con el frente en `#ffe082` y dos ecos 2 y 4 px por dentro en `#ecb23c` y `#96641e`, y se apaga al llegar. Al pasar por una torreta amplificada le lanza `Turret.flash_amp`, una versión ligera y en ámbar del escaneo de construir (`resources/shaders/amp_scan.gdshader`, 0,45 s): la torreta sigue sólida, una línea ámbar casi blanca sube por filas de píxeles con 3 filas de estela (la última punteada) y el contorno del sprite brilla en ámbar y se apaga en 3 pasos. No pisa la animación de construir, y construir o mejorar la corta. Con el Amplificador apagado por un EMP no salen ondas. El alcance fijo (relleno casi transparente y borde `#ecb23c`, `AmpAura.draw_circle_aura`) solo se pinta donde las demás torretas pintan el suyo: al pasar el ratón, con la torreta seleccionada, con la opción de mostrar alcances y en la vista previa de `BuildManager`.
- **Ficha**: la de una torreta amplificada añade una fila con lo que gana (`AmpEffect.get_stat`, icono `amp.png`: ALCANCE, ÁREA, ACELERA, FRENADO, OBJETIVOS, CARGA o SUBE NIV. o GIRO). `Turret.amplification_changed` la rehace si cambia el aura con la ficha abierta (ver [ui.md](ui.md)).

## Minero

Torreta de apoyo que da dinero (`miner.tres`, mejora `miner_fusion.tres` "Excavadora" por 600€, desde el nivel 5). Su `TurretData` no tiene ataque ni alcance y lleva `money_amount` 10 (20 la Excavadora) y `attack_cooldown` 5 s. Sirve para invertir pronto: se paga sola en unos 150 s de oleada.

- **Cuándo genera**: solo con una oleada en curso. `LevelState.wave_in_progress` se pone a true con `Spawner.wave_started` y a false con `Spawner.wave_cleared` (lo hace `Level`), y emite `wave_in_progress_changed`. `Turret._setup_miner` deja la torreta sin apuntar y con el `Timer` de `attack_cooldown` pausado mientras no hay oleada o está apagada (`_update_mine_timer`); entre oleadas conserva lo que le quedaba.
- **Animación**: el cañón (`miner_cannon.tres`) anima `default` en bucle (4 frames a 6 fps: la broca gira dentro del pozo y saltan esquirlas de roca). Al cumplirse el `Timer`, espera a que acabe la vuelta de `default` (`animation_looped`) y reproduce `generate` (7 frames a 10 fps, sin bucle): la punta se pone dorada y suelta chispas, sale una pepita del pozo que se parte en dos y cada mitad cae en una tolva, que brilla y queda un poco más llena. En el frame 4 (`MINE_PAYOUT_FRAME`, cuando caen las pepitas) da el dinero con `LevelState.add_money` y saca el `+X€` con `FloatingText` sobre la torreta.
- **EMP**: el pulso de la Saboteadora la apaga como a las demás: corta `generate` antes del cobro, pierde la generación pendiente y el `Timer` se queda en pausa hasta que vuelve.
- No se amplifica (no tiene `amp_effect`) y no pinta alcance.

## Tipos de ataque

### Bala

`scenes/entities/Bullet.tscn` + `scripts/entities/Bullet.gd` + `BulletData`.

- Sale de `muzzle_offset` girado con el cañón. Si `muzzle_offset.x` no es 0 (Cañón doble), los disparos alternan de lado.
- Persigue al objetivo: corrige la dirección cada frame mientras el objetivo exista; si desaparece sigue recta.
- Daña al primer `Enemy` cuya área toque, sea o no el objetivo, deja la animación `impact_frames` y se libera.
- Se libera sola a los 5 s.
- El cañón reproduce `fire_0`, `fire_1`... alternando en cada disparo (solo cuenta las animaciones `fire_N`; los tubos rotativos no tienen y siguen con su `spin`).

### Onda

`scripts/entities/Pulse.gd` + `PulseData`. Torreta: Cryo.

- Al cumplirse el cooldown el cañón reproduce `fire_0`; la onda nace en el frame `fire_frame`.
- La onda es una animación centrada en la torreta. En cada frame su radio es `start_radius + growth * frame`.
- Cada enemigo del rango que queda entre el radio anterior y el actual recibe el daño y, si sobrevive, la ralentización.

### Cadena

`scripts/entities/Chain.gd` + `ChainData`. Torreta: Tesla.

- Igual que la onda, sale en el frame `fire_frame` de `fire_0`.
- Daña al objetivo y salta al enemigo más cercano al último alcanzado, dentro de `jump_range` y sin repetir, hasta `max_targets`.
- Dibuja un `Line2D` con textura que sigue a los enemigos durante `bolt_time` segundos.

### Haz

`scripts/entities/Beam.gd` + `BeamData`. Torreta: Rail.

- Al disparar, el cañón reproduce `fire_0`. Durante los frames de carga se ve una mira roja desde la boca.
- En `fire_frame` sale el haz hacia donde apunte el cañón en ese momento.
- Daña a todos los enemigos del grupo `enemies` que estén a menos de `half_width` de la línea y dentro de `length`.
- El haz se desvanece pasando por `beam_textures`, una cada `frame_time` segundos.

### Haz continuo

`scripts/entities/FocusBeam.gd` + `FocusBeamData`. Torreta: Disintegrator.

- Es un nodo hijo de la torreta; el temporizador de cooldown se detiene.
- Mientras el cañón está alineado con el objetivo, le hace daño cada frame.
- El nivel del haz es `tiempo sobre el mismo enemigo / level_time`, hasta el último nivel. Cambia el daño por segundo, las texturas del haz, el brillo de la boca, el impacto y cuánto se tiñe el enemigo.
- Al cambiar de objetivo el tiempo vuelve a 0. Si solo se pierde la alineación, el haz se corta pero el tiempo acumulado se conserva.
- Si el haz mata al enemigo deja la animación `death_frames`.

### Órbita

`scripts/entities/Orbit.gd` + `OrbitData`. Torreta: Orbitador (y su mejora, el Cinturón).

- No apunta ni elige objetivo. El emisor no gira (`_is_static`) y `default` está en bucle. En cada cooldown, si hay menos de `max_orbs` cargas en órbita, reproduce `fire_0` y en `fire_frame` (3) genera una; con la órbita llena no hace nada. Genera también sin enemigos, así que entre oleadas se llena.
- `Orbit` es un nodo hijo de la torreta (por encima de torretas y enemigos) y sus hijos son las cargas (`AnimatedSprite2D` con `orb_frames`). Todas giran juntas a `orbit_speed` °/s alrededor de la torreta, a medio camino entre `min_range` y el radio de `attack_range` (52 px). Cada carga nueva sale en espiral desde el borde del emisor (6 px) hasta la órbita en `deploy_time` s, frenando al final, y se coloca en medio del hueco más grande entre las que ya giran, así que quedan repartidas.
- Ya en órbita, choca con el primer enemigo del rango cuyo centro quede a menos de medio ancho del anillo (12 px), aunque esté camuflado (no apunta, choca). Mientras sale en espiral no choca: por eso no alcanza a lo que pasa pegado a la torreta.
- Al chocar hace `damage` a todos los enemigos a menos de `splash_radius` y deja `impact_frames` a escala `impact_scale` (2, un anillo de unos 23 px de radio).
- Con un EMP las cargas se quedan quietas y no chocan; al venderla o mejorarla, las cargas desaparecen con ella.

### Effect

`scripts/Effect.gd`: `Effect.spawn(parent, frames, pos, size)` crea un `AnimatedSprite2D` que reproduce una animación una vez y se libera. Lo usan todos los ataques para impactos y fogonazos.

Límite: `Effect` y `HealEffect` se apuntan al grupo `effects`; `Effect.has_room(tree)` comprueba que haya menos de `MAX_EFFECTS` (60) vivos, o `MAX_EFFECTS_LOW` (20) si el juego va por debajo de `LOW_FPS` (45 FPS): se ajusta solo, sin opción en el menú. Si no hay hueco, el efecto no se crea. `EmpSparks` (uno por torreta, no ráfagas) no cuenta.

## Comunicación con el resto

- `BuildManager` lee y gasta dinero en `LevelState` y consulta `Grid`.
- Las torretas llaman a `Enemy.take_damage`, `Enemy.slow`, `Enemy.flash` y `Enemy.effect_scale`.
- Balas, haces y cadenas se añaden como hijos del padre de la torreta (`BuildManager`).

## Dudas

- Una torreta colocada solo se puede mejorar (fusión) o vender; no hay más mejoras.
- `disintegrator.tres` tiene `attack_cooldown = 1.0`, que el código no usa para esa torreta.
- El nombre de archivo `rocket_launcher` corresponde a la torreta que se llama "Cañón pesado", y `turret` a "Cañón doble". La carpeta es `turret_data` y la clase `TurretData`.

## Animaciones de construir, fusionar y vender

`Turret.play_build()` (se llama tras añadirla al árbol, al colocar y al mejorar por igual): aplica a `sprite` y `cannon` un `ShaderMaterial` (`resources/shaders/hologram_build.gdshader`) y anima `progress` de 0 a 1 en 0,8 s (`BUILD_TIME`). Una línea de escaneo sube de abajo arriba por filas de píxeles del mundo (así base y cañón, que gira, comparten línea y no hay antialiasing); recorre la altura real del sprite (mitad del frame, 16 px) más `BUILD_TRAIL` filas de estela. La línea es un núcleo blanco, una fila cian `#40e0f0` y una estela punteada en 3 pasos sobre la torreta ya sólida. Por encima es un holograma: el relieve del sprite pasa a una rampa de 4 tonos de cian (se lee igual sobre torretas de cualquier color), borde brillante, scanlines que se desplazan, filas que se apagan y parpadeo general. Respeta los tintes de EMP y calor (`modulate`): la parte sólida los conserva y el holograma se oscurece con ellos. Al acabar se quita el material. `Turret.play_sell()` (la llama `LevelState.sell_selected_turret` antes del `queue_free`) deja una copia visual de la torreta que se encoge en 0,25 s con chispas (`CPUParticles2D`, sin gravedad, en todas direcciones y con frenado `damping` de 40) y se libera sola; la casilla queda libre al instante.

## Bajas y daño por torreta

`Turret.kills` y `Turret.damage_dealt` cuentan lo que ha hecho cada torreta. Todos sus ataques (`Bullet.source`, `Beam`, `Chain`, `Pulse`, `FocusBeam`) llaman a `Enemy.take_damage(amount, source)`, que avisa con `Turret.register_damage(dealt, killed)` (el daño es lo que de verdad quitó, sin pasarse de la vida que quedaba). Los poderes no pasan torreta y no cuentan. La fusión hereda ambos contadores. Al vender, `LevelState` guarda la mejor torreta vendida (`retired_top_name`/`retired_top_kills`) para que siga contando en el resumen.
