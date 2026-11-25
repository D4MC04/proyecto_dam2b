# Mejora: la Mender se vacía para curar

Estado: aceptada
Espera a: mejora-specter
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La Reparadora suelta una onda de cura cada 3 s, sin más decisión que matarla. Si cura pasando su propia vida con un rayo, se ve a quién salva y cuánto le cuesta: ignorarla hace que se gaste sola, pero habrá salvado a otra.

## Qué hay que hacer
- Sustituir la onda (`heal_aura`, `_heal_nearby()`) por un rayo: engancha a la nave más dañada (en proporción) a 64 px o menos, que no sea ella, y le pasa 10 de vida por segundo de la suya. No cura por encima de la vida máxima. Si la curada muere o se aleja, busca otra.
- Si se queda sin vida, muere y da su botín normal.
- Rayo verde de píxeles sin antialias, con la rampa de `HealEffect`; las chispas de `spawn_sparks()` siguen saliendo en la curada.
- Stats y botín de docs/design/naves-plan.md (100 de vida, 45 px/s, 5 de daño, botín 25), nombre Mender y `description`.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Mender
- docs/design/enemigos.md › "Curación (Reparadora)"
- scripts/entities/Enemy.gd › `heal()` y `_heal_nearby()`
- scripts/entities/HealEffect.gd

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd y HealEffect.gd
- resources/enemy_data/reparadora.tres
- translations/textos.csv
- docs/design/enemigos.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 6.
2. La Mender engancha un rayo verde a una nave dañada: la barra de la otra sube y la suya baja.
3. Si nadie la toca, acaba muriendo sola.
