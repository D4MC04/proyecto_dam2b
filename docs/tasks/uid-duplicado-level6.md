# Quitar el aviso de UID duplicado de Level6

Estado: aceptada
Modelo recomendado: haiku

## Por qué
Cada vez que se abre Godot (y en cada prueba del probador) sale `UID duplicate` entre `scenes/maps/Level6.tscn` y `scenes/maps/redesign/Level6.tscn`. Puede hacer que Godot cargue el mapa equivocado y ensucia todas las pruebas.

## Qué hay que hacer
- `scenes/maps/redesign/` no está en ningún `LevelData` (docs/design/niveles.md). **Preguntar al usuario** si se borra la carpeta o se conserva.
- Si se conserva: con Godot cerrado, dar un uid nuevo a `redesign/Level6.tscn` (y a `redesign/Level5.tscn` si también choca). No tocar el uid de `scenes/maps/Level6.tscn`, que es el que usan los niveles.
- Si se borra: comprobar con grep que nada la referencia.
- Actualizar docs/design/niveles.md.

## Archivos que toca
- scenes/maps/redesign/
- docs/design/niveles.md

## Cómo se prueba a mano
1. Cerrar Godot, borrar `.godot` y abrir el proyecto.
2. En la salida del editor no aparece `UID duplicate`.
3. Jugar un nivel desde el menú: todo igual.
