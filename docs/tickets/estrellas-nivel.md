# Estrellas por nivel según la vida de la estación

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Ganar un nivel siempre cuenta igual. Con estrellas se premia defender bien y hay motivos para repetir niveles. La nueva selección de nivel (ticket `radar-sectores`) las enseña.

## Qué hay que hacer
- Al ganar un nivel, calcular de 1 a 3 estrellas con la vida de la estación al acabar: 3 si no perdió vida (`health == max_health`), 2 si le queda más de la mitad, 1 si gana con menos.
- En `GameState`, guardar la mejor marca de cada nivel (por número de nivel) junto con el resto del progreso de la ranura (`_save()` / `load_slot()`; que se borre al borrar la ranura o reiniciar el progreso). Solo sube, nunca baja.
- Una función en `GameState` que devuelva las estrellas de un nivel (0 si no se ha ganado), para la selección de nivel.
- Llamarlo desde donde ya se registra la victoria en `Game.gd`.
- No enseñar las estrellas en ninguna pantalla todavía (eso lo hace el ticket `radar-sectores`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/flujo.md › "Victoria"
- scripts/autoloads/GameState.gd › `load_slot()`, `_save()`, `delete_slot()`, `complete_level()`, `register_win()`
- scripts/screens/Game.gd › donde llama a `GameState.complete_level()` y `register_win()`
- scripts/entities/Base.gd › `health`, `max_health`

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/Game.gd
- docs/design/flujo.md

## Cómo se prueba a mano
1. Ganar el nivel 1 sin que la estación pierda vida: se guardan 3 estrellas.
2. Repetirlo y ganarlo con menos de la mitad de vida: la marca sigue en 3.
3. Ganar el nivel 2 perdiendo algo de vida (con más de la mitad restante): 2 estrellas.
4. Salir del juego y volver a cargar la ranura: las marcas siguen (mirar el archivo de la ranura en `user://saves/`, hasta que exista el radar).
