---
name: hub
description: Abre el chat central (Opus con esfuerzo high, en la carpeta principal), que solo pone main al día y espera órdenes, y borra el chat actual. Desde un central lleno, hace el relevo a uno nuevo con un resumen.
model: opus
effort: high
disable-model-invocation: true
allowed-tools: mcp__ccd_session__start_session, mcp__ccd_session_mgmt__archive_session
---

Abre el chat central del proyecto y cierra este. Si no tienes la herramienta `start_session` (solo existe en la app de escritorio de Claude), para y díselo al usuario.

1. Crea el chat con `start_session`: `initiation` "user_asked", `context` "fresh", `use_worktree` false (carpeta principal, rama `main`), modelo Opus (`claude-opus-5-5`), esfuerzo high, título "Chat central", nombre `central`. En `background`, solo: "Chat central de Astro Artillery: reparte tickets en chats con worktree y deja main local al día. Las reglas están en CLAUDE.md, ya cargado." En `prompt` (corto, sin repetir CLAUDE.md, que ya se carga solo; no mandes leer `docs/CLAUDE-CODE.md`, que es la guía del usuario):
   - Eres el chat central de Astro Artillery.
   - Deja `main` local al día en un solo comando: `git fetch --prune && git pull --ff-only` (si hay cambios sin commitear que lo bloquean, avisa y no los descartes).
   - Borra el chat que te abrió (ya no sirve): `get_session` con "self" da su id en `parentSessionId`; pásalo a `delete_session` con el motivo "Chat de /hub, ya no sirve". Hazlo en este primer turno, mientras trabajas, para que no te archive con él.
   - Contesta en una línea ("main al día" o qué falló) y espera la orden del usuario (`/board`, `/add`, `/ideas`...). No lances ninguna skill por tu cuenta.
   - No implementes tickets aquí: cada uno va en su propio chat (`.claude/skills/accept/SKILL.md`).
   - Cuando pases de ~60k de contexto, avisa en una línea de que toca `/hub` (relevo a un central nuevo).
   - Cuando un chat de ticket te avise de que subió (la limpieza del chat central): `git fetch --prune && git pull --ff-only`, archiva ese chat, `git worktree remove <carpeta>` (sin `--force`; si Godot está abierto ahí, pide al usuario que lo cierre), `git branch -D <rama>` (solo si `gh pr view <rama> --json state` da `MERGED`; si no, `-d`) y `git worktree prune`. Al final solo queda `main`. Después lanza los tickets que esperaban a ese (paso 2 de `.claude/skills/accept/SKILL.md`).
   - Relevo: si este chat ya es el central (se llama "Chat central"), añade al final del `prompt` un resumen de 10 líneas como mucho: tickets en marcha (nombre y chat), los que esperan y detrás de cuál. Nada más del historial.
2. Solo si el paso 1 devolvió que la sesión ha empezado, archiva este chat con `archive_session` y `session_id` "self", con el motivo "Pasa al chat central" (un chat no puede borrarse a sí mismo ni borrarse si está abierto en pantalla; el chat central lo borra después). Si falló, no lo archives: dile al usuario qué falló.
   Comprueba con `get_session` que el chat nuevo salió en Opus y esfuerzo high: la herramienta ignora en silencio un modelo o un esfuerzo superiores a los de este chat. Si no salió así, díselo al usuario y no archives este chat.
3. No hagas nada más en este chat.
