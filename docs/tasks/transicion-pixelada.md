# Transición pixelada entre niveles

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El destello blanco al pasar de nivel o reintentar no termina de convencer. Un efecto de pixelado encaja mejor con el pixel art 16x16.

## Qué hay que hacer
- Cambiar el fundido a blanco de `_restart_level()` en `Game.gd` por una transición pixelada: la pantalla se deshace en cuadritos de píxel que se apagan a negro, se cambia el nivel con la pantalla tapada y el nivel nuevo aparece al revés (los cuadritos se encienden).
- Hacerlo con un shader de `canvas_item` sobre un `ColorRect` a pantalla completa en un `CanvasLayer` alto (umbral por bloque con ruido, tamaño de bloque grande, unos 16 px). Duración parecida a la actual (~0,3 s cada mitad).
- Mantener lo que ya hace: ignora clics repetidos mientras dura (`_transitioning`), sigue corriendo con el árbol en pausa (pantallas de victoria y derrota) y bloquea el ratón mientras tapa.
- El fundido desde blanco al llegar del hiperespacio (`_fade_in_from_white`) no se toca.

## Archivos que toca
- scripts/screens/Game.gd
- resources/shaders/ (shader nuevo de la transición)
- docs/design/flujo.md

## Cómo se prueba a mano
1. F5, nivel 1. Perder y pulsar "Reintentar": la pantalla se deshace en cuadritos y vuelve con el nivel reiniciado.
2. Ganar un nivel y pulsar "Siguiente nivel": lo mismo, apareciendo en el nivel 2.
3. Pulsar el botón varias veces seguidas no rompe nada.
4. Llegar desde el menú principal (salto al hiperespacio): sigue el fundido desde blanco de antes.
