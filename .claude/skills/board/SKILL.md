---
name: board
description: Lista los tickets de docs/tickets/ con su estado y archivos, y dice cuáles chocan entre sí y cuáles se pueden hacer a la vez en worktrees.
model: haiku
disable-model-invocation: true
argument-hint: "[all]"
allowed-tools: Bash, Read, Glob, Grep, Edit, AskUserQuestion
---

Lista los tickets pendientes (los tuyos, o los de todos con `all`). No modifiques ningún archivo; si el usuario acepta tickets en las casillas, sigue `.claude/skills/accept/SKILL.md`.

Argumento (puede estar vacío): $ARGUMENTS

0. De quién: por defecto, solo los tickets del usuario, los de su carpeta `docs/tickets/$AUTHOR/`. Si el argumento es `all` o pide en sus palabras ver todos ("todos", "los de todos", "de todo el equipo"...), los de todas las carpetas. Si pide los de alguien concreto ("los de Renzo"), solo esa carpeta. Si `AUTHOR` está vacía, enseña todos y explica en una línea cómo ponerla (`docs/CLAUDE-CODE.md`).
1. Lee los tickets en un solo comando (están en `docs/tickets/<creador>/`): `for f in docs/tickets/<carpeta>/*.md; do echo "=== $f"; cat "$f"; done`, con `<carpeta>` = `$AUTHOR`, el nombre pedido o `*` para todos. Para **Chocan** y el orden de tandas usa también los aceptados de otras carpetas (aunque no salgan en la tabla), porque chocar con ellos importa: léelos con `grep -l "^Estado: aceptada" docs/tickets/*/*.md` en el mismo comando.
2. Devuelve una tabla, de prioridad alta a baja: ticket (nombre del archivo sin `.md`), creador (nombre de su carpeta), estado (y a cuál espera, si tiene `Espera a:`), prioridad, modelo recomendado, esfuerzo recomendado, archivos que toca (de la sección "Archivos que toca", sin contar `docs/`).
3. Debajo, **Chocan**: cada pareja de tickets que comparte algún archivo (sin contar `docs/`), con el archivo en común. Si ninguna choca, "Ninguno choca".
4. **Orden propuesto**: reparte todos los tickets (aceptados y propuestos) en tandas. Dentro de una tanda ninguno choca con otro, así que se hacen a la vez en chats con worktree. Cada tanda empieza cuando la anterior ya está en main. Usa las menos tandas posible y adelanta los de prioridad alta. Entre dos tickets que chocan, va primero el que deja algo que el otro aprovecha (por ejemplo, el que añade un campo o una función que el otro usa) y, si no, el más pequeño. Una línea por tanda con el porqué de cada orden:
   - Tanda 1: A, B, C
   - Tanda 2: D (después de C porque los dos tocan Enemy.gd y D aprovecha...)
5. Si no hay tickets, dilo. Si solo enseñas los tuyos, termina la tabla con una línea: "Solo los tuyos; `/board all` para ver los de todos."

Termina con una línea con el comando que toca:
- Sin tickets → `/add` (ideas del usuario) o `/ideas` (que Claude proponga).
- Uno aceptado → `/work X` con el modelo y el esfuerzo que pone el ticket.
- Varios aceptados que no chocan → los arrancas tú con `.claude/skills/accept/SKILL.md` (paso 2).
- Hay tickets propuestos sin aceptar → las casillas de `.claude/skills/accept/SKILL.md`.
