# Intro corta al empezar una partida nueva

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al abrir una ranura nueva se entra de golpe en el simulacro. Unos diálogos cortos de NOVA antes del salto dan contexto (quién eres, qué defiendes) sin frenar al jugador.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario los textos propuestos (3-4 líneas cortas de NOVA) y ajustarlos a lo que diga.
- En una ranura nueva (`GameState.tutorial_done` false), antes del simulacro: diálogos cortos de NOVA (mismo estilo que el recuadro del simulacro, letra a letra) sobre el espacio del menú.
- No se pueden saltar, pero cada clic o tecla completa el texto o pasa al siguiente: machacando se pasan en unos 3 s.
- Después, el salto al hiperespacio de siempre (`MainMenu._hyperspace_jump`) y el simulacro. Lo saltable de verdad es el simulacro (su botón "Saltar"), no estos diálogos.
- Engancharlo donde `tutorial-nivel-prueba` lanza el simulacro al entrar en una ranura nueva (`MainMenu.open_simulation()`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Pantalla de inicio" y "Salto al hiperespacio"
- docs/design/ui.md › "Tutorial del simulacro" (estilo de NOVA)
- scripts/screens/MainMenu.gd › `open_simulation()`, `_open_level()`, `_hyperspace_jump()`

## Archivos que toca
- scripts/screens/MainMenu.gd, scenes/MainMenu.tscn
- scripts/main_menu/IntroDialog.gd (nuevo)
- translations/textos.csv
- docs/design/menu.md

## Cómo se prueba a mano
1. Empezar una partida en una ranura vacía: salen los diálogos de NOVA; machacando clic se pasan rápido.
2. Después, el salto al hiperespacio y el simulacro.
3. En una ranura que ya hizo o saltó el simulacro no sale nada de esto.
