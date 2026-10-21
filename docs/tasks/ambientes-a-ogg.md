# Ambientes de nivel a OGG

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`DarkestVoid.wav` y `EchoOfTheVoid.wav` pesan 16 MB entre los dos y son bucles largos que encajan mejor en OGG.

## Qué hay que hacer
- Convertir los dos a OGG con bucle activado en el import.
- Si `sonidos-generales` ya los usa, actualizar la referencia; si no, solo convertir.
- Borrar los WAV y sus .import.

## Archivos que toca
- assets/audio/effects/LevelAmbience/*

## Cómo se prueba a mano
1. Abrir el proyecto: no hay errores de recurso perdido.
2. Si el ambiente ya suena en algún nivel, suena igual y en bucle.
