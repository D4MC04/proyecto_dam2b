# Quitar los comandos alias

Creador: David
Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
`/proponer`, `/tickets`, `/hacer`, `/revisar` y `/new` solo redirigen a `/ideas`, `/board`, `/work`, `/check` y `/hub`: duplican la lista de comandos y confunden.

## Qué hay que hacer
- Borrar las carpetas `.claude/skills/proponer`, `tickets`, `hacer`, `revisar` y `new`.
- `CLAUDE.md`: quitar de la línea de comandos la frase "`/proponer`, `/tickets`, `/hacer`, `/revisar` y `/new` son alias temporales de los anteriores."
- `docs/CLAUDE-CODE.md`: quitar la línea que dice que los nombres antiguos siguen funcionando como alias.
- Comprobar con Grep que nada más nombra esos comandos.

## Archivos que toca
- .claude/skills/proponer/, .claude/skills/tickets/, .claude/skills/hacer/, .claude/skills/revisar/, .claude/skills/new/
- CLAUDE.md
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir un chat nuevo y escribir `/`.
2. En la lista ya no salen `/proponer`, `/tickets`, `/hacer`, `/revisar` ni `/new`; siguen `/ideas`, `/add`, `/board`, `/work`, `/check`, `/commit`, `/ship` y `/hub`.
