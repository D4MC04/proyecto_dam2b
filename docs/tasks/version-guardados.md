# Versión en los archivos de guardado

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Si cambia el formato de `GameState` o `Settings`, un guardado viejo puede romper el juego.

## Qué hay que hacer
- Guardar una clave `version` y migrar o ignorar valores desconocidos al cargar.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/autoloads/Settings.gd

## Cómo se prueba a mano
1. Borrar una clave del archivo de guardado a mano y abrir el juego: arranca con valores por defecto.
