# Comando /test: abrir Godot ya en el punto de prueba

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Ahora, tras `/work` o `/fix`, solo se abre el editor y hay que navegar hasta lo que se quiere probar. Además, muchas veces Claude dice que Godot está abierto pero no se ve, y hay que pedirlo una o dos veces más. Eso ralentiza mucho cada prueba.

## Qué hay que hacer
- Skill nueva `.claude/skills/test/SKILL.md` (comando `/test`; el usuario la puede lanzar y también Claude, sin `disable-model-invocation`). Hace lo siguiente:
  - Cierra solo el Godot abierto en la carpeta de ese chat (el worktree), no los de otras carpetas.
  - Abre el editor (`$GODOT --path <carpeta> -e`) y además el juego (`$GODOT --path <carpeta> -- <argumentos de prueba>`), colocado en el punto donde se prueba lo que se ha implementado o cambiado en ese chat. Si el cambio es muy general, abre el juego sin argumentos.
  - Lanza los procesos desacoplados para que no mueran al acabar la llamada a la herramienta. Espera unos segundos, comprueba que el proceso sigue vivo y tiene ventana, y la trae al frente: Windows no deja que un proceso en segundo plano se ponga delante. Si no sale, reintenta una vez. Si sigue sin salir, lo dice claramente en vez de decir que está abierto.
  - Cuando el usuario pide "abre godot" (o similar) en un chat de ticket, se usa `/test` y se abre ese mismo punto de prueba.
- Argumentos de arranque de prueba, solo en depuración (`OS.is_debug_build()`), generalizando `--office-tutorial` de `StartScreen.gd`: ir directo a un nivel concreto, a una oleada concreta, con dinero de sobra, a la oficina, etc. Sin ranura de guardado, para no guardar nada. Solo los que hagan falta para que `/test` llegue a los puntos de prueba habituales.
- Escenas de prueba propias solo si ahorran mucho tiempo frente a llegar desde el juego. Van en `scenes/dev_preview/` y `scripts/dev_preview/` (ya ignoradas por git) y se borran antes de `/merge`. Aun así, siempre hay un paso de prueba dentro del juego real.
- `/work` (paso 6) y `/fix` (paso 5) usan `/test` en vez de `Start-Process ... -e`. Sus pasos para probar dicen qué abre ya Godot y qué hacer ahí.
- Actualizar `CLAUDE.md`: el apartado "Antes de dar algo por terminado" y la lista de comandos de "Flujo de tickets". Actualizar también `docs/CLAUDE-CODE.md`: la tabla de comandos y los pasos del flujo.

## Qué leer
- .claude/skills/work/SKILL.md › pasos 6 y 7
- .claude/skills/fix/SKILL.md › paso 5
- scripts/screens/StartScreen.gd › `_ready()` (arranque con `--office-tutorial`)
- scripts/autoloads/GameState.gd › `current_level`, `load_slot()`
- CLAUDE.md › "Antes de dar algo por terminado" y "Flujo de tickets"
- docs/CLAUDE-CODE.md › tabla de comandos y "Qué modelo usar"

## Archivos que toca
- .claude/skills/test/SKILL.md (nuevo)
- .claude/skills/work/SKILL.md
- .claude/skills/fix/SKILL.md
- scripts/screens/StartScreen.gd (y lo que haga falta para arrancar un nivel u oleada concretos)
- CLAUDE.md
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. En el chat del ticket, escribir `/test`.
2. Debería abrirse a la primera y delante de todo: el editor y el juego ya en el punto de prueba (por ejemplo, un nivel concreto empezado).
3. Volver a escribir `/test` con Godot abierto: debería cerrar el de esa carpeta y abrirlo de nuevo, también a la primera.
