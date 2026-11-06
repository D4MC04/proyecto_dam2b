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
- Primera fase del tutorial: en una partida nueva, el guía (NOVA, mismo estilo que `TutorialHints`) enseña la oficina: girar la silla, la mesa de sectores, la tablet (archivo), las opciones, las stats, la vitrina y la puerta.
- Al acabar, lleva a la segunda fase: el nivel de prueba del ticket `tutorial-nivel-prueba`.
- Se puede saltar, y no vuelve a salir en esa ranura una vez hecho o saltado.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Oficina" y "Comportamiento"
- docs/design/ui.md › "Tutorial del nivel 1" (estilo del guía)
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
1. Empezar una partida en una ranura vacía: en la oficina sale NOVA y enseña cada objeto.
2. Al acabar, lleva al nivel de prueba.
3. Volver a la oficina: el tutorial no vuelve a salir. "Saltar" también lo da por hecho.
