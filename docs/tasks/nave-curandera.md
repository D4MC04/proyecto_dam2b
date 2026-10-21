# Nave nueva: Reparadora, que cura a las naves de alrededor

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una nave nueva, con su propio dibujo, que cura a las demás: se convierte en objetivo prioritario y cambia dónde conviene poner las torres.

## Qué hay que hacer
- **Sprite nuevo** en `assets/sprites/enemies/reparadora/`:
  - Pixel art de 32x32 mirando hacia arriba, con 2-4 frames de animación (`reparadora_up_1.png`, ...), como `nave_normal_up_1.png`.
  - Seguir `docs/design/art.md` (paleta, contorno, luz) y que tenga el mismo nivel de detalle que las naves que ya hay (mirar `assets/sprites/enemies/` antes de dibujar). Tonos verdes y blancos, con aspecto de nave de apoyo: brazos o drones de reparación, un núcleo que brilla. **Sin cruz** (no es una ambulancia). Un primer intento quedó feo y se descartó: cuidar mucho la forma y el sombreado.
  - Generarlo con un script de `scripts/tools/` (no a mano píxel a píxel en el chat) y su `SpriteFrames` en `resources/sprite_frames/`.
  - Solo la dirección hacia arriba: `rotate_sprite = true` la gira.
- **Datos:** `resources/enemy_data/reparadora.tres`:
  - Vida 90, velocidad 38, recompensa 50, daño 5.
  - Descripción corta.
  - Añadirla al ARCHIVO (`Navedex.ENEMY_FILES`).
- **Habilidad:**
  - Cada 3 s cura un 10 % de su vida máxima a los enemigos (grupo `enemies`) a 48 px o menos, sin curarse a sí misma.
  - Añadir `Enemy.heal(amount)`, sin pasar de la vida máxima.
  - Al curar, la Reparadora suelta un anillo verde que se expande (pixel art, sin antialiasing).
  - En cada nave curada:
    - Sale cuánto se ha curado ("+9") en verde con `FloatingText`.
    - Hay una animación de curación: un destello verde sobre el sprite y unas chispas pequeñas de píxeles verdes (sin cruces) que suben y se desvanecen (0,4 s).
    - Su barra de vida (`HealthBar`) sube.
  - Se puede hacer con un campo en `EnemyData` (por ejemplo `heal_aura: bool`) o como mejor encaje, sin montar un sistema general.
- **Oleadas:** añadirla a las del nivel 6, en medio de grupos.

## Archivos que toca
- assets/sprites/enemies/reparadora/ (nuevo), resources/sprite_frames/ (nuevo), scripts/tools/ (generador)
- resources/enemy_data/reparadora.tres (nuevo), resources/wave_data/level_6*.tres
- scripts/entities/Enemy.gd, scripts/resources/EnemyData.gd, scripts/screens/Navedex.gd
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Jugar el nivel 6.
2. Sale la Reparadora con su dibujo nuevo, girando según el camino.
3. Cerca de ella, cada 3 s sale un anillo verde. Las naves dañadas de alrededor brillan en verde, les salen chispas que suben y el número de vida que recuperan ("+9"), y su barra de vida sube.
4. En el ARCHIVO del menú aparece la Reparadora.
