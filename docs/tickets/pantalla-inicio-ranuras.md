# Pantalla de inicio con "pulsa cualquier tecla" y ranuras de guardado

Creador: D4MC04
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Hoy el juego arranca directamente en los botones del menú. Se quiere una entrada de juego de verdad: título, "pulsa cualquier tecla", elegir partida y un efecto de entrada antes de llegar a la oficina del comandante. Es visual: las tarjetas de las ranuras y la entrada tienen que estar muy cuidadas (de ahí Opus high).

Depende de `ranuras-guardado` (usa `load_slot`, `has_save`, `delete_slot` y `get_slot_summary`).

## Qué hay que hacer
- Escena nueva `scenes/StartScreen.tscn` + `scripts/screens/StartScreen.gd`, que pasa a ser la escena inicial (`run/main_scene` en `project.godot`). Fondo: el mismo espacio que tiene hoy el menú (`MenuBackground`, `RingedPlanet`, estrellas, cometas, asteroides, satélites, `Outpost`, `Skirmish`, viñeta), reutilizando esas escenas y scripts, sin copiarlos.
- **Fase 1, título:** "ASTRO ARTILLERY" y "TOWER DEFENSE" como ahora y debajo "PULSA CUALQUIER TECLA" parpadeando. Cualquier tecla o clic lo hace desaparecer.
- **Fase 2, ranuras:** el título se queda (puede subir un poco) y aparecen 3 rectángulos en vertical, uno por ranura, con una entrada animada.
  - Sin partida: "NUEVA PARTIDA" (o similar).
  - Con partida: un mini resumen con `GameState.get_slot_summary`: fecha y hora del último guardado, horas jugadas, sector por el que va y logros conseguidos (X/12).
  - A la derecha de cada ranura con partida, un botón rojo con una cruz para borrarla. Al pulsarlo sale una cajita "¿Seguro?" con confirmar y cancelar; al confirmar llama a `GameState.delete_slot` y la ranura pasa a "NUEVA PARTIDA".
  - Escape vuelve a la fase 1.
- **Entrar:** pulsar una ranura llama a `GameState.load_slot(n)` y lanza un efecto visual llamativo que deje claro que entras en el juego (distinto del salto al hiperespacio, que es el de entrar a un nivel), y al acabar cambia a `scenes/MainMenu.tscn`.
- Volver de un nivel (`Game._quit_to_menu`) sigue yendo a `MainMenu` sin pasar por esta pantalla.
- Quitar de `MainMenu._ready` la llamada provisional a `GameState.load_slot(1)` que dejó `ranuras-guardado`.
- Quitar "Borrar progreso" de `OptionsMenu`: ahora se borra la partida desde su ranura.
- Estilo: el de las tablets y los paneles holograma de los niveles (`TabletFrameStyle`, `OverlayFrame`, `ClippedBoxStyle`, `ScreenHeader`, colores de docs/design/ui.md), pixel art sin antialiasing y textos en Monogram. Coherencia, no copia: se pueden hacer piezas nuevas.

## Qué leer
- docs/design/menu.md › "Escena y script", "Fondo", "Decoración" y "Opciones" (el botón "Borrar progreso")
- docs/design/ui.md › "Barras: tablet física", "Botones" y "OverlayScreen" (`OverlayFrame`)
- docs/design/art.md
- docs/design/flujo.md › "Cambio de escena" y "Salir al menú"
- scenes/MainMenu.tscn (nodos de fondo y decoración) y scripts/screens/MainMenu.gd › `_hyperspace_jump()`, `_transition()`
- scripts/screens/OptionsMenu.gd (botón de borrar progreso)

## Archivos que toca
- scenes/StartScreen.tscn (nuevo)
- scripts/screens/StartScreen.gd (nuevo)
- project.godot (`run/main_scene`)
- scripts/screens/MainMenu.gd (solo quitar `load_slot(1)`)
- scenes/OptionsMenu.tscn, scripts/screens/OptionsMenu.gd
- assets/ui/ (sprites nuevos si hacen falta)
- docs/design/menu.md, docs/DESIGN.md (flujo de pantallas y escena inicial)

## Cómo se prueba a mano
1. F5: sale el título con el espacio de fondo y "PULSA CUALQUIER TECLA" parpadeando.
2. Pulsar una tecla: el texto se va y entran las 3 ranuras. La 1 enseña el resumen del progreso migrado; las otras, "NUEVA PARTIDA".
3. Pulsar la cruz roja de la 1 y cancelar: no pasa nada. Entrar en la 2: efecto de entrada y luego el menú, con solo el nivel 1 desbloqueado.
4. Jugar un rato, cerrar y volver a abrir: la ranura 2 enseña fecha, horas y sector nuevos.
5. Borrar la 2 y confirmar: vuelve a "NUEVA PARTIDA".
