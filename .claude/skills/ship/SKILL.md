---
name: ship
description: Lleva la rama del ticket a main sin revisión manual: commitea lo pendiente, trae main y resuelve conflictos, sube la rama, abre el PR y lo fusiona con squash. Con "todo", desde el chat central, lo hace con todos los worktrees.
disable-model-invocation: true
argument-hint: "[todo]"
---

Lleva la rama actual a main. `main` de GitHub tiene que poder descargarse y abrirse sin errores. Nunca `--force` ni descartar cambios de nadie.

Argumento (puede estar vacío): $ARGUMENTS. Si es "todo" y estás en la carpeta principal: haz los pasos 1-7 en cada worktree de `.claude/worktrees/` (con `git -C <carpeta>`), uno detrás de otro, y después la limpieza del chat central (ver `.claude/skills/hub/SKILL.md`) por cada uno. Si uno se para, sáltalo, sigue y al final di cuáles se pararon y por qué.

1. Si estás en `main`, para: no hay nada que subir.
2. Si hay cambios sin commitear, sigue `.claude/skills/commit/SKILL.md`. Si se para, para tú también.
3. `git fetch origin`. Si la rama no tiene commits que no estén en `origin/main`, para: no hay nada que subir.
4. Si `origin/main` no está ya en la rama (`git merge-base --is-ancestor origin/main HEAD`), `git merge origin/main`. Si hay conflictos:
   - Los dos cambios se pueden sumar (textos, docs, cosas distintas añadidas en la misma zona): combínalos tú.
   - `.tscn`/`.tres` con cambios en nodos o zonas distintas, o solo reordenados por el editor: combínalos tú, sin tocar uid= ni ids de ext_resource.
   - Los dos cambiaron la misma lógica, o la misma propiedad del mismo nodo, de formas distintas; o es un archivo binario (imagen, audio): para. No subas. Explica las dos versiones en lenguaje claro y pregunta cuál vale o cómo combinarlas (AskUserQuestion).
   Con todo resuelto, commit de la fusión.
5. Lanza el agente `probador` (salvo que el paso 2 lo acabe de pasar y no hubo fusión en el paso 4). Si da errores, intenta arreglarlos una vez con `/commit`; si siguen, para y explícalos.
6. Sube y fusiona:
   - `git push -u origin <rama>`.
   - Si no hay PR abierto para la rama (`gh pr view <rama>`), créalo: `gh pr create --base main --head <rama>` con título = qué cambia en el juego, y cuerpo = resumen para alguien que está aprendiendo + lista de commits de la rama.
   - `gh pr merge <rama> --squash --delete-branch`. Si GitHub dice que no se puede fusionar porque `main` avanzó, vuelve al paso 3 (como mucho 2 veces).
7. Comprueba con `gh pr view <rama> --json state,url` que el estado es `MERGED`.
8. Dejar lo local en solo `main`:
   - En la carpeta principal: `git checkout main && git fetch --prune && git pull --ff-only && git branch -D <rama> && git worktree prune`. `-D` es necesario por el squash y solo se usa porque el paso 7 confirmó `MERGED`. Si hay cambios sin commitear que bloquean el pull, no los descartes: avisa.
   - Si entraste con `EnterWorktree`: sal con `ExitWorktree` (`remove`) y haz lo de arriba.
   - En un chat con worktree abierto por el chat central: no puedes tocar la carpeta principal. Avisa al chat central con `SendMessage` a `central`: "Subido <rama> desde <carpeta del worktree>". Él limpia.

Termina con una línea: el enlace del PR fusionado, o en qué paso se paró y por qué.
