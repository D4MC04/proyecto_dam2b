# Rediseño de la UI de nivel: plan de tareas

Resumen de lo decidido con David y de las tareas en orden. Cuando haya contradicciones con [propuesta_ui.md](propuesta_ui.md), manda este documento. Los md individuales de cada tarea (para `docs/tasks/`) se redactan uno a uno cuando se pidan.

## Cómo se escriben los md de tarea

Norma de David, para todas las tareas de este proyecto:

- Cada md termina con una sección **"Criterios de hecho"**, fácil de encontrar al abrir el archivo. Es una lista de casillas separada en **Código** (se comprueba leyendo el diff), **Juego** (se comprueba jugando, con pasos concretos) y **Documentación**.
- Cada criterio es verificable por sí solo, sin interpretación. Sirve para que Claude Code se autocompruebe, para que David verifique después y para que David revise antes de empezar que lo pedido es lo que quiere.
- Cada md se nombra con una palabra corta y fácil de escribir (por ejemplo `seleccion.md`).
- Al entregar cada md se indica el modelo recomendado (Sonnet u Opus).
- En las tareas con cambios visuales se pide que la interfaz quede más bonita y cuidada, manteniendo el pixel art. Es un intento: lo que no convenza se apunta y se corrige en la fase de estilo final.

## Estado y contexto para retomar

Para una conversación nueva que continúe este plan:

- **Rama:** `level-ui-upgrade` en `D4MC04/proyecto_dam2b` (al principio se habló de `ui-update`, pero no existe). David copia cada md a `docs/tasks/level-ui-upgrade/<nombre>.md` y su copia del plan se llama `ui_task_plan.md`.
- **Hecho y commiteado** (a 14/10): tareas 1 a 6, con 5b incluida. **Entregado y pendiente de hacer:** la 7 (`enemigos.md`). **Siguiente md a redactar:** la 8.
- **Antes de redactar cada md**, leer el código actual de la rama, porque los nombres reales ya existen y hay que usarlos: `InfoPanel`, `StatEntry`, `UiFormat` (formato K/M y segundos), `LevelIndicator`, `Sidebar` (con `inspect_requested`), `TowerButton`, `EnemyCell`, `WaveBlock`, `ScannerDisplay`, `LevelState.inspected` e `inspected_changed`, y `TowerData.accent_color`, `description` y `get_stats()`.
- Los md de trabajo están en `/mnt/project-files/ui/tareas/`. Esta conversación solo diseña: nunca edita el repo, ni commitea ni abre PRs. Se responde en español.
- La norma de los criterios de hecho también está en las instrucciones del proyecto.
- Las descripciones de torres y enemigos las escribe Claude Code y David las revisa.
- **Pantallas 10, 12 y 13:** cada md incluye tanto el comportamiento (plegable, cámara lenta, conteo) como un intento de estilo; lo que falle va a la 14.

## Decisiones

- **Distribución:** viewport de 640x272 (ventana 1920x816) con dos barras de 80 px y un área de juego de 480 px en medio. Los mapas no cambian de tamaño: cada uno se centra en el área de juego según su rectángulo útil (LogicMap más la estación).
- **Arriba en el centro del área de juego:** solo el nivel, compacto, semitransparente y sin capturar el ratón. Se vuelve casi transparente cuando el cursor o un enemigo pasan por debajo. La vida de la base no se muestra de momento.
- **Barra derecha:** pestañas Torres y Oleadas.
  - Torres: el dinero va en su cabecera, no es general.
  - Oleadas: la cabecera lleva "Oleada X/Y". Los enemigos de cada oleada se agrupan en celdas con su sprite y "×N", con la misma estructura que la rejilla de torres.
