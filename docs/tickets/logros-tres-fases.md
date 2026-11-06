# Logros con tres fases: bronce, plata y oro

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Los logros se consiguen una vez y ya. Con fases incrementales (por ejemplo, eliminar 1000, 3000 y 5000 enemigos) dan algo que perseguir durante toda la partida.

## Qué hay que hacer
- Cada logro tiene **3 fases** (bronce, plata y oro) con metas crecientes, o **1 sola fase**, que ya se consigue en oro. No hay logros de 2 fases.
- Repasar los 12 logros de `GameState.ACHIEVEMENTS`: los de contador (bajas, victorias, torretas, oleadas perfectas, naves vistas...) pasan a 3 fases con metas razonables (fusionar los que se solapan, como `kills_100` y `kills_1000`, en uno de 3 fases); los que solo pueden pasar una vez (primera victoria, nivel intacto...) se quedan en 1 fase de oro.
- Cada fase usa el mismo icono, pero la medalla y el icono cambian de color: bronce, plata y oro.
- Guardar la fase conseguida de cada logro en la ranura y migrar las ranuras viejas (los logros ya conseguidos cuentan para la fase que les toque).
- El aviso `LOGRO: nombre` dice qué fase se ha conseguido.
- El contador "X/12" de las ranuras (`get_slot_summary`) sigue teniendo sentido (por ejemplo, fases conseguidas sobre el total).
- Antes de implementar, enseñar al usuario la lista de logros con sus fases y metas y esperar su visto bueno.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Logros" y la fila `MedalCase` de "Oficina"
- scripts/autoloads/GameState.gd › `ACHIEVEMENTS`, `_is_done()`, `_check_achievements()`, `get_slot_summary()`, `load_slot()`
- scripts/main_menu/MedalCase.gd
- scripts/screens/AchievementsScreen.gd › `_make_row()`

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/main_menu/MedalCase.gd
- scripts/screens/AchievementsScreen.gd
- translations/textos.csv
- docs/design/menu.md

## Cómo se prueba a mano
1. Empezar una partida nueva y matar naves en el nivel 1: al llegar a la primera meta sale el aviso con la fase de bronce.
2. En la vitrina, la medalla de ese logro sale en bronce; las de una fase, al conseguirlas, en oro.
3. Cargar una ranura vieja con logros: siguen conseguidos en la fase que les toca.
