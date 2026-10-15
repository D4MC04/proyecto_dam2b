# Embellecer la UI: plan de tareas

Segunda fase de la interfaz, después de [plan_tareas_ui.md](plan_tareas_ui.md) (que ya está hecho y en `main`). Aquí van la nueva resolución, la fuente y la estética de escáner u holograma. Si algo choca con el plan anterior, manda este. Los md individuales de cada tarea se redactan uno a uno cuando se pidan.

## Cómo se escriben los md de tarea

Igual que en el plan anterior:

- Cada md termina con una sección **"Criterios de hecho"** con casillas separadas en **Código** (se comprueba leyendo el diff), **Juego** (se comprueba jugando, con pasos concretos) y **Documentación**.
- Cada criterio se puede comprobar por sí solo, sin interpretación.
- Cada md se nombra con una palabra corta (por ejemplo `fuente.md`).
- Cada tarea lleva su modelo recomendado (Sonnet para trabajo acotado, Opus para trabajo con muchas piezas o de arquitectura).
- Antes de redactar cada md se lee el código actual de la rama para usar los nombres reales.

## Estado y contexto para retomar

- **Rama:** `ui-beautify` en `D4MC04/proyecto_dam2b`, creada desde `main` después de mergear `level-ui-upgrade` y el menú de Opciones del compañero. David copia cada md a `docs/tasks/ui-beautify/<nombre>.md`.
- **Hecho:** la 1 (`resolucion`) y la 2 (`fondo`). **Siguiente md a redactar:** la 3 (`fuente.md`).
- Esta conversación solo diseña. Se responde en español.
- **Referencia visual:** [maqueta/maqueta_juego.png](maqueta/maqueta_juego.png) y [maqueta/maqueta_pausa.png](maqueta/maqueta_pausa.png). Las aprobó David el 15/10, con dos cambios: los botones no llevan corchetes ni `>`, y el mapa de la maqueta es relleno.

## Decisiones (15/10)

- **Resolución:** viewport de 960x540 con ventana de 1920x1080 y escalado entero a 2x. En monitores más grandes salen bandas negras en vez de estirar.
- **Columnas:** dos barras de 128 px y un área de juego de 704x540 en medio.
- **Mapas: no se tocan de momento** (salvo añadirles el nodo del fondo). Se quedan como están y se centran en el área de juego, en horizontal y en vertical. Se ampliarán cuando el tamaño final esté asegurado, para no rehacerlos otra vez.
- **Fondo:** el mismo fondo de espacio en todos los niveles, detrás de todo y cubriendo toda el área de juego. Es parte del visual del mapa: cada mapa (y la plantilla `Map.tscn`) lo lleva como nodo `Background`, que no se mueve al centrar el mapa.
- **Fuente:** solo Monogram, en todo el juego. PressStart2P desaparece. Los títulos grandes (PAUSA, ESTACION PERDIDA, SECTOR ASEGURADO) usan Monogram a un múltiplo entero de su tamaño base. David descarga Monogram y la pone en `assets/fonts/`.
- **Barras = tablet física:**
  - Marco de metal con la rampa gris azulada de `docs/design/art.md` (`#343a4a`, `#606a7c`, `#96a2b6`), contorno `#0c0e16`, tornillos en las esquinas y rejilla de altavoz abajo.
  - Dentro, una pantalla oscura con líneas de barrido, corchetes en las esquinas y cabeceras tipo `// TORRES` con una regla de marcas debajo.
- **Pantallas de pausa, derrota y victoria = holograma flotante.** Panel translúcido con esquinas recortadas, doble borde, regla de marcas arriba, corchetes por fuera del panel y un pie de texto tenue (por ejemplo "SISTEMA EN ESPERA"). Cada una mantiene su acento (cian, rojo, ámbar) y su entrada actual.
- **Botones en todo el juego:** caja con esquinas recortadas. Al pasar el ratón se rellenan con el acento y el borde se aclara. **Sin corchetes ni `>`.**
- **El menú de Opciones del compañero** se adapta al mismo estilo.
- **El camino del mapa no se toca.** La banda translúcida de la maqueta era relleno.
- **Indicador de nivel:** sin marco y al doble de tamaño.
- **Tooltips:** fuera de todo el juego. Las filas de stat llevan el nombre escrito al lado del icono (COSTE, DAÑO, ALCANCE…).
- **Pestaña Oleadas:** se ve una sola oleada, con flechas ◀ ▶ para mirar las demás. Cuando empieza otra oleada, la vista vuelve sola a la actual. Debajo van LANZAR y AUTO. Se acaba la lista larga con scroll.
- **Pie de la barra derecha:** "OL. X/Y" y el estado de la oleada, visible en las dos pestañas.
- **Tienda:** las torres tienen margen dentro de su recuadro y el coste va debajo. El dinero va en una cabecera "CREDITOS".
- **Números:**
  - Hasta 999 se escriben tal cual. Desde 1000 se usa K con un decimal y sin ".0" (5K, 5.2K, 500.5K). Desde un millón se usa M.
  - Como mucho 7 caracteres contando el €. Se trunca en vez de redondear.
  - Vale para todo: dinero, costes, stats y recuentos.

