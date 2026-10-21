# Avisos de tipado como error

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El código debe ir siempre tipado (CLAUDE.md), pero nada lo obliga.

## Qué hay que hacer
- Activar en project.godot `untyped_declaration` e `inferred_declaration` como aviso o error.
- Arreglar las declaraciones sin tipo que salgan.

## Archivos que toca
- project.godot
- scripts/**/*.gd

## Cómo se prueba a mano
1. Abrir el proyecto: no hay avisos de tipado y el juego funciona igual.
