# Contador de FPS opcional

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Para comprobar las mejoras de rendimiento hace falta ver los FPS sin abrir el editor.

## Qué hay que hacer
- Añadir en Opciones 'Mostrar FPS' (Settings).
- Label pequeño en una esquina que enseña `Engine.get_frames_per_second()`.

## Archivos que toca
- scripts/autoloads/Settings.gd
- scripts/screens/OptionsMenu.gd
- scenes/OptionsMenu.tscn
- scenes/Game.tscn

## Cómo se prueba a mano
1. Activar la opción y jugar: se ven los FPS en una esquina; al desactivarla desaparecen.
