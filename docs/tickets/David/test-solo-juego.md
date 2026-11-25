# /test abre solo el juego, sin el editor

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
`/test` abre el editor de Godot y además el juego. El editor sobra: para probar basta con el juego ya colocado en el punto de prueba.

## Qué hay que hacer
- `open-godot.ps1` deja de abrir el editor: cierra el Godot de esa carpeta y abre solo el juego con los argumentos de prueba, lo espera, reintenta una vez y lo trae al frente, como ahora.
- Lo que hoy se probaba solo en el editor (`-NoGame`, algo que se ve en una escena) pasa a abrirse como juego con esa escena directamente (por ejemplo `godot --path <carpeta> res://scenes/...`, o una escena de `scenes/dev_preview/`). Quitar `-NoGame` si deja de tener sentido.
- Ajustar los textos que hablan del editor: `.claude/skills/test/SKILL.md` (pasos 2 y 3, "EDITOR OK" y el final, que dice que se puede volver a lanzar con F5 desde el editor: ahora es `/test` otra vez), `CLAUDE.md` › "Antes de dar algo por terminado" y `docs/CLAUDE-CODE.md`.

## Qué leer
- .claude/skills/test/SKILL.md
- .claude/skills/test/open-godot.ps1
- CLAUDE.md › "Antes de dar algo por terminado"
- docs/CLAUDE-CODE.md › donde hable de `/test` (sacarlo con Grep)

## Archivos que toca
- .claude/skills/test/open-godot.ps1
- .claude/skills/test/SKILL.md
- CLAUDE.md
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. En el chat del ticket, escribir `/test`.
2. Debería abrirse solo el juego, delante de todo, sin ninguna ventana del editor.
3. Volver a escribir `/test` con el juego abierto: debería cerrarlo y abrirlo de nuevo.
