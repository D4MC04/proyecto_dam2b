# Tutorial: solo se puede hacer lo que pide el paso

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Durante el tutorial del nivel 1 el jugador puede hacer cualquier cosa (poderes, velocidad, vender…) y saltarse o romper lo que el guía le está enseñando.

## Qué hay que hacer
- Mientras el tutorial está activo, cada paso solo deja hacer lo que pide. Todo lo demás no responde, ni con el ratón ni con el teclado:
  - Elegir torreta: botones de la rejilla de torretas y teclas `select_turret_N`.
  - Colocarla: clic en una plataforma libre, y clic derecho para soltarla (ya vuelve al paso anterior).
  - Lanzar la oleada: pestaña Oleadas y Siguiente oleada (botón o `next_wave`).
  - Mientras dura la oleada 1: ninguna acción.
  - Ver la ficha: clic derecho para soltar la torreta y clic en una torreta del mapa.
  - Venta y mejora: solo "Entendido" (Vender y Mejorar no responden).
  - Poderes: Q y E y sus botones en la ficha (el orbital no).
  - Despedida: todo libre.
- Siempre se pueden usar "Saltar" y la pausa (Escape). Al saltar o acabar el tutorial, todo vuelve a funcionar.
- `TutorialHints` dice qué se permite en el paso actual, y los sitios donde entra cada acción le preguntan antes de hacerla: AUTO, velocidad, flechas de oleadas, poderes, vender, mejorar, construir y seleccionar torretas del mapa.
- Fuera del nivel 1, o con el tutorial ya hecho, nada cambia.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Tutorial del nivel 1"
- scripts/level_ui/TutorialHints.gd › `enum Step`, `start()`, `_show_step()`, `_finish()`
- scripts/level_ui/LevelUI.gd › `_unhandled_input()`, `_use_power()` y donde llama a `tutorial_hints.start()`
- scripts/level/BuildManager.gd › `_unhandled_input()`
- scripts/level/Powers.gd › `_unhandled_input()`
- scripts/level_ui/Sidebar.gd › conexiones de `next_wave_button` y las flechas de oleada
- scripts/level_ui/TurretActions.gd › `upgrade_button` y `sell_button`

## Archivos que toca
- scripts/level_ui/TutorialHints.gd
- scripts/level_ui/LevelUI.gd
- scripts/level/BuildManager.gd
- scripts/level/Powers.gd
- scripts/level_ui/Sidebar.gd
- scripts/level_ui/TurretActions.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Opciones → Borrar progreso y jugar el nivel 1 (sale el tutorial).
2. En el primer paso, pulsar Espacio, Q, E, la velocidad y la pestaña Oleadas: no pasa nada. Elegir una torreta sí funciona.
3. Seguir los pasos: en cada uno solo responde lo que pide el guía. Escape abre la pausa siempre.
4. En el paso de venta y mejora, Vender y Mejorar no hacen nada hasta pulsar "Entendido".
5. Pulsar "Saltar" (o acabar el tutorial): todo vuelve a responder.
