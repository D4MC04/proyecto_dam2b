# Panel de balanceo: jugar un nivel desde el panel

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Después de tocar un nivel en el panel hay que abrir Godot y llegar a ese nivel a mano. Con un botón en el panel se elige el nivel y se abre el juego directamente en él, para probar al momento lo que se acaba de cambiar.

## Qué hay que hacer
- En la pestaña Niveles, un botón "▶ Jugar" en cada fila de nivel (1-9 y emergencia) que abre el juego (sin editor) ya dentro de ese nivel, con los argumentos de prueba de `DevLaunch.gd` (`--level=N`, `--level=emergency`).
- Si hay cambios sin guardar, avisar antes de lanzar (el juego lee los `.tres` del disco) y ofrecer guardar y jugar.
- Una página `file://` no puede lanzar programas. Hacerlo con un protocolo propio de Windows registrado solo para el usuario (`HKCU\Software\Classes\astro-artillery`, sin administrador):
  - `tools/balance/launcher/registrar.ps1`: registra el protocolo apuntando a `lanzar.ps1` de la carpeta principal del repo (no de un worktree, que se borra). Se ejecuta una vez a mano. Guarda la ruta de Godot (de `GODOT` en `.claude/settings.local.json` o del entorno), porque el navegador no la tiene.
  - `tools/balance/launcher/lanzar.ps1`: recibe `astro-artillery://play?level=N&folder=<nombre>`. Solo acepta `level` (1-9 o `emergency`) y `folder`. Rechaza cualquier otro valor.
  - Con `folder`, el nombre de la carpeta que eligió el panel (`root.name`; el navegador no da la ruta), busca en `git worktree list` la carpeta del repo con ese nombre (la principal o el worktree de un ticket). Si no hay ninguna, muestra un aviso y no abre nada.
  - Para abrir usa `.claude/skills/test/open-godot.ps1 -Path <carpeta> -GameArgs "--level=N"`, que ya cierra el Godot de esa carpeta y trae el juego al frente.
  - Si el protocolo no está registrado, el botón no hace nada visible: el panel enseña una vez cómo registrarlo.
- Ampliar la sección del panel en docs/CLAUDE-CODE.md: registrar el lanzador (una vez), el botón Jugar y que el navegador pide permiso la primera vez.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- tools/balance/levels.js › `levelColumns()`, `renderLevel()`, `button()`
- tools/balance/app.js (abrir proyecto, `beforeunload`) y tools/balance/project.js (cambios sin guardar)
- scripts/screens/DevLaunch.gd › `is_active()`, `get_arg()`
- .claude/skills/test/open-godot.ps1 (cabecera y parámetros)

## Archivos que toca
- tools/balance/levels.js, tools/balance/index.html, tools/balance/style.css
- tools/balance/launcher/registrar.ps1, tools/balance/launcher/lanzar.ps1 (nuevos)
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Ejecutar `tools/balance/launcher/registrar.ps1` una vez.
2. Abrir el panel, elegir la carpeta del juego y entrar en Niveles. Pulsar "▶ Jugar" en el nivel 3 y aceptar el permiso del navegador: debería abrirse el juego (sin editor) ya en el nivel 3, delante de todo.
3. Pulsar "▶ Jugar" en emergencia: debería cerrarse ese juego y abrirse el nivel de emergencia.
4. Cambiar un dato sin guardar y pulsar Jugar: debería avisar de que hay cambios sin guardar.
