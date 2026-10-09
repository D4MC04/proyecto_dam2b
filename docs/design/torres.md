# Torres y ataques

## Colocación: BuildManager

`scripts/level/BuildManager.gd` (clase `BuildManager`), nodo hijo de `Level`. Exporta `grid: Grid` y `tower_scene` (`scenes/entities/Tower.tscn`). `Level` le asigna `state: LevelState`.

En `_unhandled_input`:

- **Mover el ratón**: si hay torre seleccionada y la casilla bajo el cursor es construible, muestra una vista previa en el centro de la casilla: el icono de la torre al 60 % de opacidad y su rango dibujado en blanco al 15 %. Si no, la oculta.
- **Clic izquierdo**: si hay torre seleccionada, `grid.can_build(cell)` y `state.spend_money(data.cost)`, instancia la torre como hija de `BuildManager`, la coloca en el centro de la casilla y la registra en `Grid`.
- **Clic derecho**: pone `state.selected_tower = null` y oculta la vista previa.

Tras colocar una torre la selección se mantiene, así que se pueden colocar varias seguidas.

## Escena y script

`scenes/entities/Tower.tscn` + `scripts/entities/Tower.gd` (clase `Tower`).

- `AnimatedSprite2D`: base fija.
- `Cannon` (`AnimatedSprite2D`): cañón, dibujado mirando hacia arriba.
- `RangeDetector/CollisionShape2D` (`Area2D`): rango de ataque.
- `Timer`: cooldown.

En `_ready` copia de `data: TowerData` los sprites, la forma del rango y `attack_cooldown`, y arranca el temporizador.

### Objetivo

- `enemies_in_range` se mantiene con las señales `area_entered` y `area_exited` del detector.
- `_get_target()` conserva el objetivo mientras siga vivo y dentro del rango. Si no, elige el enemigo con mayor `progress`.

### Apuntado

Cada frame el cañón gira hacia el objetivo a `turn_speed` grados/s (0 = al instante). Sin objetivo se queda donde está. Se considera alineado dentro de 12° (`AIM_TOLERANCE`).

### Disparo

Al cumplirse el cooldown:

- Sin objetivo: no hace nada.
- Si el cañón está alineado: dispara.
- Si no lo está: para el temporizador y dispara en cuanto se alinee (`_pending_shot`), y entonces lo reinicia.

Las torres de onda y de cadena no giran el cañón ni usan `_process`.

## Datos

`TowerData` (`scripts/resources/TowerData.gd`): `name`, `cost`, `attack_cooldown`, `icon`, `sprite_frames`, `attack_range`, `muzzle_flash`, `muzzle_offset`, `cannon`, `turn_speed`, y uno de estos campos, que decide el tipo de ataque: `bullet_data`, `pulse`, `chain`, `beam`, `focus_beam`.

Recursos en `resources/turret_data/`:

| Archivo | Nombre | Coste | Cooldown (s) | Rango (px) | Giro (°/s) | Ataque |
|---|---|---|---|---|---|---|
| `turret` | Cañón doble | 100 | 0,25 | 56 | 240 | Bala: 5 de daño, 300 px/s |
| `laser` | Láser | 200 | 0,5 | 112 | 180 | Bala: 15 de daño, 250 px/s, con estela |
| `cryo` | Cryo | 250 | 2,0 | 64 | no gira | Onda: 5 de daño, velocidad al 55 % durante 3,5 s |
| `rocket_launcher` | Cañón pesado | 300 | 1,5 | 88 | 180 | Bala: 45 de daño, 200 px/s |
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

## Comunicación con el resto

- `BuildManager` lee y gasta dinero en `LevelState` y consulta `Grid`.
- Las torres llaman a `Enemy.take_damage`, `Enemy.slow`, `Enemy.flash` y `Enemy.effect_scale`.
- Balas, haces y cadenas se añaden como hijos del padre de la torre (`BuildManager`).

## Dudas

- `Tower.fit_to_tile` no se llama desde ningún sitio.
- No hay forma de vender, quitar ni mejorar una torre colocada.
- `TowerData.name` no se muestra en la interfaz.
- `disintegrator.tres` tiene `attack_cooldown = 1.0`, que el código no usa para esa torre.
- El objetivo se elige por `progress`, que es la distancia recorrida en su propio camino; en mapas con varios caminos de distinta longitud no equivale a "el más cerca del final".
- El nombre de archivo `rocket_launcher` corresponde a la torre que se llama "Cañón pesado", y `turret` a "Cañón doble". La carpeta es `turret_data` y la clase `TowerData`.