- **Barra izquierda (ficha):**
  - Clic derecho en una torre o en un enemigo de la pestaña Oleadas: se muestra su ficha. Clic izquierdo en una torre: la selecciona y también la muestra.
  - Las torres que no te puedes permitir también se pueden inspeccionar.
  - Al empezar, estado de reposo: escáner o radar en pixel art con barrido animado y el texto "SIN OBJETIVO · Clic derecho para analizar". Después se queda con lo último inspeccionado y no vuelve al reposo.
  - El contenido cambia dentro de un marco fijo, sin que la barra aparezca ni desaparezca.
  - Escalable: filas de stats generadas desde los datos, iconos de 8x8 en vez de etiquetas (el nombre del stat va en tooltip), números abreviados con K y M y ancho máximo, y scroll si no caben.
- **Pantallas:** viven en el área de juego y no tapan las barras, que siguen activas para inspeccionar.
  - Con una pantalla abierta, la pestaña Torres se atenúa y no se puede seleccionar ni deseleccionar, pero el clic derecho para inspeccionar funciona. La selección que hubiera se conserva al continuar.
  - Mismo marco para las tres, con acento y entrada distintos:
    - Pausa: cian `#40e0f0`, aparece al instante, oscurecido ligero (~35 %), se puede plegar a una etiqueta para ver el mapa. Opciones: Continuar, Reiniciar, Ajustes y Salir.
    - Derrota: rojo `#ff3c5a`, cámara lenta, glitch o estática, resumen de partida. Opciones: Reintentar y Menú.
    - Victoria: ámbar `#ecb23c`, entrada deslizando y números que cuentan hacia arriba. Opciones: Siguiente nivel y Menú.
- **Estructura:**
  - `LevelUI` con un único estado (`PLAYING`, `PAUSED`, `LOST`, `WON`) y `set_state()`.
  - Una escena base de pantalla con una sola señal `option_chosen(option)`.
  - `LevelUI` reenvía a `Game` una sola señal `action_requested`.
  - `Level` emite `won` además de `lost`.
  - `LevelState` es la única fuente de la torre seleccionada (`selected_tower_changed`) y de lo inspeccionado (`inspected_changed`).
- **Estética:** cada tarea intenta que su parte quede bonita y cuidada, en pixel art y con la paleta de `docs/design/art.md`. Al final hay una pasada de estilo que corrige lo que no haya salido bien, a partir de "Retoques visuales pendientes".

## Tareas, en orden

Cada una se prueba y se commitea por separado. Las 1 y 2 van primero. Después, los bloques de barra derecha, barra izquierda y pantallas son casi independientes; la única dependencia cruzada es que la 10 necesita la 4.

### Base

1. **Selección de torre en `LevelState`** ([tareas/seleccion.md](tareas/seleccion.md)). Única fuente de verdad con la señal `selected_tower_changed`. Se quita la doble conexión de `tower_selected` (desde `Game` y desde `LevelUI`). El botón se suelta solo cuando `BuildManager` cancela con clic derecho. Sin cambios visuales. Modelo: Sonnet.
2. **Viewport 640 y tres columnas** ([tareas/columnas.md](tareas/columnas.md)). Se cambia `project.godot` (640x272, ventana 1920x816). `LevelUI` pasa a tener barra izquierda, área de juego y barra derecha, todas de momento vacías o con lo actual. El mapa se centra en el área de juego según su rectángulo útil. Hay que revisar el menú principal y los 6 niveles. Modelo: Opus.

### HUD y barra derecha

3. **Nivel arriba en el centro** ([tareas/nivel.md](tareas/nivel.md)). Etiqueta del nivel con la transparencia, el paso de clics y el aclarado descritos arriba. Modelo: Sonnet.
4. **Pestañas y pestaña Torres** ([tareas/torres.md](tareas/torres.md)). `TabContainer` con Torres y Oleadas (Oleadas vacía de momento). Rejilla de torres rediseñada con el dinero en la cabecera y un borde con el color de acento de la torre seleccionada. Modelo: Sonnet.
5. **Pestaña Oleadas** ([tareas/oleadas.md](tareas/oleadas.md)). Bloques por oleada con celdas de enemigo (sprite ×N, agrupados por tipo) y "Oleada X/Y" en la cabecera. La actual resaltada y las pasadas atenuadas. Hace falta que `Spawner` avise del cambio de oleada. Hoy cada nivel tiene una sola oleada; el paso entre oleadas llega en la 5b. Modelo: Sonnet.

