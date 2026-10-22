# Torres: cortar el disparo sin objetivo y sonido de carga del Rail y la Tesla

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
`Tower.gd` nunca para `_shoot_player` (solo el haz del Disintegrator lo corta, en `FocusBeam.gd`). Por eso los disparos largos (`DobleLaserShoot` y `RailgunShoot` duran 1,7 s, `IceShoot` 1,4 s y `RocketShoot` 1,1 s) siguen sonando cuando ya no queda objetivo. Además, la carga del Rail y de la Tesla va en silencio aunque `RailgunCharging.wav` y `CharginTower.wav` ya están en assets.

## Qué hay que hacer
- **Cortar el disparo:** cuando la torre se queda sin objetivo (`_on_attack_timeout` sin `target`, o el objetivo muere o sale del rango), parar `_shoot_player` con un fundido corto (0,1-0,15 s, `Tween` sobre `volume_db` y luego `stop()`). También al apagarla un EMP (`disable`). Si en ese momento hay un disparo nuevo, no se corta, y el disparo siguiente devuelve `volume_db` a su valor normal. No cambia nada mientras siga teniendo objetivo.
- **Carga:**
  - `TowerData`: `@export var charge_sound: AudioStream` (opcional; sin él no cambia nada).
  - `Tower`: un segundo `AudioStreamPlayer2D` (bus `SFX`) que suena al empezar `fire_0` (en `_shoot` del haz y en `_on_attack_timeout` de las estáticas) y se para en el `fire_frame`, cuando suena el disparo. También se para si la carga se corta (EMP o sin objetivo).
  - Asignarlo en `rail.tres` y `rail_fusion.tres` (`RailgunCharging.wav`) y en `tesla.tres` y `tesla_fusion.tres` (`CharginTower.wav`). La Cryo no lleva, porque `IceCharging.wav` dura 9,6 s.
  - El Rail dispara en el frame 8 y `RailgunCharging` dura 4,1 s. Medir cuánto dura la carga (frames hasta `fire_frame` / fps de `fire_0`). Si el corte suena mal, sacar con ffmpeg un trozo de esa duración con fundido, en un archivo nuevo junto al original.
- Actualizar el apartado "Sonido" de docs/design/torres.md: cuándo se corta el disparo y el sonido de carga (y quitar la línea "No se usan aún...").

## Archivos que toca
- scripts/entities/Tower.gd
- scripts/resources/TowerData.gd
- resources/turret_data/rail.tres, rail_fusion.tres, tesla.tres, tesla_fusion.tres
- assets/audio/effects/Turrets/Rail/ (solo si hay que recortar)
- docs/design/torres.md

## Cómo se prueba a mano
1. F5, nivel 1 con dinero; colocar una Torreta junto al camino y dejar pasar una sola nave: al matarla, el disparo se apaga enseguida y no se queda sonando.
2. Con varias naves seguidas, los disparos suenan como antes, sin cortes.
3. Colocar un Rail y una Tesla: suena la carga y se corta justo cuando sale el haz o el rayo con su disparo.
4. El resto de torres suenan como antes.
