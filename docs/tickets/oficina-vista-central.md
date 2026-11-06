# Retoques de la vista central de la oficina

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
En la vista central hay piezas que se ven mal: la tablet no aprovecha su hueco, la nave del holograma da un salto raro, la consola de opciones tiene cosas pegadas o rectas sobre un plano inclinado, y la barra entre consola y ventanal está pobre.

## Qué hay que hacer
- **Tablet (`ArchiveTablet`):** que la pantalla y su contenido ocupen más del hueco de la tablet y queden centrados en vertical y en horizontal.
- **Holograma de la tablet:** quitar el movimiento hacia la derecha de la nave con el ratón encima (el giro con `cos(time * 3.0)` que estrecha la nave y la desplaza al redondear `box`). La nave no debe moverse de lado.
- **Opciones (`OptionsConsole`), arriba:** separar más los faders de los vúmetros, que ahora están muy pegados.
- **Opciones, abajo:** inclinar los pomos y los interruptores con el plano de la consola (como el resto de piezas, ver `ALPHA` en `gen_center.py`), que ahora están rectos.
- **Corchetes de hover:** los corchetes blancos en L de los objetos apoyados en la consola inclinada (`OptionsConsole`, `ArchiveTablet`, `RadarConsole`) siguen la misma inclinación, en vez de ser un rectángulo recto.
- **Barra entre consola y ventanal:** darle más detalle a la línea de luz que separa la consola del ventanal (en `gen_center.py` y, si se anima, en `OfficeLights`).
- Volver a generar con `python scripts/tools/office/make_office.py`; ni los PNG ni `OfficeLayout.gd` se editan a mano.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › "Oficina" (Dibujos, Nodos, Objetos)
- docs/design/art.md › "Oficina del menú"
- scripts/main_menu/ArchiveTablet.gd › `_draw_object()` (holograma, `turn`, `box`)
- scripts/main_menu/OfficeObject.gd › `hover_rect()` y el dibujo de los corchetes
- scripts/tools/office/gen_center.py

## Archivos que toca
- scripts/tools/office/gen_center.py (y pixkit.py si hace falta)
- assets/sprites/office/center_static.png (generado)
- scripts/main_menu/OfficeLayout.gd (generado)
- scripts/main_menu/ArchiveTablet.gd
- scripts/main_menu/OptionsConsole.gd
- scripts/main_menu/OfficeObject.gd
- scripts/main_menu/OfficeLights.gd (si se anima la barra)
- docs/design/menu.md

## Cómo se prueba a mano
1. F5 y entrar en una partida hasta la oficina.
2. La tablet llena su hueco y está centrada; con el ratón encima la nave gira sin irse a la derecha.
3. En la consola de opciones, faders y vúmetros separados; pomos e interruptores inclinados como la consola.
4. Pasar el ratón por la tablet, las opciones y el radar: los corchetes siguen la inclinación.
5. La barra entre consola y ventanal tiene más detalle.
