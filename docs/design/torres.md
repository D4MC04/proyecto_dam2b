# Torres y ataques

## Colocación: BuildManager

`scripts/level/BuildManager.gd` (clase `BuildManager`), nodo hijo de `Level`. Exporta `grid: Grid` y `tower_scene` (`scenes/entities/Tower.tscn`). `Level` le asigna `state: LevelState`.

En `_unhandled_input`:

- **Mover el ratón**: si hay torre seleccionada y la casilla bajo el cursor es construible, muestra una vista previa en el centro de la casilla: el icono de la torre al 60 % de opacidad y su rango dibujado en blanco al 15 %. Si no, la oculta.
- **Clic izquierdo**: si hay torre seleccionada, `grid.can_build(cell)` y `state.spend_money(data.cost)`, instancia la torre como hija de `BuildManager`, la coloca en el centro de la casilla y la registra en `Grid`.
- **Clic izquierdo sobre una torre ya colocada** (se mira antes que lo de colocar): siempre `state.inspect_placed(tower)` (no fusiona por clic); la ficha enseña la torre y aparecen los botones de vender y, si tiene `fusion`, de mejorar (ver abajo).
- **Clic izquierdo donde no se puede construir** (el espacio, o cualquier casilla vacía sin torre de la tienda elegida): `_deselect_all()` suelta todo, como el clic derecho y además la torre colocada: `state.selected_tower = null`, `state.inspected = null` (la ficha vuelve al escáner, sin botones ni alcance) y oculta la vista previa.
- **Clic derecho**: pone `state.selected_tower = null` y oculta la vista previa.

`stop_building()` oculta la vista previa y hace que `_unhandled_input` deje de hacer nada el resto de la partida. Lo llama `Level` al perder o ganar.

Tras colocar una torre la selección se mantiene, así que se pueden colocar varias seguidas.

## Mejorar (fusión)

Se selecciona una torre colocada que tenga `TowerData.fusion` y se pulsa "Mejorar (-X€)" en la ficha (`InfoPanel.upgrade_requested` -> `LevelUI` -> `LevelState.upgrade_requested` -> `BuildManager.upgrade_selected`, solo en `PLAYING`). Gasta `fusion.cost` (sin dinero no hace nada), quita la torre vieja (`remove_child` + `queue_free`, para que `Grid` libere la casilla antes de registrar la nueva), instancia la fusionada en la misma casilla con `invested = vieja.invested + fusion.cost`, la registra en `Grid` y la inspecciona. La selección de la tienda no cambia. La fusionada no tiene `fusion`, así que no enseña el botón ni se vuelve a mejorar, y no sale en la tienda.

La fusionada es otro `TowerData` (`resources/turret_data/<x>_fusion.tres`) con sprites en `assets/sprites/towers/<x>_fusion/` y ataque propio; el campo `fusion` de la base la enlaza:

| Fusionada | Sustituye a | Coste | Daño | Alcance | Cadencia (s) | Diferencia |
|---|---|---|---|---|---|---|
| Cañón cuádruple | Cañón doble | 160 | 6 | 64 | 0,15 | Cuatro cañones, ráfaga rápida |
| Láser doble | Láser | 320 | 22 | 128 | 0,6 → 0,06 | La bala perfora a 1 enemigo extra (`pierce`); sobrecalentamiento mejor: 80 disparos, parada de 4 s |
| Cryo ventisca | Cryo | 400 | 8 | 96 | 2,0 | Onda mayor (`wave_scale` 1,5), frena al 35 % durante 4,5 s |
| Cañón de asedio | Cañón pesado | 480 | 90 | 96 | 1,6 | Explota en área de 40 px (`splash_radius`) |
| Tormenta | Tesla | 560 | 35 | 120 | 1,3 | Cadena de 6 objetivos, saltos de 80 px |
| Rail Gauss | Rail | 800 | 300 | 176 | 4,5 | Haz de 900 px y `half_width` 16 |
| Aniquilador | Disintegrator | 960 | 70/150/320 por s | 128 | no se usa | Sube de nivel en la mitad de tiempo (`level_time` 0,75) |

## Vender

Al construir en una casilla libre, `BuildManager` emite `LevelState.tower_placed` (no al mejorar); la escucha el tutorial.

