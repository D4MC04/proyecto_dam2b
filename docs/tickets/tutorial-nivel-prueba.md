# Tutorial de juego en un nivel de prueba

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El tutorial va metido en el nivel 1. Con un nivel o fase de prueba propio, el jugador aprende a jugar antes de empezar la campaña y el nivel 1 queda limpio.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario cómo es el tutorial ahora (pasos de "Tutorial del nivel 1") y preguntarle qué mejoras quiere. Hacer esas.
- Llevar el tutorial de juego a un nivel o fase de prueba propio, fuera de los 10 sectores, con un mapa generado por script como los demás.
- El nivel 1 deja de tener tutorial.
- Es la segunda fase del tutorial: la primera es la de la oficina (ticket `tutorial-oficina`), que acabará llevando a este nivel. Dejar una forma sencilla de lanzarlo (una función o señal) para que ese ticket lo use.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Tutorial del nivel 1"
- docs/design/niveles.md (cómo se generan los mapas y oleadas)
- scripts/level_ui/TutorialHints.gd
- scripts/level_ui/LevelUI.gd › `setup()`

## Archivos que toca
- scripts/level_ui/TutorialHints.gd y scenes/level_ui/TutorialHints.tscn
- scripts/level_ui/LevelUI.gd
- scenes/GameData.tscn
- resources/level_data/ (nivel de prueba nuevo) y su mapa generado
- scripts/tools/make_waves.gd (si el nivel de prueba lleva oleadas propias)
- translations/textos.csv
- docs/design/ui.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Lanzar el nivel de prueba: sale el tutorial con las mejoras pedidas.
2. Jugar el nivel 1: ya no sale el tutorial.
