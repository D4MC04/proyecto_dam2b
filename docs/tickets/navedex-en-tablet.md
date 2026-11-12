# Navedex dentro de la tablet

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
La Navedex sale como un panel suelto encima de la oficina y no parece la tablet que se pulsa. Que la ficha salga dentro de la pantalla de la tablet y se vea más viva.

## Qué hay que hacer
- **Zoom:** al pulsar `ArchiveTablet`, la vista se acerca a la tablet con el zoom generalizado del ticket `consola-opciones-interactiva` (en vez de `_open_panel(navedex)`). Al acabar, la Navedex queda dentro de la pantalla de la tablet, con el marco de metal y las escuadras alrededor (como Sectores en la mesa del radar). Escape o "Volver" hacen el zoom inverso.
- **Holograma:** la nave del detalle sale en holograma cian girando, con una línea de escaneo que baja, como en la tablet de la oficina.
- **Stats en barras:** cada stat del detalle con una barra además del número, para comparar de un vistazo.
- **No vistas:** las naves que aún no se han visto salen en la cuadrícula como silueta oscura, y en el detalle con el nombre "???" y sin descripción ni stats.
- **Pestañas:** NAVES / TORRETAS como dos botones físicos de la tablet (en el marco) en vez de la `TabBar`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Navedex", "Oficina" (fila de `ArchiveTablet`) y "Comportamiento" (Mesa del radar)
- scripts/screens/Navedex.gd
- scripts/main_menu/ArchiveTablet.gd › `_draw_object()` (holograma y escaneo)
- scripts/screens/MainMenu.gd › el zoom generalizado y `_on_archive_tablet_pressed()`

## Archivos que toca
- scripts/screens/Navedex.gd
- scenes/Navedex.tscn
- scripts/main_menu/ArchiveTablet.gd
- scripts/screens/MainMenu.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. F5, entrar en una ranura y pulsar la tablet: la vista se acerca y la Navedex sale dentro de la pantalla de la tablet.
2. Elegir una nave vista: holograma girando con escaneo y stats con barras.
3. Una nave que no se ha visto nunca sale como silueta y "???".
4. Pulsar el botón TORRETAS del marco: cambia a torretas; las flechas de mejora siguen funcionando.
5. Escape: la vista vuelve a la oficina.
