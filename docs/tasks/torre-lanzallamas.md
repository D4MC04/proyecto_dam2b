# Torre nueva: Lanzallamas

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ninguna torre hace daño con el tiempo ni ataca en cono. El Lanzallamas quema todo lo que tiene delante a corta distancia y deja a las naves ardiendo, así que va bien contra grupos y contra la curación de la Reparadora.

## Qué hay que hacer
- Tipo de ataque nuevo, **llama**: `FlameData` (`scripts/resources/FlameData.gd`) y `scripts/entities/Flame.gd`. Mientras haya objetivo y el cañón esté alineado, echa fuego en un cono hacia donde apunta. En cada tic (el `attack_cooldown`) daña a todos los enemigos del grupo `enemies` que estén dentro del cono (`length` y `cone_angle`) y les pone una quemadura.
- Quemadura en `Enemy`: `burn(dps, duration, source)`. Hace daño cada poco tiempo con `take_damage(amount, source)`, así que cuenta para las bajas y el daño de la torre. Otra quemadura renueva la duración y se queda con el mayor `dps`, no se acumula. Mientras arde, la nave se tiñe de naranja y suelta alguna chispa en píxeles, sin antialiasing.
- Con EMP la llama se corta, como el haz continuo. Si no hay objetivo, también.
- `get_attack_label()` "LLAMA"; `FlameData.get_stats()`: DAÑO (por tic), QUEMA (dps), DURACIÓN, ÁNGULO.
- Valores de partida (ajustables): coste 275, alcance 48 px, giro 200 °/s, tic 0,15 s, 3 de daño por tic, cono de 50°, quemadura de 6 dps durante 3 s.
- Mejora (`fusion`): **Infierno**, coste 550, alcance 60, cono de 70°, 5 por tic, quemadura de 12 dps durante 4 s.
- Sprites con un script nuevo en `scripts/tools/` (p. ej. `make_flamethrower.gd`) siguiendo art.md: `assets/sprites/towers/flamethrower/` (base, cañón mirando hacia arriba con boquilla y depósito, animación del chorro de fuego en píxeles) y `flamethrower_fusion/` con los mismos nombres, más detallada.
- Recursos: `resources/turret_data/flamethrower.tres` y `flamethrower_fusion.tres`, `FlameData` de cada uno, `SpriteFrames`, `description`.
- Sonido: no hay asset de fuego. Dejar `shoot_sound` vacío y decírselo al usuario, o usar uno existente si queda bien.
- Añadirlo a `GameData.tscn`, a `TOWER_FILES` de `Navedex.gd` y a las `LevelData` desde el **nivel 6** (también en el 7, 8 y 9).
- Atajos: con 10 torres, añadir `select_tower_8`, `select_tower_9` y `select_tower_10` (teclas 8, 9 y 0) a `project.godot` y a `LevelUI`. Comprobar que `press_tower_button` no falla si el índice no existe (niveles con menos torres).

## Archivos que toca
- scripts/resources/FlameData.gd, scripts/entities/Flame.gd, scripts/entities/Tower.gd, scripts/entities/Enemy.gd, scripts/resources/TowerData.gd
- scripts/tools/make_flamethrower.gd, assets/sprites/towers/flamethrower/, assets/sprites/towers/flamethrower_fusion/
- resources/turret_data/, resources/flame_data/, resources/sprite_frames/
- scenes/GameData.tscn, resources/level_data/level_6..9.tres, scripts/screens/Navedex.gd
- project.godot, scripts/level_ui/LevelUI.gd
- docs/design/torres.md, docs/design/enemigos.md, docs/design/niveles.md, docs/design/ui.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 6: en la tienda sale el Lanzallamas.
2. Colocarlo junto al camino: echa un cono de fuego a las naves cercanas, y las que pasan se quedan ardiendo (naranja, con chispas) unos segundos después de salir del cono.
3. En su ficha, las bajas y el daño suben también con lo que hace la quemadura.
4. Pulsar "Mejorar": pasa a Infierno, con un cono más ancho y una quemadura más fuerte.
5. Pulsar 8 con el Lanzallamas en la tienda: lo selecciona.
