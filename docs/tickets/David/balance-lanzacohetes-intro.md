# Balance del Cañón pesado y texto de NOVA

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Cambios hechos con el panel de balanceo en la carpeta principal: el Cañón pesado (`rocket_launcher`) y sus mejoras pasan a ser más baratos y algo más rápidos, y la segunda frase de NOVA nombra la estación 4-B. Se pasan a su propio ticket para no commitear en `main`.

## Qué hay que hacer
- Aplicar el parche en el worktree, sin el `.translation` (Godot lo regenera al importar el CSV):
  `git apply --exclude=translations/textos.es.translation "C:/Users/David/AppData/Local/Temp/claude/db58d02fe07132bb/608f0451-b480-4363-800d-4eaac3d78025/scratchpad/balance-lanzacohetes-intro.patch"`
  Si el parche ya no está, parar y avisar al usuario.
- Trae: `cost` 300/600/1200 → 200/400/800 y `attack_cooldown` 2.1 → 2.0 (fusión y nivel 3) en `resources/turret_data/rocket_launcher*.tres`. También cambia sus balas (`resources/bullet_data/rocket_launcher_fusion_bullet.tres`, `rocket_launcher_level3_bullet.tres`) y su alcance (`resources/collision_shapes/rocket_launcher.tres`, `rocket_launcher_fusion.tres`). Además, `INTRO_CALL_2` (es) pasa a "…a la estación 4-B." y `scripts/level/LevelState.gd` pierde la línea en blanco del final.
- No cambiar los valores: son los que eligió el usuario.
- Actualizar la tabla de stats de docs/design/torretas.md (fila `rocket_launcher` y las de su fusión y nivel 3) con los valores nuevos.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › tabla de stats (filas de `rocket_launcher`)

## Archivos que toca
- resources/turret_data/rocket_launcher*.tres
- resources/bullet_data/rocket_launcher_fusion_bullet.tres, rocket_launcher_level3_bullet.tres
- resources/collision_shapes/rocket_launcher.tres, rocket_launcher_fusion.tres
- translations/textos.csv
- scripts/level/LevelState.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel donde se desbloquea el Cañón pesado: debería costar 200, la mejora 400 y el nivel 3 800.
2. Empezar partida nueva en una ranura vacía: la segunda frase de NOVA debería terminar en "estación 4-B".
