# Icono del juego

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

Pospuesto hasta que estén cerrados los diseños de la torreta base y de la estación.

## Por qué
El juego sigue usando `icon.svg`, el icono por defecto de Godot, en la ventana, la barra de tareas y el ejecutable.

## Qué hay que hacer
- Diseñar un icono propio de Astro Artillery en pixel art, con el estilo y las paletas de `docs/design/art.md`. Que se lea bien en pequeño (barra de tareas, 16 a 32 px) y escalado en enteros a tamaños grandes.
- Antes de integrarlo, enseñar al usuario el boceto ampliado (o dos o tres opciones) y esperar su visto bueno.
- Ponerlo como icono del proyecto (`config/icon` en `project.godot`) y, para Windows, como icono nativo del ejecutable (`.ico` con varios tamaños, `config/windows_native_icon`). Si hay preset de exportación, también ahí.
- Si se genera con script (como los demás `make_*.gd`), dejar el script en `scripts/tools/`.
- Documentarlo en `docs/design/art.md`.

## Qué leer
- docs/design/art.md › reglas generales de estilo y paletas (sacarlas con Grep `^#`)
- project.godot › `config/icon`

## Archivos que toca
- assets/ (icono nuevo en PNG y `.ico`)
- project.godot
- scripts/tools/ (si se genera con script)
- docs/design/art.md

## Cómo se prueba a mano
1. Abrir el juego: la ventana y la barra de tareas deberían enseñar el icono nuevo, no el de Godot.
2. El icono debería reconocerse también en pequeño, en la barra de tareas.
