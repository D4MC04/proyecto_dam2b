# Tiempo de partida en el resumen

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
El resumen de victoria y derrota dice oleada, bajas, gastado y mejor torre, pero no cuánto ha durado la partida.

## Qué hay que hacer
- `RunStats` guarda la duración de la partida en segundos (`Level` ya suma `play_time` en `_process`; usar el tiempo de esta partida, no el global).
- `RunSummary` añade una fila "TIEMPO" con formato `m:ss`, debajo de GASTADO.
- Comprobar que la fila extra cabe en el panel.

## Archivos que toca
- scripts/level/RunStats.gd
- scripts/level/Level.gd
- scripts/level_ui/RunSummary.gd
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1 unos minutos y ganar o perder.
2. El resumen enseña "TIEMPO 3:12" (o lo que haya durado).
3. Reiniciar el nivel: el tiempo vuelve a empezar desde 0.
