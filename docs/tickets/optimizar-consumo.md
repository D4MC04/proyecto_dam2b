# Que el juego no caliente el portátil (sobre todo en pausa y en reposo)

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: alta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Con el juego abierto y en pausa (o quieto en un menú) el portátil se calienta. Un juego 2D pixel art parado no debería gastar casi nada. Hay que bajar el consumo sin romper nada de lo que hay.

## Qué hay que hacer
- **Medir primero.** Con el monitor de Godot (FPS, tiempo de proceso, draw calls, nodos) y el Administrador de tareas (CPU/GPU), apuntar el consumo en estos casos: menú/oficina quieto, nivel en pausa, nivel jugando a ×1 y a ×4 con una oleada grande, Navedex. Repetir las mismas medidas al final y dejar la tabla antes/después en el resumen del chat.
- Sospechosos a revisar (confirmar con las medidas, no cambiar a ciegas):
  - `project.godot` no limita los FPS (`application/run/max_fps`) y la opción VSync de `Settings` se puede apagar: sin VSync el juego dibuja cientos de FPS. Poner un tope (p. ej. 60) aunque se apague el VSync.
  - El renderer es Forward+ (`config/features` "Forward Plus"): para un juego 2D, valorar `gl_compatibility` (mucho más ligero). Solo si los shaders, la luz y los efectos se ven igual; si algo cambia, no hacerlo y decirlo.
  - En pausa y con la ventana sin foco: bajar los FPS (p. ej. `Engine.max_fps` a 30 o menos en pausa y menos aún sin foco, ver flujo.md › "Pérdida de foco") y que no se redibuje lo que no cambia.
  - 46 scripts con `_process`/`_physics_process` y ~59 `queue_redraw()`: que los que no hacen nada en un estado se paren (`set_process(false)`) y que `_draw` solo se repita cuando algo cambia. Ojo con los nodos con `process_mode` ALWAYS (`LevelUI`, `Base`, `GameState`, `MusicManager`) porque siguen en pausa.
  - Partículas, shaders del fondo (`SpaceBackground`) y animaciones del menú (estrellas, cometas, asteroides, satélites) en bucle.
- **No romper nada:** mismo aspecto, misma velocidad de juego y mismas animaciones. Probar mucho: arranque, oficina, selección de nivel, Navedex, niveles 1, 5 y 9 enteros a ×1 y ×4, pausa, derrota, victoria, opciones (VSync y pantalla completa) y el nivel de emergencia. El `probador` en headless después de cada bloque de cambios.
- Si el editor de Godot también calienta estando abierto, decirle al usuario qué ajuste de su editor tocar (p. ej. que no esté en "Update Continuously"); eso no va en el repo.

## Qué leer
- docs/design/flujo.md › "Autoloads", "Escena Game" y "Pérdida de foco"
- scripts/autoloads/Settings.gd › opciones `vsync` y `show_fps`
- project.godot › [application], [display], [rendering]

## Archivos que toca
- project.godot
- scripts/autoloads/Settings.gd y los scripts con `_process`/`_draw` que se demuestre que gastan
- docs/design/flujo.md (sección nueva corta de rendimiento: topes de FPS y qué se para en pausa)

## Cómo se prueba a mano
1. Abrir el juego, entrar en un nivel y pausarlo 5 minutos: el ventilador no debería subir y el Administrador de tareas debería marcar poca CPU/GPU.
2. Dejar la oficina quieta 5 minutos: igual.
3. Jugar un nivel entero a ×4: se ve y va igual que antes.
4. Apagar VSync en opciones: los FPS (opción "mostrar FPS") no pasan del tope.