`LevelState.sellable_tower` es la torre colocada seleccionada. `inspect_placed` la fija junto con `inspected`; cualquier otro cambio de `inspected` la suelta. `LevelState.sell_selected_tower()` suma `Tower.get_sell_value()` (mitad de `Tower.invested`, redondeada hacia abajo; `invested` es el coste al colocar y suma `fusion.cost` al fusionar), hace `queue_free` de la torre (al salir del árbol `Grid.register_tower` libera la casilla) y suelta la selección. Al vender sale un `+X€` flotante sobre la casilla (`FloatingText`, ver [enemigos.md](enemigos.md)). No cuenta en el resumen de partida. Solo vende en `PLAYING` (lo comprueba `LevelUI`).

## Escena y script

`scenes/entities/Tower.tscn` + `scripts/entities/Tower.gd` (clase `Tower`).

- `AnimatedSprite2D`: base fija.
- `Cannon` (`AnimatedSprite2D`): cañón, dibujado mirando hacia arriba.
- `RangeDetector/CollisionShape2D` (`Area2D`): rango de ataque.
- `Timer`: cooldown.

En `_ready` copia de `data: TowerData` los sprites, la forma del rango y `attack_cooldown`, y arranca el temporizador.

Si la opción `show_tower_range` de `Settings` está activada, `_draw` pinta el rango de la torre bajo sus sprites, con el mismo color que la vista previa (`BuildManager.RANGE_COLOR`). Cada torre escucha `Settings.changed` y se redibuja, así que el rango aparece o desaparece al cambiar la opción en plena partida. Además, con el ratón sobre la torre (`_physics_process`, casilla de 16 px) también lo dibuja aunque la opción esté apagada, y lo mismo mientras está seleccionada en el mapa (`selected`, que pone `LevelState.sellable_tower`).

### Objetivo

- `enemies_in_range` se mantiene con las señales `area_entered` y `area_exited` del detector.
- `_get_target()` conserva el objetivo mientras siga vivo y dentro del rango. Si no, elige el enemigo al que menos le falta para llegar a la estación (`Enemy.get_remaining_distance()`), aunque esté en otro camino.

### Apuntado

Cada frame el cañón gira hacia el objetivo a `turn_speed` grados/s (0 = al instante). Sin objetivo se queda donde está. Se considera alineado dentro de 12° (`AIM_TOLERANCE`).

### Disparo

Al cumplirse el cooldown:

- Sin objetivo: no hace nada.
- Si el cañón está alineado: dispara.
- Si no lo está: para el temporizador y dispara en cuanto se alinee (`_pending_shot`), y entonces lo reinicia.

### Sobrecalentamiento

Opcional, solo torres de bala (Láser y Láser doble). Lo activa `TowerData.overheat_shots > 0`; sin configurar no cambia nada.

- `Tower._heat` va de 0 a 1 y sube `1 / overheat_shots` en cada disparo. El siguiente cooldown es `lerp(attack_cooldown, overheat_min_cooldown, t²)` con `t = min(_heat / FULL_SPEED_HEAT, 1)`: empieza lento, acelera, y desde la mitad del calor (`FULL_SPEED_HEAT` 0,5) dispara a tope hasta sobrecalentarse (se reinicia el `Timer` con ese valor).
- Al llegar a 1 se sobrecalienta: para el `Timer`, no apunta ni dispara durante `overheat_time` s y base y cañón parpadean entre rojo (`HEAT_TINT`) y rojo brillante (`OVERHEAT_FLASH`) cada 0,12 s. Luego `_heat` vuelve a 0 y dispara a la cadencia base.
- Calor visible: `HeatGlow` (`scripts/entities/HeatGlow.gd`, hijo del cañón en `muzzle_offset`, se crea con el primer calor) pinta en píxeles un halo naranja `#ff7326` que crece de 4 a 14 px de radio y se hace más opaco con `_heat`, y chispas de 1 px (amarillo → naranja → rojo, 0,5 s de vida) que salen en todas direcciones a `heat² × 30` por segundo. Sobrecalentada, el halo palpita y salen 60 chispas más por segundo.
- Sin objetivo se enfría poco a poco: pierde todo el calor en `overheat_cool_time` s.
- Base y cañón se tiñen de blanco a rojo según el calor. Con el EMP todo esto se congela (no se enfría ni cuenta la parada).
- Valores: Láser 0,5 → 0,15 s, 15 disparos, parada 2 s; Láser doble 0,4 → 0,1 s, 25 disparos, parada 1,5 s. Ambos se enfrían en 3 s.

