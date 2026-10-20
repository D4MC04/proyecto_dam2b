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
- Subir a main: cuando el usuario da el visto bueno ("sube", "va bien", "listo", "commitea"), hacerlo sin preguntar más: commit en la rama del ticket y `git push origin <rama>:main` (avance rápido; si main avanzó, primero traer `origin/main` a la rama, nunca `--force`). Solo hacer PR si el usuario lo pide. Los tickets propuestos o aceptados que estén sin commitear también se suben cuando el usuario lo dice.
- Un ticket nuevo (`/proponer`) o aceptado (`/tickets`) solo cambia la línea `Estado:`; no se sube nada sin visto bueno.
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
