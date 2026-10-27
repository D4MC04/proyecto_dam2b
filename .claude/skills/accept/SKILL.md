---
name: accept
description: Acepta tickets de docs/tickets/ (casillas o "acepto X"): cambia su Estado a aceptada, lo sube a main y abre un chat con worktree por ticket con /work.
model: haiku
disable-model-invocation: true
argument-hint: "[nombre-1 nombre-2 ...]"
allowed-tools: Bash, Read, Glob, Grep, Edit, AskUserQuestion, mcp__ccd_session__start_session
---

Acepta tickets. Aceptar es la orden de empezar: no esperes otro visto bueno. Tickets pedidos (puede estar vacío): $ARGUMENTS

**Casillas** (si no hay nombres, o al final de `/ideas`, `/add` y `/board` cuando hay tickets en `Estado: propuesta`): AskUserQuestion en multiSelect, una opción por ticket (etiqueta: nombre; descripción: qué aporta, prioridad, modelo, esfuerzo y tanda), máximo 4 por pregunta y hasta 4 preguntas agrupadas por tanda. Si no marca ninguno, no cambies nada.

Con los tickets elegidos:
1. Cambia solo su línea `Estado:` a `aceptada`. En la carpeta principal y en `main`: `git pull --ff-only`, commit solo de eso (sin probador, mensaje "Aceptar tickets: ...") y `git push origin main`. Es el único commit que se hace en main.
2. Si tienes `start_session` (app de escritorio): enseguida, por cada ticket aceptado de la primera tanda que no choque con otro (mismos archivos fuera de `docs/`), un chat con `initiation` "user_asked", `context` "fresh", worktree, el modelo y el esfuerzo del ticket, título = nombre del ticket y `prompt` `/work nombre`. Un chat por ticket, no subagentes. Si no la tienes: di al usuario que lance `/work nombre` en un chat nuevo por ticket.
3. Los que chocan esperan a que el anterior esté en main; el chat central los lanza al recibir el aviso de subida.

Termina con una línea por ticket: lanzado en su chat, o en espera detrás de cuál.
