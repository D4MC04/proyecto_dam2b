# Sonido de las naves enemigas

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: high

Nota: se probó el motor en bucle (5 naves a la vez, -3 dB al duplicarse, mínimo -9 dB) y sonaba mal; se canceló. Si se retoma, probar otros valores o decidir qué audios se usan.

## Por qué
Hay 9 audios en `assets/audio/effects/SpaceShips/` y ninguna nave los usa (`EnemyData.death_sound` existe, pero ningún `.tres` lo tiene asignado). Varios duran demasiado para ser una muerte (`NodrizaShip` 22 s, `DartShip` 20 s), así que primero hay que decidir qué son.

## Qué hay que hacer
- **Antes de implementar, preguntar al usuario** qué es cada audio después de escucharlo: motor en bucle mientras la nave vuela, sonido al morir u otra cosa. Puede ser distinto en cada nave.
- Las naves y sus audios:
  - `nave_agresiva` → `AggressiveShip`
  - `ariete` → `BatteringRamShip`
  - `acorazado` → `Battleship`
  - los 4 `dart_*` → `DartShip`
  - `nodriza` → `NodrizaShip`
  - `nave_normal` → `NormalShip`
  - `spiked_ship` → `SpikedUFO`
  - `ufo` → `UfoShip`
  - `wasp` → `WaspShip`
  - Espectro, Divisora (y sus fragmentos), Reparadora y Saboteadora no tienen audio y siguen sin sonido.
- Si son de muerte: asignar `death_sound` en los `.tres` (el código de `Enemy._play_death_sound` ya existe).
- Si son de motor: `@export var engine_sound: AudioStream` en `EnemyData` y un `AudioStreamPlayer2D` en bucle en `Enemy` (bus `SFX`) que se para al morir o al llegar a la estación. Activar el bucle en su import.
- En ambos casos, evitar el ruido cuando hay muchas naves, en un solo sitio: limitar las que suenan a la vez (unas 4-6) y bajar el volumen según cuántas haya (por ejemplo -3 dB cada vez que se duplican, con un mínimo). Ajustar de oído.
- Actualizar docs/design/enemigos.md (apartado Daño y muerte y la línea "Los .wav ... se quedan en assets/ sin usar").

## Archivos que toca
- scripts/entities/Enemy.gd
- scripts/resources/EnemyData.gd (si son de motor)
- resources/enemy_data/*.tres de las naves de la lista
- assets/audio/effects/SpaceShips/*.import (si van en bucle)
- docs/design/enemigos.md

## Cómo se prueba a mano
1. F5, un nivel con varios tipos de nave (por ejemplo el 5): cada nave de la lista suena según lo decidido.
2. En una oleada grande el conjunto no es un ruido molesto y el volumen no sube cuantas más naves hay; con una sola nave se oye con normalidad.
3. Al ganar, perder o salir del nivel no se queda sonando ninguna nave.
4. "Efectos" a 0 las silencia.
