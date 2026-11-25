# Nave nueva: Damper

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Contra todo lo duro, lo mejor es pegar fuerte. La Damper tiene placas que aplanan los golpes grandes: ningún golpe le quita más de 25, así que rinde más el daño rápido o continuo que un golpe gordo.

## Qué hay que hacer
- Campo `max_hit` en `EnemyData` (0 = sin límite): `take_damage()` no quita más de `max_hit` por golpe. El haz continuo del Disintegrator le hace el daño entero sin tocar nada, porque cada golpe es de menos de 1.
- Las placas se ven: el sprite pierde una cada 25 % de vida (frames distintos), y un golpe recortado suelta trozos de placa con `Debris`. La ficha enseña una fila con el tope.
- Stats de docs/design/naves-plan.md (300 de vida, 45 px/s, 25 de daño, botín 70, `max_hit` 25).
- Sprite con `scripts/tools/make_damper.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`), textos en `translations/textos.csv` y `description`.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd` (nivel propuesto: 9), regenerar y comprobar la Navedex.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Damper
- docs/design/enemigos.md › "Datos", "Daño y muerte" y "Efectos visuales"
- docs/design/niveles.md › "Generador de oleadas"
- scripts/entities/Enemy.gd › `take_damage()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/damper.tres
- assets/sprites/enemies/damper/ y scripts/tools/make_damper.gd
- translations/textos.csv
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 9.
2. El Cañón pesado le quita como mucho 25 por explosión y le saltan trozos de placa; el Disintegrator la funde a su ritmo normal.
3. Al bajar de vida se le ven menos placas.
