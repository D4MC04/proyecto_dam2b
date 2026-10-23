---
name: board
description: Lista los tickets de docs/tickets/ con su estado y archivos, y dice cuáles chocan entre sí y cuáles se pueden hacer a la vez en worktrees.
model: haiku
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Edit, AskUserQuestion
---

Lista los tickets pendientes. No modifiques ningún archivo, salvo la línea `Estado:` de los tickets que el usuario acepte en las casillas (y luego súbela y arráncalos, ver "Aceptar" en CLAUDE.md).

1. Lee todos los tickets en un solo comando: `for f in docs/tickets/*.md; do [ "$f" = docs/tickets/_plantilla.md ] || { echo "=== $f"; cat "$f"; }; done`.
2. Devuelve una tabla: ticket (nombre del archivo sin `.md`), estado, modelo recomendado, esfuerzo recomendado, archivos que toca (de la sección "Archivos que toca", sin contar `docs/`).
3. Debajo, **Chocan**: cada pareja de tickets que comparte algún archivo (sin contar `docs/`), con el archivo en común. Si ninguna choca, "Ninguno choca".
4. **Orden propuesto**: reparte todos los tickets (aceptados y propuestos) en tandas. Dentro de una tanda ninguno choca con otro, así que se hacen a la vez en chats con worktree. Cada tanda empieza cuando la anterior ya está en main. Usa las menos tandas posible. Entre dos tickets que chocan, va primero el que deja algo que el otro aprovecha (por ejemplo, el que añade un campo o una función que el otro usa) y, si no, el más pequeño. Una línea por tanda con el porqué de cada orden:
   - Tanda 1: A, B, C
   - Tanda 2: D (después de C porque los dos tocan Enemy.gd y D aprovecha...)
5. Si no hay tickets, dilo.

Termina con una línea con el comando que toca:
- Sin tickets → `/add` (ideas del usuario) o `/ideas` (que Claude proponga).
- Uno aceptado → `/work X` con el modelo y el esfuerzo que pone el ticket.
- Varios aceptados que no chocan → los arrancas tú como dice "Aceptar" en CLAUDE.md.
- Hay tickets propuestos sin aceptar → las casillas para aceptar (ver "Casillas para aceptar" en CLAUDE.md).
