# Atajos de teclado en el nivel

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
Ahora todo se hace con el ratón: elegir torre, lanzar oleada, AUTO y ×2. Con teclas se juega más rápido, sobre todo en oleadas largas.

## Qué hay que hacer
- Acciones nuevas en el Input Map de `project.godot`: `select_tower_1` … `select_tower_7` (teclas 1-7), `next_wave` (Espacio), `toggle_auto` (A), `toggle_speed` (F).
- Las teclas 1-7 eligen la torre en el orden de la rejilla de `// TORRES`, pasando por el mismo camino que el clic (`Sidebar.tower_selected` → `LevelUI._on_tower_selected`). Si no hay dinero o la selección está bloqueada (pausa, derrota, victoria), no hacen nada, igual que el botón.
- Espacio, A y F hacen lo mismo que pulsar `NextWaveButton`, `AutoWaveButton` y el botón de velocidad (respetando que la oleada solo se lanza si la anterior acabó, ver "Decidido").
- Ninguna tecla hace nada en pausa, derrota o victoria.
- Escribir la tecla en pequeño en cada botón solo si cabe sin mover el diseño; si no, no.
- Actualizar docs/design/ui.md.

## Archivos que toca
- project.godot
- scripts/level_ui/Sidebar.gd (o LevelUI.gd)
- docs/design/ui.md

## Cómo se prueba a mano
1. F5, nivel 1.
2. Pulsar 1: queda seleccionada la primera torre, como si se hubiera hecho clic. Colocarla.
3. Espacio lanza la oleada; volver a pulsar mientras hay enemigos no lanza otra.
4. A enciende/apaga AUTO y F cambia ×1/×2; el botón cambia a la vez.
5. Escape para pausar y pulsar 1, Espacio, A, F: no pasa nada.
