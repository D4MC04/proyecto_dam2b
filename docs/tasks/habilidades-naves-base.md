# Habilidades de naves: sistema base y nave con escudo

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Ahora todas las naves hacen lo mismo: recorren el camino y ya está, solo cambian la vida y la velocidad. Con habilidades, cada nave nueva obliga a pensar qué torres poner. Este ticket prepara el sistema y añade la primera nave, para que las siguientes (`nave-divisora`, `nave-curandera`, `nave-sigilo`, `nave-emp`) solo tengan que añadir su habilidad.

## Qué hay que hacer
- `EnemyAbility` (`scripts/resources/EnemyAbility.gd`, `Resource`) con funciones vacías que se pueden sobrescribir: `on_setup(enemy)`, `on_process(enemy, delta)`, `on_damage(enemy, amount) -> float` (devuelve el daño que llega de verdad) y `on_die(enemy)`. Además `name` y `description`, para la ficha.
- `EnemyData`:
  - `ability: EnemyAbility` (null = sin habilidad).
  - `tint: Color` (blanco por defecto), para reutilizar sprites de otras naves teñidos.
  - `get_stats()` añade la fila HABILIDAD si tiene.
- `Enemy`:
  - Llama a las funciones de la habilidad en `setup`, `_process`, `take_damage` y `die`, y aplica `tint` al sprite.
  - `heal(amount)`, sin pasar de la vida máxima.
  - `targetable := true`.
- `Tower._best_enemy` ignora a los enemigos con `targetable == false`.
- `Navedex` carga todos los `.tres` de `resources/enemy_data/` en orden en vez de la lista fija `ENEMY_FILES`, para que las naves nuevas salgan solas.
- Primera habilidad, **Escudo** (`scripts/resources/abilities/ShieldAbility.gd`):
  - Absorbe los primeros 60 de daño.
  - Se ve una burbuja cian/blanca en pixel art alrededor de la nave que parpadea al recibir golpes y se rompe con un destello.
  - Se recarga si la nave pasa 4 s sin recibir daño.
- Nave nueva "Escudera" (`resources/enemy_data/escudera.tres`):
  - Sprite de la nave normal teñido.
  - Vida 80, velocidad 40, recompensa 45, daño 10.
  - Añadirla a las oleadas del nivel 4.

## Archivos que toca
- scripts/resources/EnemyAbility.gd (nuevo), scripts/resources/abilities/ShieldAbility.gd (nuevo)
- scripts/resources/EnemyData.gd, scripts/entities/Enemy.gd, scripts/entities/Tower.gd
- scripts/screens/Navedex.gd
- resources/enemy_data/escudera.tres (nuevo), resources/wave_data/level_4*.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 4.
2. Salen Escuderas con una burbuja alrededor. Los primeros disparos rompen la burbuja (destello) sin quitarles vida y luego ya pierden vida.
3. Si dejan de recibir disparos un rato, la burbuja vuelve.
4. En el ARCHIVO del menú aparece la Escudera con la fila HABILIDAD: ESCUDO.
