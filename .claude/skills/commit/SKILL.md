---
name: commit
description: Revisa lo que no está commiteado, lo prueba en headless y, si sale bien, lo commitea en la rama actual con un mensaje que explica el cambio. No sube nada.
disable-model-invocation: true
argument-hint: "[nota opcional para el mensaje]"
---

Guarda en un commit los cambios sin commitear de la rama actual. Nota del usuario para el mensaje (puede estar vacía): $ARGUMENTS

1. En un solo comando: `git rev-parse --abbrev-ref HEAD && git status --short && git diff HEAD`. Si la rama es `main`, para: en main no se trabaja. Si no hay cambios, di "Nada que commitear" y para.
2. Revisa solo esos cambios (no la rama entera): lógica rota, referencias en .tscn/.tres que no se actualizaron al renombrar, uid= o ids de ext_resource cambiados, tile_map_data escrito a mano, reglas de CLAUDE.md incumplidas.
3. Lanza el agente `probador`.
4. Si hay problemas o el probador da errores, para y enséñalos (archivo:línea y por qué). No commitees.
5. Si todo va bien: `git add -A` y commit. Mensaje en español: una primera línea corta con qué cambia en el juego (no qué archivos), y debajo, si hace falta, 1-3 líneas con el porqué o los detalles que no se ven en el código.

Termina con una línea: el mensaje del commit, o qué falló.
