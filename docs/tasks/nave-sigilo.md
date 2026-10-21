# Nave nueva: Espectro, que se vuelve invisible a ratos

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una nave nueva, con su propio dibujo, que desaparece a ratos y no se puede apuntar: obliga a cubrir el camino con varias torres.

## Qué hay que hacer
- **Sprite nuevo** en `assets/sprites/enemies/espectro/`:
  - Pixel art de 32x32 mirando hacia arriba, con 2-4 frames, como `nave_normal_up_1.png`.
  - Seguir `docs/design/art.md`. Tonos morado oscuro y negro, con forma afilada de caza furtivo.
  - Generarlo con un script de `scripts/tools/`. Solo hacia arriba: `rotate_sprite = true`.
- **Datos:** `resources/enemy_data/espectro.tres`:
  - Vida 70, velocidad 55, recompensa 40, daño 10.
  - Añadirla al ARCHIVO.
- **Habilidad:**
  - Cada 4 s se camufla 2 s: el sprite baja al 20 % con un parpadeo de distorsión y las torres no la apuntan (`Tower._best_enemy` la ignora).
  - Los ataques de área (onda del Cryo, meteorito, haz del Rail) sí le dan.
- **Oleadas:** añadirla a las del nivel 7.

## Archivos que toca
- assets/sprites/enemies/espectro/ (nuevo), resources/sprite_frames/ (nuevo), scripts/tools/ (generador)
- resources/enemy_data/espectro.tres (nuevo), resources/wave_data/level_7*.tres
- scripts/entities/Enemy.gd, scripts/resources/EnemyData.gd, scripts/entities/Tower.gd, scripts/screens/Navedex.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Jugar el nivel 7.
2. Los Espectros se vuelven casi transparentes a ratos y mientras tanto los Cañones dobles dejan de dispararles.
3. La onda de un Cryo sí les da.
