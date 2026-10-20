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
- Guía completa para el usuario: docs/CLAUDE-CODE.md. Formato de ticket: docs/tasks/_plantilla.md.
- `/proponer` crea tickets con `Estado: propuesta`. Solo se implementan los `Estado: aceptada`, con `/hacer nombre`.
- Cada ticket en su rama `ticket/nombre` desde main. Nunca trabajar en main.
- Un ticket nuevo (`/proponer`) solo cambia la línea `Estado:`; no se sube nada sin visto bueno.
- **Aceptar es la orden de empezar** (casillas o "acepto X"), sin esperar otro visto bueno:
  1. Commit en `main` solo del cambio de `Estado:` de los `docs/tasks/` (única excepción a no trabajar en main; sin probador) y `git push origin main`. Si `origin/main` avanzó, antes `git pull --ff-only`.
  2. Enseguida, un chat con worktree (`start_session`, `user_asked`) por cada ticket aceptado de la primera tanda que no choque con otro, con `/hacer nombre` y su modelo y esfuerzo.
  3. Los que chocan esperan a que el anterior esté en main; el chat central los lanza al recibir el aviso de subida.
- **Subir a main** (tras el visto bueno: "sube", "va bien", "listo", "commitea"; sin preguntar más ni hacer PR, salvo que el usuario lo pida). `main` de GitHub tiene que poder descargarse y abrirse sin errores, así que antes de subir:
  1. Pasar el agente `probador` (OK) y `git fetch origin`; si `origin/main` avanzó, traerlo a la rama y volver a probar. Nunca `--force`.
  2. Commit en la rama del ticket y `git push origin <rama>:main`.
  3. Borrar la rama remota del ticket: `git push origin --delete <rama>`.
  4. Dejar lo local en solo `main`: el chat que trabaja en la carpeta principal hace `git fetch --prune`, `git pull --ff-only` (si hay cambios locales sin commitear que lo bloquean, no descartarlos: avisar), `git branch -d <rama>` (solo con `-d`, nunca borra ramas sin fusionar) y `git worktree prune`. Un chat en worktree no puede tocar la carpeta principal: avisa al chat central de que subió y este hace el paso 4; si el chat entró con `EnterWorktree`, sale con `ExitWorktree` (`remove`) y lo hace él.
  5. Preguntar si archiva el chat del ticket (ver abajo).
- **Chat central** (se abre con `/new`): trabaja en la carpeta principal sobre `main`, en Opus. Propone y reparte tickets en chats con worktree, revisa lo que suben y hace el paso 4 de "Subir a main" para que el usuario nunca tenga que hacer `git pull` a mano. Cada vez que arranca o recibe un aviso de subida, deja `main` local al día.
- `/new`: crea el chat central y archiva el chat donde se escribió (se puede recuperar desde Archivados).
- Para probar, usar el agente `probador`. Antes de commitear o subir, `/revisar` (prueba, revisa y mira conflictos con main).
- Avisar al usuario de qué comando toca, al final de la respuesta, en una línea:
  - Pregunta qué tickets quedan o cuáles se pueden hacer a la vez → `/tickets`.
  - Sin tickets aceptados o pide ideas → `/proponer`.
  - Ticket aceptado → `/hacer nombre`, con el modelo y el esfuerzo que pone el ticket (`Modelo recomendado` y `Esfuerzo recomendado`).
  - Tras `/hacer` → probar a mano en Godot y luego `/revisar`.
  - `/revisar` en OK → "commitea" (con el visto bueno, commit y subida directa a main).
  - Ticket ya en main y probado a mano por el usuario → preguntar si archiva el chat de ese ticket (si dice que sí, archivarlo; si es el chat actual, archivarse a sí mismo al final).
  - Chat largo o tema distinto al del chat → abrir chat nuevo.
  - Tarea mecánica en Opus → bajar a Sonnet o Haiku. Sonnet atascado dos veces → subir a Opus.

## Sprites
- Pixel art 16x16. Seguir docs/design/art.md y el estilo de los sprites existentes en assets/.

## Antes de dar algo por terminado
- Comprobar que el proyecto carga sin errores en headless. Godot (no está en el PATH): `C:\Users\renzo\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` o `C:\Users\David\Desktop\Godot.exe`, el que exista en el equipo.
- No commitear ni subir a menos que el usuario lo pida o dé el visto bueno. Si lo hace, hacer el commit y subirlo a main como dice "Flujo de tickets".
- Al acabar una tarea, dar al usuario unos pasos breves para comprobar a mano que funciona en el juego: qué escena abrir, qué hacer y qué debería verse.
