---
name: new
description: Abre el chat central (Opus, en la carpeta principal), que solo pone main al día y espera órdenes, y borra el chat actual.
model: haiku
disable-model-invocation: true
allowed-tools: mcp__ccd_session__start_session, mcp__ccd_session_mgmt__archive_session
---

Abre el chat central del proyecto y cierra este.

1. Crea el chat con `start_session`: `initiation` "user_asked", `context` "fresh", `use_worktree` false (carpeta principal, rama `main`), modelo Opus, título "Chat central", nombre `central`. En `background`, solo: "Chat central de Astro Artillery: reparte tickets en chats con worktree y deja main local al día. Las reglas están en CLAUDE.md, ya cargado." En `prompt` (corto, sin repetir CLAUDE.md, que ya se carga solo; no mandes leer `docs/CLAUDE-CODE.md`, que es la guía del usuario):
   - Eres el chat central de Astro Artillery.
   - Deja `main` local al día en un solo comando: `git fetch --prune && git pull --ff-only` (si hay cambios sin commitear que lo bloquean, avisa y no los descartes).
   - Borra el chat que te abrió (ya no sirve): `get_session` con "self" da su id en `parentSessionId`; pásalo a `delete_session` con el motivo "Chat de /new, ya no sirve". Hazlo en este primer turno, mientras trabajas, para que no te archive con él.
   - Contesta en una línea ("main al día" o qué falló) y espera la orden del usuario (`/tickets`, `/proponer`...). No lances ninguna skill por tu cuenta.
   - Cuando un chat de ticket suba a main, revisa que todo cargue (`probador`) y repite la actualización de `main` local, para que el usuario nunca tenga que hacer `git pull` a mano.
2. Solo si el paso 1 devolvió que la sesión ha empezado, archiva este chat con `archive_session` y `session_id` "self", con el motivo "Pasa al chat central" (un chat no puede borrarse a sí mismo ni borrarse si está abierto en pantalla; el chat central lo borra después). Si falló, no lo archives: dile al usuario qué falló.
3. No hagas nada más en este chat.
