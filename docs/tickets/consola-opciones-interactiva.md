# Consola de opciones interactiva

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
En el menú, al pulsar la consola de opciones sale un cuadro con todos los botones encima de la oficina y no pega con el resto. La consola tiene faders, pomos e interruptores dibujados: que sean ellos las opciones y se toquen de verdad.

## Qué hay que hacer
- **Zoom:** al pulsar `OptionsConsole`, la vista se acerca a la consola como la mesa del radar (`_open_sectors` / `_tween_zoom`), en vez de `_open_panel(options_menu)`. Generalizar el zoom de `MainMenu` para que valga para más de un objeto (lo reutilizará el ticket `navedex-en-tablet`). Al terminar el zoom, la consola de cerca ocupa la vista y se pinta a resolución completa (no el PNG pequeño estirado), con el mismo estilo de metal.
- **Faders (3):** General, Música y Efectos (`master_volume`, `music_volume`, `sfx_volume`). Se arrastran con el ratón en vertical (pasos de 0,05). Los vúmetros de al lado se mueven con el nivel real del bus (`AudioServer.get_bus_peak_volume_left_db`); con `muted`, se apagan.
- **Botón Silenciar:** un pulsador grande (`muted`), encendido en rojo cuando está activo.
- **Pomos (3):** se giran con clic (y con la rueda): Idioma (posiciones ES / EN, `language`), Pantalla completa (`fullscreen`) y VSync (`vsync`), con dos posiciones marcadas ON / OFF.
- **Interruptores (5):** palancas que suben (ON) y bajan (OFF): Mostrar FPS, Rango de torretas, Números de daño, Temblor de pantalla y Pausar sin foco. Cambiar el número de interruptores de la consola pequeña de 4 a 5 en `gen_center.py` › `build_options` y que reflejen el valor real de `Settings` (ya no "el tercero bajado" fijo).
- **Pantallita LCD:** con el ratón encima de un control, muestra su nombre y valor (por ejemplo "MÚSICA 40%", "IDIOMA ES"), con las claves de traducción que ya usa `OptionsMenu`; sin ratón encima, un texto en espera.
- Cada cambio llama a `Settings.set_value` y se ve al momento (el idioma, en toda la consola).
- **Salir:** Escape, clic fuera de la consola o un botón "Volver" dibujado en la consola: hace el zoom inverso.
- La consola pequeña de la oficina (sin zoom) enseña la posición real de faders, pomos e interruptores.
- `OptionsMenu` (el cuadro) se queda tal cual para el menú de pausa; en el menú principal ya no se abre.
- Volver a generar con `python scripts/tools/office/make_office.py`; ni los PNG ni `OfficeLayout.gd` se editan a mano.
- Va antes que `oficina-vista-central` (de David): ese ticket se adapta a este después.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Oficina", "Comportamiento" (Mesa del radar) y "Opciones" (con "Settings")
- docs/design/art.md › "Oficina del menú"
- scripts/screens/MainMenu.gd › `_open_sectors()`, `_close_sectors()`, `_tween_zoom()`, `_set_radar_zoom()`, `_on_options_console_pressed()`, `_close_panel()`
- scripts/main_menu/RadarConsole.gd › `set_zoom()`
- scripts/main_menu/OptionsConsole.gd
- scripts/tools/office/gen_center.py › `build_options()`
- scripts/screens/OptionsMenu.gd (claves de texto de cada opción)

## Archivos que toca
- scripts/screens/MainMenu.gd
- scenes/MainMenu.tscn
- scripts/main_menu/OptionsConsole.gd
- scripts/tools/office/gen_center.py (y lo que genera: PNG de la oficina y `OfficeLayout.gd`)
- docs/design/menu.md

## Cómo se prueba a mano
1. F5, entrar en una ranura: en la oficina, la consola de la derecha enseña los faders, pomos y palancas en sus valores actuales.
2. Pulsar la consola: la vista se acerca y la consola llena la pantalla, nítida.
3. Pasar el ratón por cada control: la pantallita dice qué es y su valor.
4. Bajar el fader de Música: la música baja y su vúmetro también. Pulsar Silenciar: se apaga todo y los vúmetros.
5. Girar el pomo de Idioma a EN: los textos cambian al momento.
6. Subir la palanca de Números de daño, salir con Escape y jugar un nivel: salen los números. En la pausa → Opciones, el cuadro de siempre tiene los mismos valores.
