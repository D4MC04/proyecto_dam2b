# Astro Artillery (Godot 4, 2D)

## Estructura
- scripts/: lógica GDScript. scenes/: escenas. resources/: Resource (datos). assets/: sprites y audio.
- docs/: documentación del proyecto (ver abajo).

## Convenciones de código
- Guía oficial de estilo de GDScript: indentación con tabs, snake_case en variables y funciones, PascalCase en clases, UPPER_SNAKE_CASE en constantes.
- Identificadores (variables, funciones, clases, señales, nodos) en inglés. Comentarios en español.
- GDScript tipado siempre.
- Si el código existente no sigue estas reglas, seguir estas reglas, no el código existente.

## Escenas y mapas
- Se pueden crear y editar .tscn y .tres (UI, escenas de juego, TileSet).
- No cambiar los uid= ni los id de ext_resource existentes.
- Los mapas con TileMapLayer se generan con un script a partir de datos (cuadrícula de texto o Resource). No escribir tile_map_data a mano.
- Al renombrar variables, funciones, señales o nodos, actualizar también sus referencias en .tscn y .tres.
- Dar nombres claros a los nodos nuevos.

## Documentación
- Diseño actual: @docs/DESIGN.md. El detalle por sistema está en docs/design/: leer solo el que toque.
- Tareas en `docs/tasks/nombre.md`. Hacer solo la tarea indicada.
- Antes de implementar, comprobar que no contradice la sección "Decidido" de DESIGN.md. Si contradice, parar y avisar.
- Al terminar una tarea: actualizar el docs/design/ afectado (y DESIGN.md si cambia algo general) y borrar el archivo de la tarea.
- No crear otros .md sin que se pida.

## Flujo de tickets
- Guía para el usuario: docs/CLAUDE-CODE.md. Formato de ticket: docs/tasks/_plantilla.md.
- Comandos: `/ideas` (Claude propone tickets), `/add` (tickets con las ideas del usuario), `/board` (estado, choques y tandas), `/work nombre` (implementa), `/check` (revisa sin tocar nada), `/commit` (revisa lo pendiente, prueba y commitea en la rama), `/ship` (commitea lo pendiente, abre el PR y lo fusiona en main con squash), `/hub` (abre el chat central). `/proponer`, `/tickets`, `/hacer`, `/revisar` y `/new` son alias temporales de los anteriores.
- Solo se implementan tickets con `Estado: aceptada`, cada uno en su rama `ticket/nombre` desde main. Nunca trabajar en main, salvo el commit del `Estado:` al aceptar.
- Solo se sube a main con `/ship`. Si el usuario dice "commitea", hacer `/commit`; si dice "sube" o parecido, no subir: recordarle `/ship`.
- **Aceptar es la orden de empezar** (casillas o "acepto X"), sin esperar otro visto bueno:
  1. Cambiar solo la línea `Estado:` a `aceptada`. Commit en `main` solo de eso (sin probador) y `git push origin main`; si `origin/main` avanzó, antes `git pull --ff-only`.
  2. Si hay herramienta `start_session` (app de escritorio): enseguida, un chat con worktree (`user_asked`) por cada ticket aceptado de la primera tanda que no choque con otro, con `/work nombre` y su modelo y esfuerzo. Si no la hay: decir al usuario que lance `/work nombre`.
  3. Los que chocan esperan a que el anterior esté en main; el chat central los lanza al recibir el aviso de subida.
- **Casillas para aceptar** (al final de `/ideas`, `/add` y `/board`, si hay tickets en `Estado: propuesta`): AskUserQuestion en multiSelect, una opción por ticket (etiqueta: nombre; descripción: qué aporta, modelo, esfuerzo y tanda), máximo 4 por pregunta y hasta 4 preguntas agrupadas por tanda. Los marcados se aceptan como arriba; si no marca ninguno, no se cambia nada.
- **Chat central** (`/hub`): carpeta principal, rama `main`, en Opus. Reparte tickets, recibe los avisos de subida y deja `main` local al día para que el usuario nunca haga `git pull` a mano.
- Para probar, usar el agente `probador`.
- Comandos `gh`: si existe la variable `GH_USER`, lanzarlos con la cuenta de este proyecto sin guardar el token: `GH_TOKEN="$(gh auth token --user "$GH_USER")" gh ...`.
- Avisar al usuario de qué comando toca, al final de la respuesta, en una línea:
  - Pregunta qué tickets quedan o cuáles se pueden hacer a la vez → `/board`.
  - Quiere arreglar o añadir algo concreto → `/add`. Pide ideas → `/ideas`.
  - Ticket aceptado → `/work nombre`, con el modelo y el esfuerzo que pone el ticket.
  - Tras `/work` → probar a mano en Godot y luego `/ship`.
  - Ticket ya en main → decir que su chat, su worktree y su rama ya se borraron.
  - Chat largo o tema distinto al del chat → abrir chat nuevo.
  - Tarea mecánica en Opus → bajar a Sonnet o Haiku. Sonnet atascado dos veces → subir a Opus.

## Ahorro de tokens
- Cada llamada a una herramienta reenvía todo el contexto: hacer las menos posibles.
- Juntar en un solo comando de Bash (con `&&` o `;`) lo que no necesite ver el resultado anterior para decidir. Las llamadas independientes, en paralelo en el mismo mensaje.
- No releer archivos ya leídos ni comprobar lo que una herramienta ya confirmó.

## Sprites
- Pixel art 16x16. Seguir docs/design/art.md y el estilo de los sprites existentes en assets/.

## Antes de dar algo por terminado
- Comprobar con el agente `probador` que el proyecto carga sin errores en headless. Busca Godot en la variable de entorno `GODOT`, que cada uno pone en su `.claude/settings.local.json` (ver docs/CLAUDE-CODE.md).
- Commitear solo con `/commit` y subir solo con `/ship` (salvo el cambio de `Estado:` al aceptar).
- Al acabar una tarea (y tras cada cambio que haya que volver a probar), abrir yo el editor de Godot (`$GODOT`) en la carpeta donde están los cambios (el worktree del ticket) con `--path <carpeta> -e`, en segundo plano. Si ya había uno abierto en esa carpeta, cerrarlo antes. El usuario no tiene que cambiar de rama ni copiar rutas: solo pulsa F5 y juega.
- Dar al usuario unos pasos breves para comprobar a mano que funciona en el juego: qué nivel jugar, qué hacer y qué debería verse.
