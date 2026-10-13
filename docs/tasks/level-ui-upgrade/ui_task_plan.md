# Rediseño de la UI de nivel: plan de tareas

Resumen de lo decidido con David y de las tareas en orden. Cuando haya contradicciones con [propuesta_ui.md](propuesta_ui.md), manda este documento. Los md individuales de cada tarea (para `docs/tasks/`) se redactan uno a uno cuando se pidan.

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
- **Estética:** en cada md de tarea se pide a Claude Code que haga la interfaz más bonita y cuidada, manteniendo el pixel art y la paleta de `docs/design/art.md`.

## Tareas, en orden

Cada una se prueba y se commitea por separado. Las 1 y 2 van primero. Después, los bloques de barra derecha, barra izquierda y pantallas son casi independientes; la única dependencia cruzada es que la 10 necesita la 4.

### Base

1. **Selección de torre en `LevelState`.** Única fuente de verdad con la señal `selected_tower_changed`. Se quita la doble conexión de `tower_selected` (desde `Game` y desde `LevelUI`). El botón se suelta solo cuando `BuildManager` cancela con clic derecho. Sin cambios visuales.
2. **Viewport 640 y tres columnas.** Se cambia `project.godot` (640x272, ventana 1920x816). `LevelUI` pasa a tener barra izquierda, área de juego y barra derecha, todas de momento vacías o con lo actual. El mapa se centra en el área de juego según su rectángulo útil. Hay que revisar el menú principal y los 6 niveles.

### HUD y barra derecha

3. **Nivel arriba en el centro.** Etiqueta del nivel con la transparencia, el paso de clics y el aclarado descritos arriba.
4. **Pestañas y pestaña Torres.** `TabContainer` con Torres y Oleadas (Oleadas vacía de momento). Rejilla de torres rediseñada con el dinero en la cabecera y un borde con el color de acento de la torre seleccionada.
5. **Pestaña Oleadas.** Bloques por oleada con celdas de enemigo (sprite ×N, agrupados por tipo) y "Oleada X/Y" en la cabecera. La actual resaltada y las pasadas atenuadas. Hace falta que `Spawner` avise del cambio de oleada. Hoy cada nivel tiene una sola oleada.

### Barra izquierda

6. **Ficha de torres.** Marco fijo y estado de reposo con el escáner. Clic derecho e izquierdo en la tienda, también con el botón desactivado. Filas generadas desde `TowerData` según el tipo de ataque, iconos de 8x8, formato K/M y scroll. La señal es `inspected_changed`.
7. **Ficha de enemigos.** Clic derecho en las celdas de la pestaña Oleadas. Filas desde `EnemyData` (vida, velocidad, recompensa) con el mismo marco.

### Pantallas

8. **Estado de UI único y escena base de pantallas.** Enum de estado en `LevelUI`, `OverlayScreen` con `option_chosen` y una sola señal hacia `Game`. Pausa y derrota pasan a ser escenas heredadas de la base, sin cambio visual.
9. **Victoria funcional.** `Level` emite `won` cuando termina la última oleada y no queda ningún enemigo. `Game` llama a `set_state(WON)` y se conecta "Siguiente nivel". Si la pantalla ya existe en la rama `ui-update`, se adapta a la base.
10. **Pausa rediseñada.** Estilo cian, plegable, barras activas y selección de torre bloqueada (necesita la 4).
11. **Ajustes en pausa.** El control de volumen del menú principal pasa a ser un componente reutilizable, que se usa en el menú y en un subpanel de la pausa.
12. **Derrota rediseñada.** Estilo rojo, cámara lenta antes de pausar, glitch, y un resumen de partida reutilizable (oleada alcanzada, enemigos destruidos, dinero gastado).
13. **Victoria rediseñada.** Estilo ámbar, entrada deslizando y conteo, reutilizando el resumen de la 12.

## Pendiente de decidir más adelante

- Mostrar la vida de la base.
- Valoración de 1 a 3 estrellas en la victoria.
- Inspeccionar torres colocadas y enemigos en el mapa (datos en vivo, vender o mejorar).
- Vista previa de la ficha al pasar el ratón.
- Fuente secundaria más estrecha para la ficha.