5b. **Progresión de oleadas** ([tareas/progresion.md](tareas/progresion.md)). En la pestaña Oleadas, un botón "Siguiente oleada" y un toggle AUTO (icono de rayo o texto "AUTO"). El botón está disponible cuando la oleada actual ha terminado de sacar enemigos, aunque queden vivos, y desde el principio para la primera. Con AUTO activo, la siguiente oleada empieza sola cuando mueren o salen todos los enemigos de la actual. Valores por defecto (cámbialos si no cuadran): la primera oleada espera al botón para dejar construir; AUTO empieza desactivado en cada nivel. El `Spawner` lleva la cuenta de enemigos vivos y emite que la oleada está limpia; la victoria (tarea 9) usa eso en la última. Modelo: Opus.

### Barra izquierda

6. **Ficha de torres** ([tareas/ficha.md](tareas/ficha.md)). Marco fijo y estado de reposo con el escáner. Clic derecho e izquierdo en la tienda, también con el botón desactivado. Filas generadas desde `TowerData` según el tipo de ataque, iconos de 8x8, formato K/M y scroll. La señal es `inspected_changed`. Modelo: Opus.
7. **Ficha de enemigos** ([tareas/enemigos.md](tareas/enemigos.md)). Clic izquierdo o derecho en las celdas de la pestaña Oleadas. La ficha pasa a usar un contrato común (icono, nombre, etiqueta, acento, `get_stats()`, descripción) en vez de ramas por tipo. Filas desde `EnemyData` (vida, velocidad, recompensa) con el mismo marco. Modelo: Sonnet.

### Pantallas

8. **Estado de UI único y escena base de pantallas.** Enum de estado en `LevelUI`, `OverlayScreen` con `option_chosen` y una sola señal hacia `Game`. Pausa y derrota pasan a ser escenas heredadas de la base, sin cambio visual. Modelo: Opus.
9. **Victoria funcional.** `Level` emite `won` cuando termina la última oleada y no queda ningún enemigo. `Game` llama a `set_state(WON)` y se conecta "Siguiente nivel". En la rama no existe pantalla de victoria; se crea sobre la base de la tarea 8. Modelo: Sonnet.
10. **Pausa rediseñada.** Estilo cian, plegable, barras activas y selección de torre bloqueada (necesita la 4). Modelo: Sonnet.
11. **Ajustes en pausa.** El control de volumen del menú principal pasa a ser un componente reutilizable, que se usa en el menú y en un subpanel de la pausa. Modelo: Sonnet.
12. **Derrota rediseñada.** Estilo rojo, cámara lenta antes de pausar, glitch, y un resumen de partida reutilizable (oleada alcanzada, enemigos destruidos, dinero gastado). Modelo: Opus.
13. **Victoria rediseñada.** Estilo ámbar, entrada deslizando y conteo, reutilizando el resumen de la 12. Modelo: Sonnet.
14. **Pasada de estilo final.** Corrige lo apuntado en "Retoques visuales pendientes" y unifica detalles. Se plantea cuando se llegue (puede ser una o varias tareas).

## Pendiente de decidir más adelante

- Mostrar la vida de la base.
- Valoración de 1 a 3 estrellas en la victoria.
- Inspeccionar torres colocadas y enemigos en el mapa (datos en vivo, vender o mejorar).
- Vista previa de la ficha al pasar el ratón.
- Fuente secundaria más estrecha para la ficha.

## Retoques visuales pendientes

Para la fase de estilo final. Se apuntan aquí conforme aparecen.

- (vacío)
