# Pasar theme.mp3 a OGG

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`theme.mp3` (5 MB) es el único MP3; en OGG pesa menos y hace bucle sin huecos.

## Qué hay que hacer
- Convertir a OGG y activar loop en el import.
- Cambiar la referencia (grep `theme.mp3`).
- Borrar el MP3 y su .import.

## Archivos que toca
- assets/audio/music/theme.*
- scripts/autoloads/MusicManager.gd o la escena que lo cargue

## Cómo se prueba a mano
1. Abrir el menú: suena el tema y vuelve a empezar sin corte al acabar.
