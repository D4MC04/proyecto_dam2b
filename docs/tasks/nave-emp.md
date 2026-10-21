# Nave nueva: Saboteadora, que apaga las torres cercanas

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Una nave nueva, con su propio dibujo, que inutiliza torres un momento: ya no basta con amontonar torres en un solo punto.

## Qué hay que hacer
- **Sprite nuevo** en `assets/sprites/enemies/saboteadora/`:
  - Pixel art de 32x32 mirando hacia arriba, con 2-4 frames (`saboteadora_up_1.png`, ...), como `nave_normal_up_1.png`.
  - Seguir `docs/design/art.md`. Tonos azul eléctrico y gris oscuro, con aspecto de nave de guerra electrónica (bobinas, antena o núcleo que brilla).
  - Generarlo con un script de `scripts/tools/` y su `SpriteFrames` en `resources/sprite_frames/`.
  - Solo la dirección hacia arriba: `rotate_sprite = true`.
- **Datos:** `resources/enemy_data/saboteadora.tres`:
  - Vida 110, velocidad 30, recompensa 55, daño 10.
  - Descripción corta.
  - Añadirla al ARCHIVO (`Navedex.ENEMY_FILES`).
- **Habilidad:**
  - Cada 5 s suelta un pulso EMP que apaga 3 s las torres a 48 px o menos. Se ve como un anillo azul que se expande (pixel art, sin antialiasing).
  - Añadir `Tower.disable(seconds)`. Mientras dura, la torre no apunta ni dispara (el haz continuo se corta) y se ve oscurecida, con chispas azules que saltan.
- **Oleadas:** añadirla a las del nivel 8.

## Archivos que toca
- assets/sprites/enemies/saboteadora/ (nuevo), resources/sprite_frames/ (nuevo), scripts/tools/ (generador)
- resources/enemy_data/saboteadora.tres (nuevo), resources/wave_data/level_8*.tres
- scripts/entities/Enemy.gd, scripts/resources/EnemyData.gd, scripts/entities/Tower.gd, scripts/screens/Navedex.gd
- docs/design/enemigos.md, docs/design/torres.md

## Cómo se prueba a mano
1. Jugar el nivel 8.
2. Sale la Saboteadora con su dibujo nuevo.
3. Cada 5 s suelta un anillo azul y las torres de alrededor se oscurecen con chispas y dejan de disparar 3 s.
4. Luego vuelven a disparar con normalidad.
