# Unificar nombres de sprites

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Nombres mezclados (`t1_*`, `t2_*`, `disint_*`, `nave_agresiva_up.png`, `planetagaseoso`…) (Dudas de art.md).

## Qué hay que hacer
- Renombrar a `<nombre>_<frame>.png` con el nombre de su carpeta, desde el editor de Godot o actualizando .import y referencias.
- Comprobar que no queda nada roto.

## Archivos que toca
- assets/sprites/**
- resources/sprite_frames/*
- docs/design/art.md

## Cómo se prueba a mano
1. Abrir el proyecto sin errores y jugar los niveles 1 y 9: todo se ve igual.
