# Pasar los WAV largos a OGG

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los WAV de más de 1 MB (NodrizaShip 4 MB, DartShip 2,5 MB, IncrementalRay 2 MB, IceCharging 1,8 MB, GameOver 1,7 MB, Battleship 1,4 MB, Victory 1,3 MB, UfoShip 1,1 MB) ocupan mucho en el repo y en el ejecutable.

## Qué hay que hacer
- Convertir a OGG Vorbis (calidad ~0.5) los WAV de más de 1 MB con ffmpeg u otra herramienta.
- Actualizar todas las referencias en .gd, .tscn y .tres (grep del nombre).
- Conservar el bucle donde lo tenga el .import del WAV (en OGG es `loop` del import).
- Borrar los WAV viejos y sus .import.
- Anotar en docs/design/art.md (o el doc de audio) que los efectos largos van en OGG.

## Archivos que toca
- assets/audio/effects/**
- scripts/** y scenes/** que los referencien
- docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con Nodriza, Disintegrator y Cryo.
2. Los sonidos se oyen igual que antes, sin cortes ni silencio al repetir.
