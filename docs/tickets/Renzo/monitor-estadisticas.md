# Monitor de estadísticas con datos reales y zoom

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El monitor de stats de la oficina solo hace una animación de adorno (barras, línea y anillo sin datos), y al pulsarlo sale un panel plano con cinco líneas de texto. Se quiere que el monitor enseñe las estadísticas de verdad y que al pulsarlo la cámara se acerque a él para verlas en detalle, como la mesa del radar, la consola de opciones o la Navedex.

## Qué hay que hacer
- **Monitor en la oficina (`CombatScoreboard`):** que sus gráficos salgan de los datos reales de `GameState` en vez de ser de adorno, y se sigan moviendo (que suban hasta su valor, latan...):
  - Las 5 fichas de abajo enseñan su número real (naves destruidas `stats.kills`, victorias `stats.wins`, torretas `stats.turrets`, oleadas perfectas `stats.perfect_waves`, naves vistas).
  - Las barras: torretas más construidas (`stats.built_<torreta>`), normalizadas a la más alta.
  - El anillo: reparto de algo real (por ejemplo, torretas construidas por tipo o kills/oleadas/poderes) con su leyenda.
  - Solo con datos que ya guarda `GameState`: no añadir contadores nuevos.
- **Zoom al pulsarlo:** en vez de `_open_panel(stats_panel)`, `_zoom_in` / `_zoom_out` hasta el monitor, como `_set_options_zoom` y `_set_tablet_zoom`. Ojo: el zoom ahora enfoca puntos de la vista central (`_zoom_office`); el monitor está en la vista izquierda, así que hay que adaptarlo a esa vista.
- **Monitor de cerca (nuevo, sustituye a `StatsScreen`):** desde `CLOSE_UP_FADE_START` aparece encima con un fundido, con el mismo marco del monitor, y dentro las estadísticas a fondo:
  - Las cinco de ahora (kills, gastado, tiempo, favorita, sectores ganados) más torretas, poderes y oleadas perfectas.
  - Gráfico de barras con todas las torretas construidas (`built_<torreta>`) con su nombre/icono.
  - Los mismos gráficos que el monitor de lejos pero grandes y con números.
  - Escape, "Volver" o clic fuera hacen el zoom inverso.
- Textos nuevos traducidos (claves en la tabla de traducciones como las `STATS_*`).
- Actualizar docs/design/menu.md (`CombatScoreboard`, `StatsScreen`, "Zoom a un objeto").

## Qué leer
- docs/design/menu.md › "Oficina" (tabla de objetos: `CombatScoreboard`), "Comportamiento" › "Zoom a un objeto" y "Consola de opciones", y `StatsScreen`
- docs/design/art.md › "Oficina del menú"
- scripts/screens/MainMenu.gd › `_on_combat_scoreboard_pressed()`, `_zoom_in()`, `_zoom_out()`, `_zoom_office()`, `_set_options_zoom()`
- scripts/main_menu/CombatScoreboard.gd
- scripts/autoloads/GameState.gd › `stats`, `play_time`, `favorite_turret()`

## Archivos que toca
- scripts/main_menu/CombatScoreboard.gd
- scripts/main_menu/StatsCloseUp.gd (nuevo)
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- archivo de traducciones (claves `STATS_*`)
- docs/design/menu.md

## Cómo se prueba a mano
1. Entrar con una partida que ya tenga niveles jugados y girar a la izquierda.
2. El monitor de stats debería enseñar barras, anillo y fichas con los números reales, animados.
3. Pulsarlo: la cámara se acerca al monitor y aparece la vista de cerca con todas las estadísticas y gráficos.
4. Escape o "Volver": la cámara se aleja y se vuelve a la oficina.
