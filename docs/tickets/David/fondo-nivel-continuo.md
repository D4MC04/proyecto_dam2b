# Fondo del nivel sin saltos ni huecos negros

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Las estrellas y la nebulosa que se mueven detrás del mapa a ratos dan un salto ("snap"). Si te quedas el tiempo suficiente en un nivel, el fondo se acaba, se ve negro unos segundos y vuelve de golpe. Debería moverse siempre igual, sin saltos y sin quedarse nunca sin contenido.

## Qué hay que hacer
- En `scenes/maps/SpaceBackground.tscn`, revisar los `Parallax2D` `Nebula` (-3 px/s, textura de 640x544 repetida solo en horizontal) y `Stars` (-6 px/s, 640x272 en los dos ejes):
  - `repeat_size` tiene que ser exactamente el tamaño de la textura, para que el bucle no salte.
  - `repeat_times` tiene que dar para cubrir los 704x540 del área de juego más un margen, para que nunca quede un hueco (la textura es más estrecha que el área).
  - El origen tiene que estar bien colocado tras `Map.place_background()`.
- Encontrar la causa real del salto y del negro (no solo subir números) y apuntarla en docs/design/niveles.md › "SpaceBackground".
- Comprobar que el `Twinkle` de las estrellas sigue funcionando y que el planeta gigante no se mueve.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "SpaceBackground"
- scenes/maps/SpaceBackground.tscn (nodos `Nebula` y `Stars`)
- scripts del mapa › `place_background()`

## Archivos que toca
- scenes/maps/SpaceBackground.tscn
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar un nivel con fondo de espacio y dejarlo varios minutos (con la oleada en marcha o en pausa entre oleadas).
2. La nebulosa y las estrellas deberían moverse siempre suaves, sin saltos, y nunca debería verse fondo negro.
