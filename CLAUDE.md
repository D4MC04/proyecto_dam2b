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

## Sprites
- Pixel art 16x16. Seguir docs/design/art.md y el estilo de los sprites existentes en assets/.

## Antes de dar algo por terminado
- Comprobar que el proyecto carga sin errores en headless.
- No commitear: lo hacen los humanos.
