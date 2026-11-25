# La consola de opciones de la oficina igual que la de cerca

Estado: pospuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La consola de opciones que se ve en la oficina (`OptionsConsole`) y la de cerca (`OptionsCloseUp`) no parecen la misma: desde la oficina los tres pomos no parecen ruedas, falta el pulsador rojo de silenciar y falta la pantallita de abajo donde sale qué es cada mando.

## Qué hay que hacer
- Que el módulo de opciones de la oficina sea la misma consola que la de cerca, vista inclinada y pequeña, con la misma distribución:
  - Los tres pomos (Idioma, Pantalla completa, VSync) se ven como ruedas, como en la de cerca, con su marca según el valor.
  - El pulsador rojo de silenciar, encendido con `muted`.
  - La pantallita de abajo (la de información; desde la oficina puede ir con "OPCIONES" o apagada si no se lee a ese tamaño).
- Lo fijo está en `center_static.png`, que genera `scripts/tools/office/gen_center.py` › `build_options()` (con `lean_knob()`); lo que cambia lo pinta `OptionsConsole._draw_object()` con las posiciones de `OfficeLayout.CENTER.opt`. Regenerar las imágenes con el script, no a mano, y actualizar `OfficeLayout` si cambian posiciones (lo genera el mismo script).
- La consola de cerca no cambia, salvo que haga falta para que encajen.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Consola de opciones" y la fila de la consola de opciones en "Oficina"
- docs/design/art.md (estilo de la oficina)
- scripts/tools/office/gen_center.py › `build_options()`, `lean_knob()`, `build_options_close()`
- scripts/main_menu/OptionsConsole.gd › `_draw_object()`
- scripts/main_menu/OptionsCloseUp.gd (cómo pinta pomos, pulsador y pantallita)

## Archivos que toca
- scripts/tools/office/gen_center.py
- assets/sprites/office/center_static.png (regenerado)
- scripts/main_menu/OfficeLayout.gd (regenerado, si cambian posiciones)
- scripts/main_menu/OptionsConsole.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego y llegar a la oficina.
2. Mirar la consola de opciones: tres ruedas reconocibles, el pulsador rojo y la pantallita de abajo, como en la de cerca.
3. Abrir la consola: el paso de la de la oficina a la de cerca encaja (mismos mandos en el mismo sitio).
4. Cambiar idioma, pantalla completa, VSync y silenciar; al volver, la consola de la oficina lo refleja.
