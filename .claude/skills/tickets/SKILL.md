---
name: tickets
description: Lista los tickets de docs/tasks/ con su estado y archivos, y dice cuáles chocan entre sí y cuáles se pueden hacer a la vez en worktrees.
model: haiku
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Edit, AskUserQuestion
---

Lista los tickets pendientes. No modifiques ningún archivo, salvo la línea `Estado:` de los tickets que el usuario acepte en las casillas (y luego súbela y arráncalos, ver abajo).

1. Lee todos los tickets en un solo comando: `for f in docs/tasks/*.md; do [ "$f" = docs/tasks/_plantilla.md ] || { echo "=== $f"; cat "$f"; }; done`.
2. Devuelve una tabla: ticket (nombre del archivo sin `.md`), estado, modelo recomendado, esfuerzo recomendado, archivos que toca (de la sección "Archivos que toca", sin contar `docs/`).
3. Debajo, **Chocan**: cada pareja de tickets que comparte algún archivo (sin contar `docs/`), con el archivo en común. Si ninguna choca, "Ninguno choca".
4. **Orden propuesto**: reparte todos los tickets (aceptados y propuestos) en tandas. Dentro de una tanda ninguno choca con otro, así que se hacen a la vez en chats con worktree. Cada tanda empieza cuando la anterior ya está en main. Usa las menos tandas posible. Entre dos tickets que chocan, va primero el que deja algo que el otro aprovecha (por ejemplo, el que añade un campo o una función que el otro usa) y, si no, el más pequeño. Una línea por tanda con el porqué de cada orden:
   - Tanda 1: A, B, C
   - Tanda 2: D (después de C porque los dos tocan Enemy.gd y D aprovecha...)
5. Si no hay tickets, dilo.

Termina con una línea con el comando que toca:
- Sin tickets aceptados → aceptar alguno ("acepto X") o `/proponer`.
- Uno aceptado → `/hacer X` con el modelo y el esfuerzo que pone el ticket.
- Varios aceptados que no chocan → los arrancas tú como dice "Aceptar es la orden de empezar" en CLAUDE.md.
- Hay tanda propuesta sin aceptar → las casillas de abajo.

## Aceptar con casillas
Si hay tickets en `Estado: propuesta`, termina con la herramienta AskUserQuestion en modo multiSelect para que el usuario los marque con un clic:
- Una opción por ticket propuesto. Etiqueta: el nombre del ticket. Descripción: qué aporta en una frase, el modelo, el esfuerzo y su tanda.
- Máximo 4 opciones por pregunta: si hay más tickets, usa varias preguntas (hasta 4) agrupadas por tanda.
- Los que marque pasan a `Estado: aceptada` (solo cambias esa línea). Los no marcados se quedan como están.
- Si no marca ninguno, no cambies nada.
- Si marca alguno, no preguntes más: sigue "Aceptar es la orden de empezar" de CLAUDE.md (subir el `Estado:` a main y abrir ya los chats con worktree).
