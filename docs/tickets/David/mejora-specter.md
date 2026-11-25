# Mejora: la Specter sale invisible y se destapa al recibir daño

Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Ahora el Espectro aparece visible y se camufla a ratos, así que basta con esperar. Si sale invisible siempre y solo se destapa al recibir daño, el área que les da a las naves de su grupo la descubre sola, y si viene sola hay que buscar cómo pillarla.

## Qué hay que hacer
- Sale camuflada desde el principio. Cualquier daño (de lo que ya le da camuflada: ondas, explosiones, saltos de la Tesla, Orbitador, haz del Rail…) la deja visible 3 s; cada golpe reinicia el tiempo. Después se vuelve a camuflar con la animación de ahora.
- Sustituye el bucle de `cloak_interval` y `cloak_time` por un tiempo de destape (`reveal_time`).
- Stats y botín de docs/design/naves-plan.md (75 de vida, 60 px/s, 10 de daño, botín 20), y nombre Specter si no lo ha hecho ya `naves-base-rediseno`.
- Actualizar su `description`.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Specter
- docs/design/enemigos.md › "Camuflaje"
- scripts/entities/Enemy.gd › el tween de camuflaje de `setup()` y `take_damage()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/espectro.tres
- translations/textos.csv
- docs/design/enemigos.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 7.
2. Las Specter salen ya transparentes y las torretas de un objetivo no les disparan.
3. Una Cryo o un Cañón pesado que les da las destapa unos 3 s y entonces las demás torretas les disparan.
