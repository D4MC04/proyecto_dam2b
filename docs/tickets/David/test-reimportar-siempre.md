# /test reimporta siempre antes de abrir el juego

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
`/test` solo importa el proyecto (la copia de `.godot/`) la primera vez que se abre una carpeta. Si después se cambia un sprite u otro recurso importado, el juego lo sigue enseñando antiguo hasta que alguien vuelva a importar.

## Qué hay que hacer
- En `open-godot.ps1`, importar siempre (`--headless --path <carpeta> --import`) antes de abrir el juego, no solo cuando falta `.godot`. Si no cambió nada, apenas tarda.
- Ajustar el comentario del paso 2 del script y, si lo menciona, `.claude/skills/test/SKILL.md`.

## Qué leer
- .claude/skills/test/open-godot.ps1 › paso 2 (línea ~102, "Carpeta sin importar")

## Archivos que toca
- .claude/skills/test/open-godot.ps1
- .claude/skills/test/SKILL.md (si hace falta)

## Cómo se prueba a mano
1. En un chat de ticket, cambiar un sprite y escribir `/test`.
2. El juego debería enseñar ya el sprite nuevo, sin importar nada a mano.
