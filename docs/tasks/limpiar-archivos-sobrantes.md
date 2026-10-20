# Limpiar archivos .tmp y el UID duplicado de Level6

Estado: propuesta
Modelo recomendado: haiku

## Por qué
En git hay 7 archivos `.tmp` que dejó el editor en `scenes/`, y Godot avisa en cada arranque de `UID duplicate` entre `scenes/maps/Level6.tscn` y `scenes/maps/redesign/Level6.tscn`. Ensucian el repo y los avisos del probador.

## Qué hay que hacer
- Borrar de git los `scenes/*.tmp` (`Game.tscn971528365.tmp`, `Level.tscn*.tmp`, `MainMenu.tscn4881157710.tmp`).
- Añadir `*.tmp` al `.gitignore`.
- `scenes/maps/redesign/` no está en ningún `LevelData` (ver docs/design/niveles.md). Preguntar al usuario si se borra la carpeta; si no, dar un uid nuevo a `redesign/Level6.tscn` (y a `redesign/Level5.tscn` si también choca), con Godot cerrado.
- Actualizar docs/design/niveles.md si cambia `redesign/`.

## Archivos que toca
- scenes/*.tmp
- .gitignore
- scenes/maps/redesign/
- docs/design/niveles.md

## Cómo se prueba a mano
1. Borrar `.godot` y abrir el proyecto en Godot.
2. En la salida del editor no debería aparecer `UID duplicate`.
3. Jugar el nivel 1 desde el menú: todo igual que antes.
