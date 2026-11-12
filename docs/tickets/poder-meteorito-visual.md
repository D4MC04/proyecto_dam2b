# Meteorito más vistoso

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
El poder del meteorito se ve muy simple: cae el cometa del fondo y sale la explosión del lanzacohetes más grande. Ni el efecto ni el icono del botón llaman la atención.

## Qué hay que hacer
- **Caída:** un meteorito propio (no el `cometa.png` del fondo): roca en llamas con estela de fuego y chispas que se quedan atrás mientras cae.
- **Aviso:** mientras cae, una marca en el suelo en el punto de impacto (sombra o círculo que se cierra) para que se vea dónde va a pegar.
- **Impacto:** una explosión propia, más grande que la del lanzacohetes, con onda expansiva del tamaño de `METEOR_RADIUS`, cascotes que salen despedidos y un cráter o una marca de quemado que se apaga en unos segundos. El mapa tiembla con `Level.shake_map` (respeta la opción de Temblor de pantalla, que ya la lee `shake_map`).
- **Icono del botón:** rehacer `power_meteor.png` (16x16) con más detalle y en el estilo de los iconos de interfaz.
- Sprites en pixel art, generados con script como los demás efectos (ver docs/design/art.md). No cambiar daño, radio ni recarga.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Poderes" (tabla y "Meteorito")
- docs/design/art.md › paletas y "Iconos de interfaz"
- scripts/level/Powers.gd › `_drop_meteor()`, `_explode()`, constantes `METEOR_*`
- scripts/level/Level.gd › `shake_map()`

## Archivos que toca
- scripts/level/Powers.gd
- assets/ui/power_meteor.png
- assets/sprites/effects/ (sprites nuevos del meteorito y su explosión) y su `SpriteFrames` en resources/sprite_frames/
- scripts/tools/ (script que genera los sprites)
- docs/design/niveles.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y lanzar una oleada.
2. Pulsar Q (o el botón del meteorito) y hacer clic sobre un grupo de naves.
3. Debería verse la marca en el suelo, la roca en llamas cayendo, una explosión grande con onda y cascotes, el temblor y la marca de quemado que se apaga. Las naves del área reciben el mismo daño que antes.
4. El icono del botón se ve más detallado.
