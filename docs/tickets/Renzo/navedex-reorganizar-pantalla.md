# Reorganizar la pantalla de la Navedex (todo menos la vitrina)

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La vitrina de arriba está bien, pero el resto de la pantalla de la tablet no convence: el nombre con las flechas de versión, los stats, el carrusel y cómo se reparte el espacio (hueco vacío entre stats y carrusel, todo apelotonado arriba).

## Qué hay que hacer
- No tocar la vitrina (`Showcase`, `NavedexShowcase.gd`) ni su tamaño.
- Antes de tocar la escena, enseñar al usuario 2-3 bocetos de la nueva distribución de la pantalla (en pestaña Torretas y Naves) y esperar a que elija uno.
- Rehacer, según el boceto elegido:
  - Nombre y versiones: las flechas `PrevButton`/`NextButton` junto al nombre y la línea "MEJORA: ..." (`FusionLabel`).
  - Stats (`StatRows`, `_make_stat_row`): las 8 cajas con barra en dos columnas, que se ven apretadas y con letra pequeña.
  - Carrusel (`Carousel`, `CarouselPrev`/`CarouselNext`): la fila de iconos, ahora separada del resto.
  - Reparto del espacio (`Spacer`): que no quede el hueco vacío entre stats y carrusel.
- Que funcione igual en las dos pestañas (en naves la vitrina crece con el hueco que sobra) y con naves no vistas ("???", sin descripción ni stats).
- Los botones físicos de abajo (NAVES, TORRETAS, Volver) y el dibujo del terminal (`_draw`) se quedan como están.

## Boceto elegido (A, lista en una columna)
Ya se enseñaron los bocetos y Renzo eligió este; no hace falta volver a enseñarlos.
- Nombre entre `PrevButton`/`NextButton` como ahora. Debajo, `VersionRow` (solo en torretas; en naves se oculta y su hueco va a la vitrina): `VersionPips`, un cuadrado de 6 px por versión (cian `OfficePaint.CYAN` el que se ve, `OfficePaint.SCREEN_LINE` el resto), y `FusionLabel` ("MEJORA: ...") al lado.
- `StatRows` pasa a `VBoxContainer` (separación 2): los 8 stats en una columna a todo el ancho, con su barra debajo y el fondo alterno por stat (`StatRow.create(entry, index)`).
- Se quita `Spacer`. En torretas `StatRows` es `SIZE_EXPAND_FILL` y cada fila `SIZE_EXPAND | SIZE_SHRINK_CENTER`, así se reparten el hueco por igual hasta el carrusel. En naves `StatRows` es `SIZE_FILL` y la vitrina crece.
- Encima del carrusel, una línea de 1 px color `SCREEN_LINE` (`CarouselLine`).
- Pendiente: medir que cabe con la torreta que más ocupa (8 stats + descripción larga) en los 372 px de alto de `Content`; si no cabe, bajar separaciones o poner la barra dentro de la fila.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Navedex" (puntos "Pantalla", "Carrusel", "Stats con barra" y el de las versiones de torretas)
- docs/design/art.md (paleta y estilo de UI)
- scripts/screens/Navedex.gd › `_show_entry()`, `_make_stat_row()`, `_open_tab()`, `_style_arrow()`, `_change_version()`
- scenes/Navedex.tscn › nodos de `Tablet/Content/Box`

## Archivos que toca
- scenes/Navedex.tscn
- scripts/screens/Navedex.gd
- docs/design/menu.md

## Cómo se prueba a mano
1. Desde el menú, pulsar la tablet para abrir la Navedex.
2. Pestaña TORRETAS: pasar por varias torretas con el carrusel y cambiar a sus mejoras.
3. Pestaña NAVES: pasar por varias, incluida alguna no vista.
4. Debería verse la distribución del boceto elegido, sin huecos vacíos ni textos apretados, y la vitrina igual que antes.
