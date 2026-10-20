---
name: tickets
description: Lista los tickets de docs/tasks/ con su estado y archivos, y dice cuáles chocan entre sí y cuáles se pueden hacer a la vez en worktrees.
model: haiku
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

Lista los tickets pendientes. No modifiques ningún archivo.

1. Lee todos los `docs/tasks/*.md` menos `_plantilla.md`.
2. Devuelve una tabla: ticket (nombre del archivo sin `.md`), estado, modelo recomendado, archivos que toca (de la sección "Archivos que toca", sin contar `docs/`).
3. Debajo, **Chocan**: cada pareja de tickets que comparte algún archivo (sin contar `docs/`), con el archivo en común. Si ninguna choca, "Ninguno choca".
4. **A la vez**: el grupo más grande de tickets `aceptada` que no chocan entre sí. Esos se pueden repartir en chats con worktree.
5. Si no hay tickets, dilo.

Termina con una línea con el comando que toca:
- Sin tickets aceptados → aceptar alguno ("acepto X") o `/proponer`.
- Uno aceptado → `/hacer X` en Sonnet.
- Varios aceptados que no chocan → "abre sesiones en worktree para X e Y" y `/hacer` en cada una. Antes, los tickets tienen que estar commiteados en main.
