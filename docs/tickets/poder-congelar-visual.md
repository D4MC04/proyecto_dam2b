# Congelar más vistoso

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
El poder de congelar se ve muy simple: solo sale en cada nave la escarcha del Cryo. Ni el efecto ni el icono del botón llaman la atención.

## Qué hay que hacer
- **Al lanzarlo:** una ola de frío que barre toda el área de juego (pantalla tintada de azul hielo que se desvanece, o un frente de escarcha que la cruza), con copos que caen durante `FREEZE_TIME`.
- **Bordes de la pantalla:** al pulsarlo, se forma escarcha en las esquinas y los bordes del área de juego (crece desde las esquinas hacia dentro, como un cristal que se hiela) y se queda mientras dura `FREEZE_TIME`; al acabar se derrite o se desvanece. Así se nota que el hielo está puesto.
- **En cada nave:** que se vea atrapada en hielo, con un bloque o costra de hielo propia (no solo `cryo_frost.tres`) y un tinte azul, y al acabar que el hielo se rompa en trozos.
- **Icono del botón:** rehacer `power_freeze.png` (16x16) con más detalle y en el estilo de los iconos de interfaz.
- Sprites en pixel art, generados con script como los demás efectos (ver docs/design/art.md). No cambiar el factor, la duración ni la recarga.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Poderes" (tabla)
- docs/design/art.md › paletas (Cryo) y "Iconos de interfaz"
- scripts/level/Powers.gd › `_freeze()`, constantes `FREEZE_*`
- scripts/entities/Enemy.gd › `slow()`

## Archivos que toca
- scripts/level/Powers.gd
- scripts/entities/Enemy.gd (si el hielo de la nave va en el enemigo)
- assets/ui/power_freeze.png
- assets/sprites/effects/ (sprites nuevos del hielo) y su `SpriteFrames` en resources/sprite_frames/
- scripts/tools/ (script que genera los sprites)
- docs/design/niveles.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y lanzar una oleada.
2. Pulsar E (o el botón de congelar).
3. Debería verse la escarcha creciendo en las esquinas y bordes de la pantalla, la ola de frío por el mapa, los copos y las naves atrapadas en hielo y más lentas; a los 4 s el hielo se rompe y vuelven a su velocidad.
4. El icono del botón se ve más detallado.
