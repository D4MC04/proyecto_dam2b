# Tutorial de la oficina

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Al empezar una partida, el jugador cae en la oficina sin saber qué es cada objeto. El tutorial tiene que orientarle desde el principio, no solo dentro de los niveles.

## Qué hay que hacer
- **Antes de tocar nada**, preguntar al usuario cómo quiere el tutorial de la oficina (qué enseñar y en qué orden) y hacerlo así.
- Última fase del tutorial. Orden de una partida nueva: intro (`intro-partida`) → nivel de emergencia (`tutorial-nivel-prueba`) → oficina. Sale al llegar a la oficina por primera vez después del nivel de emergencia (hecho o saltado).
- Si el nivel de emergencia se ganó (sale su pantalla de victoria y se vuelve con "Menú"), NOVA empieza felicitando por superarlo y de ahí pasa al tutorial de la oficina; si se saltó o se abandonó, empieza sin felicitar. Hay que guardar en `GameState` cómo acabó (ahora `tutorial_done` solo dice que ya se pasó por él; `Game._quit_to_menu` lo marca).
- El guía (NOVA, mismo estilo y foco que el nivel de emergencia: se oscurece todo menos lo que se señala y su recuadro) enseña solo lo necesario, de forma inmersiva. Propuesta para enseñar al usuario: que la oficina tiene varias vistas girando la silla ("echa un vistazo alrededor"), la mesa de sectores (donde se juega) y las opciones. Logros, vitrina, stats y archivo no se explican (como mucho, "lo demás, explóralo tú").
- Se puede saltar, y no vuelve a salir en esa ranura una vez hecho o saltado.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Oficina" y "Comportamiento"
- docs/design/ui.md › "Tutorial del nivel de emergencia" (estilo del guía y foco)
- scripts/level_ui/TutorialHints.gd
- scripts/autoloads/GameState.gd › `tutorial_done`, `complete_tutorial()`

## Archivos que toca
- scripts/main_menu/OfficeTutorial.gd (nuevo)
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scripts/autoloads/GameState.gd
- translations/textos.csv
- docs/design/menu.md, docs/design/ui.md

## Cómo se prueba a mano
1. Empezar una partida en una ranura vacía y acabar o saltar el nivel de emergencia: en la oficina sale NOVA y enseña lo acordado.
2. Volver a la oficina: el tutorial no vuelve a salir. "Saltar" también lo da por hecho.
