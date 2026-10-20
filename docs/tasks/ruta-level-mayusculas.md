# Arreglar la ruta de Level.tscn (mayúsculas)

Estado: aceptada
Modelo recomendado: haiku

## Por qué
En git el archivo se llama `scenes/level.tscn` (minúscula), pero `Game.tscn` lo carga como `res://scenes/Level.tscn`. En Windows funciona; en Linux, Mac o en una exportación que distinga mayúsculas, el juego no encuentra el nivel (docs/design/flujo.md, "Dudas").

## Qué hay que hacer
- Con Godot cerrado, renombrar en git a `scenes/Level.tscn` con `git mv -f scenes/level.tscn scenes/Level.tscn` (en Windows hace falta `-f` para cambiar solo mayúsculas).
- Comprobar con grep que ninguna escena ni script referencia `level.tscn` en minúscula. No cambiar ningún `uid=`.
- Quitar la duda de docs/design/flujo.md.

## Archivos que toca
- scenes/level.tscn → scenes/Level.tscn
- docs/design/flujo.md

## Cómo se prueba a mano
1. Borrar `.godot` y abrir el proyecto en Godot.
2. En el sistema de archivos del editor sale `scenes/Level.tscn`.
3. Desde `scenes/MainMenu.tscn`, entrar al nivel 1: carga igual que antes.
