# Llamada de socorro al empezar una partida nueva

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al abrir una ranura nueva se entra de golpe en el nivel de emergencia. La partida tiene que empezar con una llamada: desde la estación (NOVA) o desde el mando que te envía piden apoyo urgente para la base atacada, y por eso saltas directo a defenderla antes de ver tu oficina. Da contexto sin frenar al jugador.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario los textos propuestos (3-4 líneas cortas de la llamada) y quién habla (NOVA desde la estación, el mando o los dos), y ajustarlos a lo que diga.
- En una ranura nueva (`GameState.tutorial_done` false), antes del nivel de emergencia: la llamada de socorro, en diálogos cortos (mismo estilo que el recuadro de NOVA del nivel de emergencia: retrato enmarcado, nombre grande, 2 líneas por página y flecha para seguir) sobre el espacio del menú.
- No se pueden saltar, pero cada clic o tecla completa el texto o pasa al siguiente: machacando se pasan en unos 3 s.
- Después, el salto al hiperespacio de siempre (`MainMenu._hyperspace_jump`) y el nivel de emergencia. Lo saltable de verdad es el nivel de emergencia (su botón "Saltar"), no estos diálogos.
- Engancharlo donde `tutorial-nivel-prueba` lanza el nivel de emergencia al entrar en una ranura nueva (`MainMenu.open_emergency()`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Pantalla de inicio" y "Salto al hiperespacio"
- docs/design/ui.md › "Tutorial del nivel de emergencia" (estilo de NOVA)
- scripts/screens/MainMenu.gd › `open_emergency()`, `_open_level()`, `_hyperspace_jump()`

## Archivos que toca
- scripts/screens/MainMenu.gd, scenes/MainMenu.tscn
- scripts/main_menu/IntroDialog.gd (nuevo)
- translations/textos.csv
- docs/design/menu.md

## Cómo se prueba a mano
1. Empezar una partida en una ranura vacía: salen los diálogos de NOVA; machacando clic se pasan rápido.
2. Después, el salto al hiperespacio y el nivel de emergencia.
3. En una ranura que ya hizo o saltó el nivel de emergencia no sale nada de esto.