### Apagada por EMP

`Tower.disable(seconds)` (lo llama el pulso EMP de la Saboteadora, ver [enemigos.md](enemigos.md)). Todas las torres están en el grupo `towers`.

- `disabled = true`: `_process` no apunta, el `Timer` de cooldown se pausa (`paused`, así conserva lo que le quedaba) y el haz continuo (`FocusBeam`) se corta. Si el cañón estaba cargando o disparando vuelve a `default`, y el frame de disparo de onda, cadena o haz no se lanza.
- Base y cañón se tiñen de azul muy oscuro (`DISABLED_TINT`) y el cañón se queda quieto (`speed_scale` 0).
- Mientras dura, `EmpSparks` (`scripts/entities/EmpSparks.gd`) pinta en píxeles sin antialiasing 4 zigzags de chispas en `#2a6ae6`, `#78bcff` y `#e6f6ff` que cambian de sitio cada 0,06 s, y encima de la torre un icono de "sin energía" de 9x10 (rayo ámbar `#ecb23c`/`#ffe082` con contorno `#0c0e16`, tachado en diagonal con 2 px de `#f0323c`) que parpadea cada 0,25 s. En los últimos 2 s el parpadeo se acelera poco a poco hasta 0,06 s, como aviso de que la torre está a punto de volver. `Tower.disable` le pasa la duración con `EmpSparks.start(seconds)`, también al renovarla.
- A los `seconds` segundos (tween de la torre, sigue la velocidad del juego) vuelve a funcionar con un destello blanco de 0,3 s en base y cañón. Otro pulso mientras está apagada renueva la duración, no se acumula.

### Sonido

`Tower` crea un `AudioStreamPlayer2D` (bus `SFX`, polifonía 2) con `TowerData.shoot_sound`. Suena en cada disparo: al lanzar la bala, y en el `fire_frame` de la onda, la cadena y el haz (así el sonido va con el efecto, no con la carga). En el haz continuo (`FocusBeam`) suena mientras el haz está activo: se repite si el audio acaba antes y se corta al soltar. `BulletData.hit_sound` (opcional, solo el Cañón pesado y su fusión) suena al impactar, en un reproductor aparte porque la bala se libera.

**Corte del disparo:** cuando la torre se queda sin objetivo (en `_process` para las de bala, en `_on_attack_timeout` para todas) o la apaga un EMP, el disparo que siga sonando baja `volume_db` a -40 dB en 0,12 s (`Tween`) y se para. Un disparo nuevo cancela el fundido y devuelve `volume_db` a 0. El Rail (haz) no se corta en `_process`, para que su disparo no se apague justo al matar al objetivo; el haz continuo lo gestiona `FocusBeam`.

**Carga:** `TowerData.charge_sound` (opcional) crea un segundo reproductor (bus `SFX`). Suena al empezar `fire_0` (en `_shoot` del haz y en `_on_attack_timeout` de las estáticas) y se para en el `fire_frame`, cuando sale el disparo, o al apagarla un EMP. Lo llevan el Rail y la Tesla con sus fusiones (`RailgunCharging`, `CharginTower`). La Cryo no, porque `IceCharging` dura 9,6 s. Los sonidos son más largos que la carga (Rail: 1,6 s de 4,1 s; Tesla: 0,19 s de 1,16 s), así que se oye solo su inicio.

Las torres de onda y de cadena no giran el cañón ni usan `_process`.

## Datos

`TowerData` (`scripts/resources/TowerData.gd`): `name`, `cost`, `attack_cooldown`, `icon`, `sprite_frames`, `attack_range`, `muzzle_flash`, `muzzle_offset`, `cannon`, `turn_speed`, y uno de estos campos, que decide el tipo de ataque: `bullet_data`, `pulse`, `chain`, `beam`, `focus_beam`. `overheat_shots`, `overheat_min_cooldown`, `overheat_time`, `overheat_cool_time`: sobrecalentamiento opcional (ver Disparo). `shoot_sound`: sonido del disparo. `fusion`: el `TowerData` en el que se convierte al fusionarla con otra igual (null en las fusionadas). Además `description`, una frase corta opcional que sale al final de la ficha (ver [ui.md](ui.md)); las 7 torres la tienen. La ficha pinta todas las torres en cian `#40e0f0` (`TowerData.ACCENT_COLOR`, ver [ui.md](ui.md)).

