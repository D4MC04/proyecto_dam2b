# Sonido al destruir enemigos

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
Cada nave tiene su sonido en `assets/audio/effects/SpaceShips/` (9 carpetas) y no se usa. Oír la explosión al matar da respuesta inmediata a lo que hacen las torres.

## Qué hay que hacer
- Escuchar un par de archivos para confirmar que son de explosión/muerte. Si son de motor, parar y avisar al usuario.
- `EnemyData`: añadir `@export var death_sound: AudioStream` y rellenarlo en los 12 `.tres` de `resources/enemy_data/` (los 4 `dart_*` comparten `DartShip.wav`; `acorazado` → `Battleship`, `ariete` → `BatteringRam`, `nodriza` → `Nodriza`, `nave_agresiva` → `AggressiveShip`, `nave_normal` → `NormalShip`, `spiked_ship` → `SpikedUFO`, `ufo` → `UFO`, `wasp` → `Wasp`).
- Al morir (donde se emite `died`, `Enemy.gd`), reproducir el sonido en el bus `SFX`. Como el enemigo hace `queue_free()` justo después, el reproductor no puede ser hijo del enemigo: crearlo en el padre (o en `Level`) y que se libere al acabar (`finished`).
- No suena cuando el enemigo llega a la estación, solo cuando lo matan.
- Actualizar docs/design/enemigos.md.

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/*.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. F5, nivel 1, poner un par de torres y lanzar una oleada.
2. Cada enemigo que muere suena; los que llegan a la estación no.
3. Con "Efectos" a 0 en Opciones no se oye nada.
