---
name: accept
description: Acepta tickets de docs/tickets/ (casillas o "acepto X"): cambia su Estado a aceptada, lo sube a main y abre un chat con worktree por ticket con /work.
model: haiku
disable-model-invocation: true
argument-hint: "[nombre-1 nombre-2 ...]"
allowed-tools: Bash, Read, Glob, Grep, Edit, AskUserQuestion, mcp__ccd_session__start_session
---

Acepta tickets. Aceptar es la orden de empezar: no esperes otro visto bueno ni preguntes nada más. Tickets pedidos (puede estar vacío): $ARGUMENTS

Los tickets están en `docs/tickets/<creador>/nombre.md` (una carpeta por creador): búscalos por nombre con `docs/tickets/*/nombre.md`.

**Casillas** (si no hay nombres, o al final de `/ideas`, `/add` y `/board` cuando hay tickets en `Estado: propuesta`): AskUserQuestion en multiSelect, una opción por ticket (etiqueta: nombre; descripción: qué aporta, prioridad, modelo, esfuerzo y tanda), máximo 4 por pregunta y hasta 4 preguntas agrupadas por tanda. Si no marca ninguno, no cambies nada.

Con los tickets elegidos:
1. Cambia su línea `Estado:` a `aceptada`. A cada uno que choque con otro aceptado que aún no está en main (mismos archivos fuera de `docs/`), añade debajo de `Estado:` la línea `Espera a: nombre-del-otro` (uno solo: el que va antes según el orden de `/board`). En la carpeta principal y en `main`: `git pull --ff-only`, commit solo de eso (sin probador, mensaje "Aceptar tickets: ...") y `git push origin main`. Es el único commit que se hace en main.
2. Si tienes `start_session` (app de escritorio): enseguida, por cada ticket aceptado sin `Espera a:`, un chat con `initiation` "user_asked" (nunca "offer" ni "own_initiative": son tarjetas que paran al usuario, y "Hacerlo aquí" nunca vale), `context` "fresh", worktree, el modelo y el esfuerzo del ticket, título = nombre del ticket y `prompt` `/work nombre`. Un chat por ticket, no subagentes. Si la app no te deja lanzarlo, di en una línea "nombre ya se puede lanzar: escribe 'lanza nombre'" y no saques tarjeta. Si no tienes `start_session`: di al usuario que lance `/work nombre` en un chat nuevo por ticket.
3. Los que llevan `Espera a:` los lanza el chat del ticket al que esperan, al acabar su `/merge` (paso 8 de `.claude/skills/merge/SKILL.md`).

"lanza nombre" (orden del usuario) = el paso 2 con ese ticket, aunque lleve `Espera a:`.

Termina con una línea por ticket: lanzado en su chat, o en espera detrás de cuál.
