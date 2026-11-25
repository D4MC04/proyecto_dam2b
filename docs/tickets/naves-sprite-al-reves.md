# Naves con el sprite al revés

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Alguna nave (puede que solo una) avanza por el camino con el sprite al revés, mirando hacia atrás.

## Qué hay que hacer
- Averiguar qué naves salen al revés. Sospechosas: `nave_normal` y `nave_agresiva`, las únicas con `rotation_offset = 180.0`. Sus sprites se redibujaron en el PR #155 (naves base rediseñadas), y según `docs/design/art.md` todos los enemigos se dibujan mirando hacia arriba, así que el giro de 180° probablemente sobra. Comprobar también el resto de naves con `rotate_sprite = true`, por si hay otra.
- Arreglar la orientación de las que salgan al revés, preferiblemente con el dato (`rotation_offset`) y no redibujando el sprite.

## Qué leer
- scripts/entities/Enemy.gd › `_update_animation()`
- resources/enemy_data/nave_normal.tres y nave_agresiva.tres (`rotation_offset`)
- docs/design/art.md › líneas de "Los sprites de torreta y enemigo se dibujan mirando hacia arriba" (sacar la sección con Grep)

## Archivos que toca
- resources/enemy_data/*.tres (solo las que salgan al revés)
- docs/design/ (la sección que hable de `rotation_offset`, si la hay)

## Cómo se prueba a mano
1. Jugar un nivel donde salgan las naves corregidas (en el nivel 1 salen las naves base).
2. Todas las naves deberían avanzar con el morro hacia donde van, también en las curvas.
