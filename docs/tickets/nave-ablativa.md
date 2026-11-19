# Nave nueva: Ablativa

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Contra todo lo duro la respuesta es pegar fuerte (Cañón pesado 40 en área, Rail 450). Una nave con placas que limitan el daño de cada golpe es lo contrario de la Coraza: premia el daño continuo o muy rápido (Minigun, Disintegrator, Tesla) y castiga confiarlo todo a un golpe gordo.

## Qué hay que hacer
- `EnemyData`: campo `max_hit` (0 = sin límite). `take_damage()` no quita más de `max_hit` por golpe. El haz continuo del Disintegrator no se ve afectado (son muchos golpes pequeños).
- Ablativa: unos 300 de vida, 40 px/s, `max_hit` 30, 20 de daño a la estación, radio 14; botín ≈ 155 € (factor ×1,3).
- Las placas se ven: el sprite pierde una placa cada 25 % de vida (frames distintos), y un golpe recortado suelta trozos de placa con `Debris`. La ficha enseña una fila MÁX. GOLPE.
- Sprite con `scripts/tools/make_ablativa.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 9 (llega el Disintegrator). Regenerar y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Daño y muerte", "Efectos visuales"
- docs/design/niveles.md › "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › `take_damage()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/ablativa.tres
- assets/sprites/enemies/ablativa/ y scripts/tools/make_ablativa.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 9.
2. El Cañón pesado le quita como mucho 30 por explosión y le saltan trozos de placa; el Disintegrator la funde normal.
3. Al bajar de vida se le ven menos placas.
