# Nave nueva: Interceptora

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Las únicas naves rápidas (Darts 90, Wasp 100, Nave normal 75) son de los niveles 1-2 y tienen poca vida; del nivel 3 al 9 todas las nuevas van a 55 px/s o menos. Falta una nave rápida y dura para el final, y ninguna le pone problemas a la Cryo: la Interceptora obliga a matar con daño, no solo a frenar.

## Qué hay que hacer
- `EnemyData`: unos 150 de vida, 80 px/s, 10 de daño a la estación, radio 11; botín ≈ 100 € (factor ×1,2).
- Motores térmicos: la ralentización le dura un tercio. Campo nuevo en `EnemyData` (`slow_resist`, 0 = normal; 0,67 = dura un tercio) que `slow()` usa para acortar la duración. Al quitarse la escarcha echa una nube de vapor de píxeles.
- Sprite con `scripts/tools/make_interceptora.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a la tabla `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 8 (con la Saboteadora) y en las antiguas del 9. Regenerar las oleadas y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Ralentización"
- docs/design/niveles.md › "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › `slow()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/interceptora.tres
- assets/sprites/enemies/interceptora/ y scripts/tools/make_interceptora.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 8 con una Cryo en el camino.
2. La Interceptora pasa rápida, se tiñe de azul muy poco tiempo y suelta vapor al quitarse la escarcha.
3. Con Minigun o Tesla bien puestas cae; solo con Cryo y Cañón doble se escapa.