## Tareas, en orden

Cada una se prueba y se commitea por separado.

1. **Resolución y columnas** (`resolucion.md`). Modelo: Opus.
   - `project.godot` pasa a 960x540, ventana de 1920x1080 y escalado entero.
   - `LevelUI` con barras de 128 px y área de juego de 704x540.
   - El mapa se centra en el área de juego en los dos ejes (hoy `Level` solo lo centra en horizontal, con `GAME_AREA_CENTER_X`).
   - Las pantallas de pausa, derrota y victoria siguen cubriendo solo el área de juego.
   - El menú principal y el de Opciones se recolocan para que funcionen a 960x540, sin cambiar todavía su estilo.
   - Hay que revisar los 6 niveles y el menú.
2. **Fondo de espacio** (`fondo.md`). Modelo: Sonnet.
   - `FondoEspacio` pasa a ser `scenes/maps/SpaceBackground.tscn` y cubre 704x540, con estrellas animadas y cometa.
   - Cada mapa y la plantilla `Map.tscn` lo llevan como primer hijo `Background`. `Map` lo coloca en el origen del área de juego después de centrar el mapa.
3. **Fuente** (`fuente.md`). Modelo: Sonnet.
   - Monogram como única fuente en `menu_theme.tres` y en todas las escenas. PressStart2P se borra de `assets/fonts/`.
   - Los `font_size` actuales (8, 16 y 24, en unos 16 archivos) están pensados para PressStart2P. Se cambian a múltiplos enteros del tamaño nativo de Monogram para que no salga borrosa; los títulos van a 2x o 3x.
   - Se quitan los apaños por las tildes de PressStart2P: el comentario de `InfoPanel` y el título de la derrota, que vuelve a ser "SEÑAL PERDIDA" si Monogram dibuja bien la Ñ.
4. **Números y nivel** (`numeros.md`). Modelo: Sonnet.
   - `UiFormat.abbreviate` con la regla nueva, usada en todos los números de la UI.
   - Indicador de nivel sin marco y al doble de tamaño.
5. **Pestaña Oleadas** (`oleadas.md`). Modelo: Sonnet.
   - Una sola oleada a la vista, flechas, vuelta sola a la actual, y LANZAR y AUTO debajo.
   - Pie "OL. X/Y" con el estado en la barra derecha.
6. **Estilo de las barras** (`barras.md`). Modelo: Opus.
   - Las dos barras como tablet física: marco, pantalla, líneas de barrido, cabeceras.
   - Tienda con cabecera "CREDITOS" y torres con margen.
   - Filas de stat con el nombre escrito.
   - Fuera todos los tooltips del juego.
7. **Estilo de pantallas y botones** (`pantallas.md`). Modelo: Opus.
   - Pausa, derrota y victoria como holograma flotante sobre `OverlayScreen` y `OverlayFrame`.
   - El botón de esquinas recortadas pasa a ser el estilo de botón del tema, para todo el juego.
8. **Menú principal y Opciones** (`menu.md`). Modelo: Sonnet.
   - El menú principal y el de Opciones del compañero con el estilo nuevo (paneles holograma y botones del tema).

## Pendiente de decidir más adelante

- Ampliar los mapas al área de juego, cuando el tamaño final esté asegurado.
- Lo que sigue pendiente del plan anterior: vida de la base, estrellas en la victoria, inspeccionar torres colocadas y enemigos en el mapa, y vista previa de la ficha al pasar el ratón.

## Retoques visuales pendientes

Se apuntan aquí conforme aparecen.

- Barras (`barras`): la maqueta no estaba en el repo al hacer la tarea, así que el marco se hizo solo con las medidas y colores del md; falta compararlo con `maqueta_juego.png`.
- Barras: en las filas de stat de la ficha el hueco entre icono y nombre es de 2 px, justo para que quepan 9 + 7 caracteres en 108 px. Se ve algo apretado; si se quiere más aire hay que bajar `MAX_VALUE_CHARS` o acortar algún nombre.
- Pantallas (`pantallas`): `maqueta_pausa.png` tampoco estaba en el repo, así que el holograma y el botón se hicieron solo con las medidas y colores del md; falta compararlos con la maqueta.
- Pantallas: en Opciones, un interruptor en ON (estilo `pressed`, relleno al 22 %) se parece bastante a uno en OFF con el ratón encima (relleno al 35 %). Si confunde, el ON podría llevar otro color o texto.
- Pantallas: `RunSummary` y el título de oleada de la barra siguen siendo cajas rectas; no son botones, pero se podrían recortar para que todo case.
