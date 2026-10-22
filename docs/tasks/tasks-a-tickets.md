# Renombrar docs/tasks a docs/tickets

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
En los comandos y en la guía se habla de "tickets", pero la carpeta se llama `tasks`.

## Qué hay que hacer
- **Hacerlo cuando no haya otro ticket en curso.** Una rama abierta todavía busca y borra su ticket en `docs/tasks/`.
- `git mv docs/tasks docs/tickets` (incluida `_plantilla.md`).
- Cambiar todas las rutas `docs/tasks` por `docs/tickets`:
  - CLAUDE.md (apartados "Documentación" y "Flujo de tickets"; "Tareas en `docs/tasks/nombre.md`" pasa a "Tickets en `docs/tickets/nombre.md`").
  - docs/CLAUDE-CODE.md.
  - Los comandos de `.claude/skills/`: `add`, `board` (incluido el bucle `for f in docs/tasks/*.md` y la comparación con `_plantilla.md`), `ideas` y `work`. Repasar también el resto de skills (`check`, `commit`, `ship`, `hub` y los alias) por si construyen la ruta.
  - Los tickets que citen `docs/tasks/`.
- Comprobar con `git grep -n "docs/tasks\|tasks/"` (y en `.claude/`) que no queda ninguna referencia.

## Archivos que toca
- docs/tasks/ → docs/tickets/
- CLAUDE.md
- docs/CLAUDE-CODE.md
- .claude/skills/*/SKILL.md

## Cómo se prueba a mano
1. `/board`: lista los tickets de `docs/tickets/` con su estado.
2. `/add` con una idea de prueba: el ticket se crea en `docs/tickets/`. Borrarlo después.
