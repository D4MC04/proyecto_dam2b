# Cañón pesado: los cohetes explotan en área

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
El Cañón pesado (`rocket_launcher`) solo daña a la nave que golpea; ya tiene animación de explosión y `RocketExplosion` al impactar, pero no hace daño en área. Solo su fusión, el Cañón de asedio, lo tiene (`splash_radius` 32). Con daño en área tiene una mecánica propia.

## Qué hay que hacer
- `resources/bullet_data/rocket_launcher_bullet.tres`: `splash_radius = 24.0`. `Bullet.gd` ya aplica el daño en área y la ficha ya enseña la fila ÁREA.
- Para que la fusión siga siendo mejor, subir el `splash_radius` de `rocket_launcher_fusion_bullet.tres` a 40. Ajustar los dos de oído jugando.
- Si la explosión (`rocket_launcher_impact.tres`) se queda pequeña para el radio, subir el `sprite_scale` del impacto, en múltiplos enteros.
- docs/design/torres.md: en la tabla de torres, añadir "explota en área de 24 px" al Cañón pesado, y en la de fusiones poner 40 px en el Cañón de asedio.

## Archivos que toca
- resources/bullet_data/rocket_launcher_bullet.tres
- resources/bullet_data/rocket_launcher_fusion_bullet.tres
- docs/design/torres.md

## Cómo se prueba a mano
1. F5, un nivel con oleadas en grupo (por ejemplo el 2); colocar un Cañón pesado junto al camino.
2. Al impactar en una nave, las que van pegadas a ella también pierden vida (se ve en sus barras).
3. La ficha del Cañón pesado muestra ÁREA 24, y la del Cañón de asedio ÁREA 40.
