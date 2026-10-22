# Música por nivel

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Solo suena `theme` (en el menú y en todos los niveles). Las 6 pistas `.ogg` de `assets/audio/music/` no las usa nada: `Beauty Flow`, `Limit 70`, `Mesmerizing Galaxy Loop`, `Raving Energy (faster)`, `Space_1990-B` y `Tyrant`.

## Qué hay que hacer
- **Antes de implementar, preguntar al usuario** qué pista va en cada uno de los 9 niveles (puede repetir alguna o dejar `theme`) y si sobra alguna para borrarla.
- `LevelData`: `@export var music: AudioStream` (si está vacío, sigue sonando `theme`). Asignarlo en `level_1.tres` … `level_9.tres`.
- `MusicManager`: una función `play_track(stream: AudioStream)` que cambia de pista con un fundido corto y no hace nada si ya está sonando esa. El nivel la llama al empezar y el menú principal vuelve a poner `theme`.
- Activar `loop=true` en el import de las pistas usadas. Borrar las que el usuario descarte (con su `.import`).
- Actualizar docs/design/menu.md (apartado Música) y niveles.md.

## Archivos que toca
- scripts/autoloads/MusicManager.gd
- scripts/resources/LevelData.gd
- resources/level_data/level_*.tres
- scripts/level/Level.gd y el script del menú principal
- assets/audio/music/*.import
- docs/design/menu.md, niveles.md

## Cómo se prueba a mano
1. F5: en el menú suena `theme`.
2. Entrar a cada nivel: suena su pista, con un fundido y en bucle.
3. Volver al menú: vuelve `theme`. Reintentar el mismo nivel no reinicia la pista.
