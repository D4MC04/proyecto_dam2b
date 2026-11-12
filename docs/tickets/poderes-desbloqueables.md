# Poderes desbloqueables, de pago y con su mini tutorial

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ahora los tres poderes (meteorito, congelar y rayo orbital) están desde el primer nivel, gratis y con recargas largas. Desbloquearlos poco a poco y que cuesten dinero los hace una decisión y no satura al jugador nuevo. El nivel de emergencia (`tutorial-nivel-prueba`) ya no los enseña.

## Qué hay que hacer
- **Antes de tocar nada**, preguntar al usuario: en qué nivel se desbloquea cada poder, cuánto cuesta usarlo y qué recarga nueva lleva.
- Los poderes no están disponibles desde el principio: cada uno se desbloquea en su nivel (se guarda en `GameState`). Los bloqueados no se ven o salen bloqueados en la fila de poderes, según diga el usuario.
- Usar un poder cuesta dinero (`LevelState.spend_money`); sin dinero suficiente no se lanza.
- Recargas más cortas que las actuales (45, 60 y 75 s).
- Mini tutorial al desbloquear el primero: NOVA (mismo estilo y foco que el nivel de emergencia) explica qué son los poderes y cómo se usan (botón o Q/E/R, apuntar, recarga y coste).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Poderes"
- docs/design/ui.md › "Poderes" y "Tutorial del nivel de emergencia"
- scripts/level/Powers.gd
- scripts/level_ui/LevelUI.gd › `_use_power()`, `setup_powers()`
- scripts/level_ui/TutorialHints.gd

## Archivos que toca
- scripts/level/Powers.gd
- scripts/level_ui/LevelUI.gd, scripts/level_ui/PowerButton.gd
- scripts/level_ui/TutorialHints.gd (o un script nuevo para el mini tutorial)
- scripts/autoloads/GameState.gd
- translations/textos.csv
- docs/design/niveles.md, docs/design/ui.md

## Cómo se prueba a mano
1. Partida nueva, nivel 1: no hay poderes (o salen bloqueados).
2. Ganar hasta el nivel que desbloquea el primero: sale NOVA y explica los poderes.
3. Usar uno: cuesta dinero y la recarga es más corta. Sin dinero no se lanza.
