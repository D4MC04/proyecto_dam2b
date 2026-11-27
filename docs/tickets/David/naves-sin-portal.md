# Las naves entran desde fuera de la pantalla, sin portal

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Se quita el portal de entrada de las naves: deben llegar volando desde fuera de la pantalla.

## Qué hay que hacer
- Quitar los portales: `Spawner._open_portals()`, `_close_portals()`, `_portals`, el `flash_exit()` al crear cada nave y `scripts/entities/Portal.gd`, si ya no lo usa nadie.
- Las naves empiezan al principio del camino, que ya arranca 2 casillas fuera del mapa, en vez de en `PORTAL_OFFSET`. Así entran desde fuera de la pantalla.
- Quitar la aparición desde el portal de `Enemy` (`spawn_in`: crecer de escala 0 a 1 con destello), porque ya entran volando.
- Revisar lo que dependía del portal: el comentario de `EnemyData` sobre que el portal del jefe tiembla más, los comentarios de `map_generator.gd` sobre la boca y el portal, y `PORTAL_OFFSET`. Que los mapas no cambien.
- Actualizar `docs/design/niveles.md` › "Portales" y lo que lo nombre.

## Qué leer
- docs/design/niveles.md › "Portales" y "Ciclo de oleadas"
- scripts/level/Spawner.gd › `_open_portals()`, `_close_portals()`, `_spawn()` y `PORTAL_OFFSET`
- scripts/entities/Enemy.gd › `spawn_in()`

## Archivos que toca
- scripts/level/Spawner.gd
- scripts/entities/Portal.gd (se borra)
- scripts/entities/Enemy.gd
- scripts/resources/EnemyData.gd (solo el comentario)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Empezar cualquier nivel y lanzar una oleada.
2. No debería salir ningún portal: las naves entran volando desde el borde de la pantalla por cada camino.
3. Probar una oleada con jefe (si hay) y una con varios caminos: tampoco salen portales.