Funciones para la ficha:

- `get_stats() -> Array[StatEntry]`: filas comunes (COSTE con `€`, ALCANCE = radio del `CircleShape2D` de `attack_range`, CADENCIA = `attack_cooldown` en segundos salvo en el haz continuo; con sobrecalentamiento, además CAD. MÁX, AGUANTE (disparos) y PARADA) seguidas de las del ataque. Los nombres de fila son cortos y en mayúsculas (9 caracteres como mucho, ver `StatEntry` en [ui.md](ui.md)).
- `get_attack() -> Resource`: el `*Data` de ataque que tenga (o null).
- `get_attack_label()`: "BALA", "ONDA", "CADENA", "HAZ" o "HAZ CONT.".
- Cada `*Data` de ataque tiene su `get_stats()`:

| Clase | Filas |
|---|---|
| `BulletData` | DAÑO, VEL. BALA, y PERFORA (`pierce`) y ÁREA (`splash_radius`) solo si son > 0 |
| `PulseData` | DAÑO, FRENADO (`-45%` con `slow_factor` 0,55), DURACIÓN (de la ralentización) |
| `ChainData` | DAÑO, OBJETIVOS (`max_targets`), SALTO (`jump_range`) |
| `BeamData` | DAÑO, PERFORA ("TODOS") |
| `FocusBeamData` | DPS (`40/80` si cabe en `StatEntry.MAX_VALUE_CHARS`, 7 caracteres; si no, una fila por nivel: DPS N1 `40`, DPS N2 `80`, DPS N3 `160`), T. NIVEL |

Los valores usan `UiFormat.abbreviate`, `UiFormat.number` y `UiFormat.seconds`. Un stat nuevo es una entrada más en el `get_stats()` que toque; la ficha no cambia.

Recursos en `resources/turret_data/`:

| Archivo | Nombre | Coste | Cooldown (s) | Rango (px) | Giro (°/s) | Ataque |
|---|---|---|---|---|---|---|
| `turret` | Cañón doble | 100 | 0,25 | 56 | 240 | Bala: 5 de daño, 300 px/s |
| `laser` | Láser | 200 | 0,8 | 112 | 180 | Bala: 15 de daño, 250 px/s, con estela. Sobrecalentamiento: 0,8 → 0,07 s, 55 disparos (a tope desde el 28), parada de 5 s |
| `cryo` | Cryo | 250 | 2,0 | 64 | no gira | Onda: 5 de daño, velocidad al 55 % durante 3,5 s |
| `rocket_launcher` | Cañón pesado | 300 | 1,5 | 88 | 180 | Bala: 45 de daño y explota en área de 30 px, 200 px/s |
| `tesla` | Tesla | 350 | 1,3 | 110 | no gira | Cadena: 25 de daño, 3 enemigos, saltos de 64 px |
| `rail` | Rail | 500 | 5,0 | 160 | 45 | Haz: 150 de daño a toda la línea, 700 px de largo |
| `disintegrator` | Disintegrator | 600 | no se usa | 112 | 140 | Haz continuo: 40, 80 y 160 de daño/s |

## Tipos de ataque

### Bala

`scenes/entities/Bullet.tscn` + `scripts/entities/Bullet.gd` + `BulletData`.

- Sale de `muzzle_offset` girado con el cañón. Si `muzzle_offset.x` no es 0 (Cañón doble), los disparos alternan de lado.
- Persigue al objetivo: corrige la dirección cada frame mientras el objetivo exista; si desaparece sigue recta.
- Daña al primer `Enemy` cuya área toque, sea o no el objetivo, deja la animación `impact_frames` y se libera.
- Se libera sola a los 5 s.
- El cañón reproduce `fire_0`, `fire_1`... alternando en cada disparo.

### Onda

`scripts/entities/Pulse.gd` + `PulseData`. Torre: Cryo.

- Al cumplirse el cooldown el cañón reproduce `fire_0`; la onda nace en el frame `fire_frame`.
- La onda es una animación centrada en la torre. En cada frame su radio es `start_radius + growth * frame`.
- Cada enemigo del rango que queda entre el radio anterior y el actual recibe el daño y, si sobrevive, la ralentización.

