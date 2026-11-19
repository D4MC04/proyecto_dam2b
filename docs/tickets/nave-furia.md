# Nave nueva: Furia

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Las naves van a la misma velocidad toda su vida, así que da igual matarlas de golpe o poco a poco. La Furia acelera según pierde vida: castiga el daño a cuentagotas y premia rematar rápido (Disintegrator, Rail) o tener una Cryo en la parte final del camino.

## Qué hay que hacer
- `EnemyData`: campo `rage_speed` (0 = no tiene). Velocidad = `speed` × (1 + `rage_speed` × (1 − vida / vida máxima)); con 2,0 llega casi al triple con la vida a cero. Se multiplica con la ralentización, no la sustituye.
- Furia: unos 180 de vida, 35 px/s, `rage_speed` 2,0, 15 de daño a la estación, radio 12; botín ≈ 90 € (factor ×1,3).
- El sprite se va tiñendo de rojo y las llamas del motor crecen con la rabia; con menos del 25 % deja una estela roja.
- Sprite con `scripts/tools/make_furia.gd` (pixel art según docs/design/art.md, mirando hacia arriba, `rotate_sprite = true`) y `description` para la ficha.
- Añadirla a `LEVELS` de `scripts/tools/make_waves.gd`: nueva en el nivel 7, junto al Espectro. Regenerar y comprobar que sale en la Navedex.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Movimiento", "Ralentización"
- docs/design/niveles.md › "Generador de oleadas"
- docs/design/art.md (sección de sprites de enemigos)
- scripts/entities/Enemy.gd › `_process()` y `take_damage()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/furia.tres
- assets/sprites/enemies/furia/ y scripts/tools/make_furia.gd
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 7.
2. La Furia entra lenta; al recibir daño se pone roja y acelera, y casi muerta corre con estela.
3. Con una Cryo en la parte final del camino no llega.
