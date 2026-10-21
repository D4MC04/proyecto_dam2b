# Batalla de fondo en el menú principal

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El menú tiene estrellas, cometas y planetas, pero nada del juego en sí. Unas naves enemigas cruzando a lo lejos perseguidas por disparos dan ganas de jugar.

## Qué hay que hacer
- Nodo nuevo `Skirmish` en `MainMenu.tscn`, detrás del panel y delante de los planetas: cada 6-12 s cruza un grupo de 2-4 naves enemigas (sprites de `resources/sprite_frames/`, a escala 0,5 y algo transparentes para que se vean lejanas) en formación.
- De vez en cuando les llegan disparos (líneas cian de 1 px) desde fuera de la pantalla y alguna explota (reutilizar un impacto de `resources/`).
- Que no distraiga: pocas a la vez y lejos del centro donde están los botones.

## Archivos que toca
- scenes/MainMenu.tscn
- scripts/main_menu/Skirmish.gd (nuevo)
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y esperar en el título unos 15 s.
2. Cruza a lo lejos un grupo de naves pequeñas; a alguna le dan disparos y explota.
3. Los botones se siguen viendo y pulsando igual.
