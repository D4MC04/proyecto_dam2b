# La velocidad ×2 solo acelera el juego, no la interfaz

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El botón ×2 cambia `Engine.time_scale`, que acelera todo lo que va con `_process` o con tweens normales, también animaciones de la interfaz. El ×2 debería acelerar solo la partida (naves, torretas, oleadas, recargas), no la interfaz.

## Qué hay que hacer
- Revisar las animaciones de la interfaz del nivel que siguen `Engine.time_scale` y pasarlas a tiempo real: tweens con `set_ignore_time_scale()` (como ya hacen `BossAlert`, `WaveAnnouncer`, `RunSummary` y `VictoryScreen`) y `_process` con el `delta` deshecho (`delta / Engine.time_scale`, como `TutorialHints`). Candidatos vistos: `LevelIndicator` (fundido), `Sidebar` (golpe en la vida de la estación y parpadeo de INICIAR) y cualquier otro de `scripts/level_ui/` que anime con `_process` o tweens.
- Lo que es de la partida sigue el ×2: recargas de poderes (`PowerButton` enseña la recarga de `Powers`), temblor del mapa, portales, naves, torretas.
- El simulacro (`TutorialHints`) ya va en tiempo real.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "LevelUI" (velocidad ×2) y "Pestaña Oleadas"
- scripts/level_ui/LevelUI.gd › `set_state()`
- Grep de `create_tween()` y `func _process` en scripts/level_ui/

## Archivos que toca
- scripts/level_ui/LevelIndicator.gd, scripts/level_ui/Sidebar.gd y los que salgan del Grep
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar un nivel con ×2.
2. Las animaciones de la interfaz (parpadeo de INICIAR, golpe en la vida de la estación, fundido del indicador de nivel) van a la misma velocidad que a ×1.
3. Las naves, torretas y recargas sí van al doble.
