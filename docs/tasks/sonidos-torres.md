# Sonido de disparo de las torres

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Hay sonidos de disparo de las 7 torres en `assets/audio/effects/Turrets/`, pero ningún script los reproduce y el deslizador "Efectos" de Opciones no cambia nada audible (docs/design/menu.md, "Dudas").

## Qué hay que hacer
- `TowerData`: añadir `@export var shoot_sound: AudioStream` (y `charge_sound` si hace falta para las que cargan: Rail, Cryo, Tesla, Disintegrator).
- Rellenarlo en los 7 `.tres` de `resources/turret_data/` y en las 7 fusionadas (`*_fusion.tres`, que usan el mismo sonido que su base) con su archivo de `Turrets/<torre>/` (Turret → `DobleLaserShoot.wav`, Rocket → `RocketShoot.wav`, Laser → `LaserShoot.wav`, Rail → `RailgunShoot.wav`, Cryo → `IceShoot.wav`, Tesla → `ElectricZap.wav`, Disintegrator → `IncrementalRay.wav`).
- `Tower`: un `AudioStreamPlayer2D` en el bus `SFX` que suena cada vez que la torre dispara (en el mismo sitio donde arranca la animación `fire_*`). Limitar la polifonía para que 10 torres disparando no saturen.
- Si el Disintegrator dispara en continuo, que el sonido suene mientras el rayo está activo y pare al soltarlo, no que se reinicie cada frame.
- Actualizar docs/design/torres.md y quitar la duda del deslizador en menu.md.

## Archivos que toca
- scripts/resources/TowerData.gd
- scripts/entities/Tower.gd (y FocusBeam.gd si el Disintegrator lo necesita)
- scenes/entities/ (escena de la torre)
- resources/turret_data/*.tres
- docs/design/torres.md, docs/design/menu.md

## Cómo se prueba a mano
1. F5 y entrar al nivel 1.
2. Colocar una torre de cada tipo disponible y lanzar una oleada: cada una suena distinto al disparar.
3. Pausa → Opciones (o menú principal → Opciones) → bajar "Efectos" a 0: los disparos dejan de oírse; la música sigue.
