# Acercarse a la mesa del radar al abrir Sectores

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La mesa del radar de la oficina enseña 6 ecos de adorno, no el radar de verdad, y al pulsarla la pantalla de Sectores aparece con un fundido. Tiene que sentirse que te acercas a la mesa y entras en su pantalla.

## Qué hay que hacer
- **La mesa enseña el radar de verdad:** la pantalla de `RadarConsole` pasa a mostrar lo mismo que `SectorRadar`, chafado por la inclinación de la mesa: un contacto por nivel en su `radar_distance` y `radar_bearing`, solo los visibles según el progreso, la estación en el centro y la niebla fuera del alcance. Sustituye a los 6 ecos fijos de `BLIPS`. El barrido sigue como ahora.
- **Animación de acercamiento al pulsar la mesa:** la oficina hace zoom hacia la pantalla de la mesa (de 0,6 a 0,8 s, con suavizado de entrada y salida) hasta que la pantalla llena la vista. Mientras dura, el trapecio se va enderezando hasta coincidir con el radar de `LevelSelectionScreen`. Después aparecen el resto de la pantalla de Sectores (cabecera, ficha y botón "Volver") y el radar real, sin salto entre el último fotograma del zoom y el radar.
- **Al volver**, con "Volver" o Escape, se hace la animación inversa: el radar se aleja y se inclina hasta quedar otra vez en la mesa, en la vista central.
- Mientras dura la animación no se puede girar la silla ni pulsar otros objetos.
- Si el menú abre con la selección de nivel ya abierta (`start_on_level_selection`), se abre directamente, sin animación.
- Los demás paneles (tablet, vitrina, opciones...) siguen con su fundido.
- No cambiar el modo corrupto del jefe (ticket `radar-corrupto-jefe`) ni las mejoras de la pantalla de sectores (ticket `pantalla-sectores-mejoras`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Oficina" (tabla de objetos, fila de `RadarConsole`), "Comportamiento" y "Radar de sectores"
- scripts/main_menu/RadarConsole.gd › `_ready()`, `_draw_blips()`, `_radar_to_local()`
- scripts/screens/MainMenu.gd › `_open_panel()`, `_close_panel()`, `_fade_panel()`, `_on_radar_console_pressed()`, `_turn()`
- scripts/level_ui/SectorRadar.gd › `refresh()`, `_compute_range()`, `_contact_position()`, `_draw_fog()`, `_draw_station()`
- resources/shaders/office_radar.gdshader

## Archivos que toca
- scripts/main_menu/RadarConsole.gd
- scripts/screens/MainMenu.gd
- resources/shaders/office_radar.gdshader
- scenes/MainMenu.tscn
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir el juego (F5) y quedarse en la vista central de la oficina.
2. Mirar la mesa del radar: deberían verse los contactos de los niveles desbloqueados en sus sitios, la estación en el centro y la niebla, no los 6 ecos rojos fijos.
3. Pulsar la mesa: la vista se acerca a la pantalla, se endereza y pasa al radar de Sectores sin salto. Después aparecen la ficha y "Volver".
4. Pulsar "Volver" (o Escape): el radar se aleja y vuelve a quedar en la mesa.
5. Ganar un nivel y volver al menú: Sectores se abre directamente, sin animación.
