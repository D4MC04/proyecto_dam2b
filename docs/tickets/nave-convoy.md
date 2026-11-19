# Nave nueva: Convoy

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ninguna nave castiga concentrar el fuego en una sola. El Convoy son tres naves enlazadas que se reparten el daño: disparar a una cunde poco y hay que pegar a las tres a la vez (Tesla, Cañón pesado, Orbitador). Distinto del Enjambre (`nave-enjambre`, muchas naves frágiles sueltas) y de la Escudera (`nave-escudo`, absorbe daño ajeno).

## Qué hay que hacer
- Grupos de 3 naves iguales que salen muy pegadas y se enlazan con un rayo de píxeles entre vecinas mientras estén a 64 px o menos.
- El daño que recibe una se reparte a partes iguales entre las enlazadas vivas (sin repartir en bucle: el reparto no se vuelve a repartir). Un golpe de área que les da a las tres hace lo mismo que sin enlace.
- Cada una: unos 80 de vida, 50 px/s, 10 de daño a la estación, radio 10; botín ≈ 45 € (factor ×1,2).
- Al morir una, su rayo se corta con chispa.
- Sprite con `scripts/tools/make_convoy.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 6 (llega la Tesla). El generador tiene que sacarlas siempre de 3 en 3. Regenerar y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Daño y muerte", "Curación (Reparadora)" (cómo busca a las vecinas)
- docs/design/niveles.md › "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › `take_damage()` y `_heal_nearby()`
- scripts/tools/make_waves.gd › cómo arma los grupos

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/convoy.tres
- assets/sprites/enemies/convoy/ y scripts/tools/make_convoy.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 6.
2. Salen tres naves unidas por un rayo; si un Cañón doble pega a una, bajan las tres barras de vida.
3. Una Tesla las mata mucho antes que un solo cañón. Al morir una, su rayo se corta.
