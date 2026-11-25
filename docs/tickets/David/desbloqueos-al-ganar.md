# Desbloqueos un sector antes y en la pantalla de victoria

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El primer desbloqueo debería llegar al acabar el tutorial. Y los desbloqueos se ven mejor justo al ganar el sector que al volver a la oficina.

## Qué hay que hacer
- **Adelantar los desbloqueos un sector.** Lo que hoy se desbloquea al ganar el sector N pasa a desbloquearse al ganar el sector N-1. El tutorial (nivel de emergencia, sector 0) hace el primer desbloqueo: lo que hoy da ganar el sector 1. Hoy `GameState.complete_level(number)` da `GameData.turret_order[number]` y el sector siguiente, y el nivel de emergencia no desbloquea nada (`Game._on_level_won`, número 0).
  - Que cada sector ofrezca las torretas ya desbloqueadas con el nuevo orden: revisar las listas de torretas de `resources/level_data/*.tres` y lo que diga "La torreta N sale en el nivel N".
- **Enseñar los desbloqueos en la pantalla de victoria, no en la oficina.** Al ganar, `VictoryScreen` mantiene su contorno (el marco de "sector asegurado") y solo cambia el contenido para enseñar el desbloqueo o los desbloqueos, uno tras otro.
  - El botón que hoy dice "Oficina" dice "Siguiente" mientras queden cosas por ver: primero la victoria con sus estrellas, luego cada desbloqueo. Cuando ya no queda nada, dice "Oficina" y lleva a la oficina.
  - Sin desbloqueos (un sector repetido, el último), la victoria queda como ahora.
  - La oficina deja de enseñar `UnlockNotice` al volver de un sector. Decidir qué pasa con la cola `GameState.pending_unlocks` (y su guardado) y con `UnlockNotice`, si ya no se usa en ningún sitio; se puede reutilizar su contenido dentro de la victoria.
- Mirar si el nivel de emergencia tiene su propia salida tras ganar (va al tutorial de la oficina) y que también enseñe ahí su desbloqueo.

## Qué leer
- docs/design/flujo.md › "Victoria"
- docs/design/menu.md › "Aviso de desbloqueos"
- docs/design/torretas.md › lo que hable del orden de desbloqueo (sacarlo con Grep "desbloq")
- scripts/autoloads/GameState.gd › `complete_level()`, `queue_unlock()`, `take_unlocks()`
- scripts/screens/Game.gd › `_on_level_won()`
- scripts/level_ui/VictoryScreen.gd y scripts/level_ui/LevelUI.gd › `show_victory_stars()`
- scripts/screens/UnlockNotice.gd › `show_unlocks()` y scripts/resources/UnlockInfo.gd
- scripts/screens/MainMenu.gd › donde llama a `show_unlocks`

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/Game.gd
- scripts/level_ui/VictoryScreen.gd y scenes/level_ui/VictoryScreen.tscn
- scripts/level_ui/LevelUI.gd
- scripts/screens/MainMenu.gd (y UnlockNotice si se reutiliza o se quita)
- resources/level_data/*.tres (torretas de cada sector)
- translations/textos.csv (si hace falta "Siguiente")
- docs/design/flujo.md, docs/design/menu.md, docs/design/torretas.md

## Cómo se prueba a mano
1. Partida nueva y jugar el tutorial hasta ganarlo: debería salir el primer desbloqueo (lo que antes daba el sector 1), con "Siguiente" hasta el último y "Oficina" al final.
2. Ganar el sector 1: la victoria con sus estrellas y "Siguiente"; después, en el mismo marco, cada desbloqueo; el último paso, "Oficina".
3. Al volver a la oficina no debería salir ningún aviso de desbloqueo.
4. Repetir un sector ya ganado: la victoria sale como ahora, con "Oficina" directamente.
