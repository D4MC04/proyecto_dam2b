---
name: ship
description: Revisa la rama del ticket y, si está bien, la commitea, la sube directa a main y borra la rama. Con "todo", desde el chat central, sube todos los worktrees listos.
model: opus
disable-model-invocation: true
argument-hint: "[todo]"
---

Sube a main la rama actual. `main` de GitHub tiene que poder descargarse y abrirse sin errores. Nunca `--force`. No hagas PR salvo que el usuario lo pida.

Argumento (puede estar vacío): $ARGUMENTS. Si es "todo" y estás en la carpeta principal: haz los pasos 1-4 en cada worktree de `.claude/worktrees/` (con `git -C <carpeta>`), uno detrás de otro, y después la limpieza del chat central (ver `.claude/skills/hub/SKILL.md`) por cada uno. Si uno no pasa la revisión, sáltalo y sigue.

1. Si estás en `main`, para: no hay nada que subir.
2. Revisión: sigue `.claude/skills/check/SKILL.md` (incluye el `probador`). Si hay problemas, errores del probador o conflictos con main, para y enséñalos. No subas.
3. Commit de todo en la rama (mensaje corto en español de qué cambia). `git fetch origin`; si `origin/main` avanzó desde la revisión, `git merge origin/main` y vuelve a pasar el `probador`.
4. En un solo comando: `git push origin HEAD:main && git push origin --delete <rama>` (si la rama no estaba en remoto, ignora ese error).
5. Dejar lo local en solo `main`:
   - En la carpeta principal: `git checkout main && git fetch --prune && git pull --ff-only && git branch -d <rama> && git worktree prune`. Si hay cambios sin commitear que lo bloquean, no los descartes: avisa.
   - Si entraste con `EnterWorktree`: sal con `ExitWorktree` (`remove`) y haz lo de arriba.
   - En un chat con worktree abierto por el chat central: no puedes tocar la carpeta principal. Avisa al chat central con `SendMessage` a `central`: "Subido <rama> desde <carpeta del worktree>". Él limpia.

Termina con una línea: qué se subió, o qué falló.