### Cadena

`scripts/entities/Chain.gd` + `ChainData`. Torre: Tesla.

- Igual que la onda, sale en el frame `fire_frame` de `fire_0`.
- Daña al objetivo y salta al enemigo más cercano al último alcanzado, dentro de `jump_range` y sin repetir, hasta `max_targets`.
- Dibuja un `Line2D` con textura que sigue a los enemigos durante `bolt_time` segundos.

### Haz

`scripts/entities/Beam.gd` + `BeamData`. Torre: Rail.

- Al disparar, el cañón reproduce `fire_0`. Durante los frames de carga se ve una mira roja desde la boca.
- En `fire_frame` sale el haz hacia donde apunte el cañón en ese momento.
- Daña a todos los enemigos del grupo `enemies` que estén a menos de `half_width` de la línea y dentro de `length`.
- El haz se desvanece pasando por `beam_textures`, una cada `frame_time` segundos.

### Haz continuo

`scripts/entities/FocusBeam.gd` + `FocusBeamData`. Torre: Disintegrator.

- Es un nodo hijo de la torre; el temporizador de cooldown se detiene.
- Mientras el cañón está alineado con el objetivo, le hace daño cada frame.
- El nivel del haz es `tiempo sobre el mismo enemigo / level_time`, hasta el último nivel. Cambia el daño por segundo, las texturas del haz, el brillo de la boca, el impacto y cuánto se tiñe el enemigo.
- Al cambiar de objetivo el tiempo vuelve a 0. Si solo se pierde la alineación, el haz se corta pero el tiempo acumulado se conserva.
- Si el haz mata al enemigo deja la animación `death_frames`.

### Effect

`scripts/Effect.gd`: `Effect.spawn(parent, frames, pos, size)` crea un `AnimatedSprite2D` que reproduce una animación una vez y se libera. Lo usan todos los ataques para impactos y fogonazos.

Límite: `Effect` y `HealEffect` se apuntan al grupo `effects`; `Effect.has_room(tree)` comprueba que haya menos de `MAX_EFFECTS` (60) vivos, o `MAX_EFFECTS_LOW` (20) si el juego va por debajo de `LOW_FPS` (45 FPS): se ajusta solo, sin opción en el menú. Si no hay hueco, el efecto no se crea. `EmpSparks` (uno por torre, no ráfagas) no cuenta.

## Comunicación con el resto

- `BuildManager` lee y gasta dinero en `LevelState` y consulta `Grid`.
- Las torres llaman a `Enemy.take_damage`, `Enemy.slow`, `Enemy.flash` y `Enemy.effect_scale`.
- Balas, haces y cadenas se añaden como hijos del padre de la torre (`BuildManager`).

## Dudas

- Una torre colocada solo se puede mejorar (fusión) o vender; no hay más mejoras.
- `disintegrator.tres` tiene `attack_cooldown = 1.0`, que el código no usa para esa torre.
- El nombre de archivo `rocket_launcher` corresponde a la torre que se llama "Cañón pesado", y `turret` a "Cañón doble". La carpeta es `turret_data` y la clase `TowerData`.

## Animaciones de construir, fusionar y vender

`Tower.play_build(fused)` (se llama tras añadirla al árbol): escala 0 a 1 en 0,35 s con rebote (`TRANS_BACK`) y destello de `sprite` y `cannon`; al fusionar el destello es más fuerte (`FUSE_FLASH`). `Tower.play_sell()` (la llama `LevelState.sell_selected_tower` antes del `queue_free`) deja una copia visual de la torre que se encoge en 0,25 s con chispas (`CPUParticles2D`) y se libera sola; la casilla queda libre al instante.

## Bajas y daño por torre

`Tower.kills` y `Tower.damage_dealt` cuentan lo que ha hecho cada torre. Todos sus ataques (`Bullet.source`, `Beam`, `Chain`, `Pulse`, `FocusBeam`) llaman a `Enemy.take_damage(amount, source)`, que avisa con `Tower.register_damage(dealt, killed)` (el daño es lo que de verdad quitó, sin pasarse de la vida que quedaba). Los poderes no pasan torre y no cuentan. La fusión hereda ambos contadores. Al vender, `LevelState` guarda la mejor torre vendida (`retired_top_name`/`retired_top_kills`) para que siga contando en el resumen.
