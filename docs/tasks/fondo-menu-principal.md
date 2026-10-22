# Fondo del menú principal a la altura de los niveles

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El fondo del menú (`ColorRect` negro con estrellas de 1 px y planetas sueltos) es mucho más simple que el de los niveles (nebulosa, planeta gigante, campo de asteroides con gravilla, restos y luces). Al entrar en un nivel hay un salto grande de complejidad visual.

## Qué hay que hacer
- Rehacer el fondo de `MainMenu` para que tenga una riqueza visual parecida a la de los niveles y use el mismo lenguaje: aprovechar lo que ya hay (`SpaceBackground.tscn` con nebulosa y planeta gigante, piezas de `tileset_espacio.tres`, restos, balizas) en vez de inventar un estilo nuevo.
- Mantener o adaptar la decoración animada actual (`StarField`, `Comets`, `Asteroids`, `Satellites`, `Planets`, `Skirmish`) para que encaje con el nuevo fondo. El salto al hiperespacio (`StarField.warp`) tiene que seguir funcionando.
- Que el fondo no le quite legibilidad al título ni a los paneles (`ButtonsPanel`, `LevelsPanel`, `OptionsMenu`, `Navedex`).
- Si se usan tiles, generarlos por script (nada de `tile_map_data` a mano).
- Actualizar `docs/design/menu.md`.

## Archivos que toca
- scenes/MainMenu.tscn
- scripts/main_menu/*.gd (los que haga falta)
- scenes/maps/SpaceBackground.tscn (solo si hay que reutilizarlo desde el menú)
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego (F5).
2. Mirar el título, la selección de nivel, las opciones y el archivo: el fondo debería verse del mismo estilo y con la misma riqueza que un nivel, con los textos y botones bien legibles.
3. Entrar en el nivel 1: el paso del menú al nivel no debería notarse como un salto de estilo, y el hiperespacio debería verse igual que antes.
