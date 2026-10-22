# Audio largo a OGG y bucles en el import

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los audios largos están en WAV o MP3 y pesan mucho (los dos ambientes suman 16 MB), y ninguno de los que deben repetirse tiene el bucle activado en el import.

## Qué hay que hacer
- Convertir a OGG Vorbis (calidad ~0.5, con ffmpeg) estos audios:
  - Ambientes: `LevelAmbience/DarkestVoid.wav` (93 s) y `EchoOfTheVoid.wav` (41 s).
  - Naves largas: `SpaceShips/Nodriza/NodrizaShip.wav` (22 s), `Dart/DartShip.wav` (20 s), `UFO/UfoShip.wav` (8,9 s), `Battleship/Battleship.wav` (8,1 s), `NormalShip/NormalShip.wav` (6,5 s) y `Wasp/WaspShip.wav` (5,6 s).
  - `SFXs/GameOver.wav` (9 s) y `SFXs/Victory.wav` (7,8 s).
  - `music/theme.mp3`.
- Bucle activado en el import (`loop=true`) solo en `theme` y en los dos ambientes. Las naves no se tocan: si van en bucle lo decide `audio-naves`.
- `MusicManager.gd`: cambiar `MUSIC_PATH` a `theme.ogg` y el tipo `AudioStreamMP3` por `AudioStreamOggVorbis`. Quitar `track.loop = true` si el import ya lo trae.
- Grep de cada nombre en .gd, .tscn y .tres y actualizar las referencias (ahora solo usa estos archivos `MusicManager`).
- Borrar los originales y sus `.import`.
- En docs/design/menu.md (apartado Música), anotar que los audios largos o en bucle van en OGG y los efectos cortos en WAV.

## Archivos que toca
- assets/audio/effects/LevelAmbience/*, SpaceShips/*, SFXs/GameOver.*, SFXs/Victory.*
- assets/audio/music/theme.*
- scripts/autoloads/MusicManager.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir el proyecto: no hay errores de recurso perdido.
2. F5: en el menú suena el tema y, al acabar, vuelve a empezar sin corte.
