# Oleadas mucho más difíciles sin romper la economía

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El early game es algo fácil y a partir de la oleada 5 se puede dejar de construir y ganar igual. Pero meter más naves no basta: dan más dinero, se construye más y vuelve a pasar lo mismo.

## Qué hay que hacer
- Hacer después de `balance-torretas` (con sus stats nuevos).
- Subir algo la dificultad del early game y mucho la del late game en todos los niveles, retocando la tabla `LEVELS` de `scripts/tools/make_waves.gd` y regenerando las oleadas.
- Que la dificultad crezca más rápido que el dinero que dan las oleadas. Palancas a valorar (elegir y justificar):
  - `health_multiplier` más alto y con más pendiente (la recompensa no sube con él: más dificultad sin más dinero).
  - Menos naves pero más duras, más rápidas o más juntas (separación, solape de caminos), en vez de más naves.
  - Crecimiento del presupuesto y mezcla de tipos por oleada.
  - Si hace falta, recompensas (`reward`), `PERFECT_WAVE_BONUS` o `starting_money`, contándolo en el resumen.
- Estimar por nivel y oleada el dinero acumulado frente a la vida total que llega (con el multiplicador) y el DPS necesario con las torretas del nivel. Objetivo: en cada oleada hay que seguir construyendo o mejorando; sin hacerlo, se pierde antes del final.
- Actualizar docs/design/niveles.md ("Generador de oleadas" y la tabla de niveles) y enemigos.md si cambian recompensas.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "LevelState", "Datos de nivel" y "Generador de oleadas"
- docs/design/enemigos.md › "Datos"
- docs/design/torretas.md › "Datos" (ya con el balance nuevo)
- scripts/tools/make_waves.gd › tabla `LEVELS` y cálculo de presupuesto, tiempos y vida

## Archivos que toca
- scripts/tools/make_waves.gd
- resources/wave_data/ (regenerados)
- scenes/GameData.tscn (solo la línea `waves` del nivel 5, la reescribe el script)
- resources/enemy_data/ y resources/level_data/ (solo si cambian recompensas o dinero inicial)
- scripts/level/LevelState.gd (solo si cambia `PERFECT_WAVE_BONUS`)
- docs/design/niveles.md
- docs/design/enemigos.md (si cambian recompensas)

## Cómo se prueba a mano
1. Jugar el nivel 2: las primeras oleadas piden algo más de cuidado.
2. Jugar el nivel 5 y dejar de construir en la oleada 5: se pierde antes del final.
3. Jugar el nivel 9 construyendo y mejorando bien: se gana, pero cuesta.
