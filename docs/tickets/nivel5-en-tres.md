# Nivel 5 en su level_5.tres

Creador: Renzo
Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
El nivel 5 está duplicado: subrecurso en `GameData.tscn` y `level_5.tres`, que no se usa (Dudas de niveles.md).

## Qué hay que hacer
- Que `GameData.tscn` use `level_5.tres` como los demás y borrar el subrecurso (sin cambiar uids existentes).
- Quitar el caso especial de `make_waves.gd` (`SCENE_LEVEL`).

## Archivos que toca
- scenes/GameData.tscn
- scripts/tools/make_waves.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 5: mismas oleadas que antes.
