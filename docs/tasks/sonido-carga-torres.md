# Sonido de carga del Rail y la Tesla

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El Rail y la Tesla cargan antes de disparar (la animación `fire_0` hasta su `fire_frame`), pero la carga va en silencio. `RailgunCharging.wav` y `CharginTower.wav` están en `assets/` y nadie los usa.

## Qué hay que hacer
- Añadir `@export var charge_sound: AudioStream` a `TowerData` (opcional; sin él no cambia nada).
- En `Tower`, un segundo `AudioStreamPlayer2D` (bus `SFX`) que suena al empezar `fire_0` (en `_shoot` del haz y en `_on_attack_timeout` de las estáticas) y se corta (`stop()`) en el `fire_frame`, justo cuando suena el disparo.
- `RailgunCharging.wav` dura 4,1 s y la carga del Rail mucho menos: medir cuánto dura la carga (frames hasta `fire_frame` / fps de `fire_0`) y, si el corte a mitad suena mal, sacar con ffmpeg un trozo de esa duración con fundido (archivo nuevo, sin tocar el original).
- Ponerlo en `rail.tres`, `rail_fusion.tres` (`RailgunCharging`), `tesla.tres` y `tesla_fusion.tres` (`CharginTower`). Cryo no: `IceCharging.wav` dura 9,6 s.
- Actualizar el apartado "Sonido" de docs/design/torres.md (y quitar los sonidos usados de "No se usan aún").

## Archivos que toca
- scripts/resources/TowerData.gd
- scripts/entities/Tower.gd
- resources/turret_data/rail.tres, rail_fusion.tres, tesla.tres, tesla_fusion.tres
- assets/audio/effects/Turrets/Rail/ (solo si hace falta recortar)
- docs/design/torres.md

## Cómo se prueba a mano
1. F5, un nivel con dinero suficiente; colocar un Rail y una Tesla junto al camino.
2. Al acercarse un enemigo, el Rail suena mientras carga la mira y el sonido de carga se corta justo cuando sale el haz con su disparo.
3. La Tesla suena igual antes de cada rayo.
4. Las demás torres suenan como antes.
