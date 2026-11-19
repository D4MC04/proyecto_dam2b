# Nave nueva: Ladrona

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Todas las naves castigan igual: quitan vida a la estación. Desde el Minero (nivel 5) el dinero es parte de la estrategia, pero ninguna nave lo amenaza. La Ladrona apenas daña la estación pero roba dinero si llega: obliga a cubrir el final del camino y a no gastarlo todo en Mineros.

## Qué hay que hacer
- `EnemyData`: campo `steal_money` (0 = no roba). Al llegar a la estación, además de `base_damage`, quita ese dinero (sin bajar de 0) con `LevelState` y saca "-100€" en rojo con `FloatingText` sobre la estación.
- Ladrona: unos 100 de vida, 60 px/s, 0 de daño a la estación, `steal_money` 100, radio 11; botín ≈ 60 € (factor ×1,2).
- Lleva una bolsa o garra que brilla dorada; la ficha enseña una fila ROBA.
- Si llega, rompe la oleada perfecta como las demás.
- Sprite con `scripts/tools/make_ladrona.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 5 (llega el Minero). Regenerar y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Movimiento", "Comunicación con el resto"
- docs/design/niveles.md › "LevelState", "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › donde emite `reached_end`
- scripts/level/Spawner.gd › dónde se recoge `reached_end`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- scripts/level/ (donde se recoge `reached_end`)
- resources/enemy_data/ladrona.tres
- assets/sprites/enemies/ladrona/ y scripts/tools/make_ladrona.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 5 y dejar pasar una Ladrona.
2. La vida de la estación no baja, el dinero baja 100 y sale "-100€" en rojo.
3. Si se la mata, da su botín normal.
