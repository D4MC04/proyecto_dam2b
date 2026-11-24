# Pantallas de victoria y derrota mejoradas, sin "Siguiente sector"

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Desde la victoria se puede saltar directamente al siguiente sector, pero la idea es que el jugador pase siempre por la oficina entre sectores. Además, los datos del resumen de victoria y derrota son bastante arbitrarios y algunos no le importan a nadie.

## Qué hay que hacer
- Victoria: quitar la opción "Siguiente sector" (`NEXT_LEVEL`); desde la victoria se vuelve a la oficina. Quitar también lo que solo servía para ella (`LevelUI.Action.NEXT_LEVEL`, su rama en `Game.gd` y `set_option_visible` de `LevelUI.setup`) si nadie más lo usa.
- Repensar los datos del resumen (`RunSummary`, `RunStats`) en victoria y derrota: quedarse con los que dicen algo útil al jugador (cómo de bien lo hizo, qué le funcionó, qué le falló, en derrota qué le mató o cuánto le faltó) y quitar los que no aportan. Proponer la lista al usuario antes de implementarla.
- El ticket `resumen-tiempo` (tiempo de partida en el resumen) se solapa: decidir con el usuario si el tiempo entra aquí; si entra, borrar `docs/tickets/resumen-tiempo.md`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "GameOverScreen", "RunSummary" y "VictoryScreen"
- docs/design/flujo.md › "Acciones de la UI", "Derrota", "Victoria" y "Salir al menú"
- docs/design/niveles.md › `RunStats`
- scripts/level_ui/LevelUI.gd › `Action`, `setup()` (`NEXT_LEVEL`), `_request_action()`
- scripts/screens/Game.gd › rama `NEXT_LEVEL`
- scripts/level_ui/RunSummary.gd y el script de `RunStats`
- docs/tickets/resumen-tiempo.md

## Archivos que toca
- scripts/level_ui/VictoryScreen.gd, scripts/level_ui/GameOverScreen.gd, scripts/level_ui/RunSummary.gd y sus escenas
- scripts/level_ui/LevelUI.gd, scripts/level_ui/OverlayScreen.gd, scripts/screens/Game.gd
- `RunStats` y donde se rellena (Level)
- docs/design/ui.md, docs/design/flujo.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Ganar el nivel 1: la victoria no ofrece "Siguiente sector"; "Menú" lleva a la oficina.
2. El resumen de victoria enseña los datos nuevos, con sentido para lo jugado.
3. Perder un nivel: el resumen de derrota enseña los datos nuevos.
