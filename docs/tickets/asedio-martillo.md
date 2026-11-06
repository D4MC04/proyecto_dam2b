# Cañón de asedio nuevo: dos cañones, salva que frena y recarga a la vista

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Al mejorar el Cañón pesado, el Cañón de asedio solo cambia un poco de aspecto y ataca igual. Tiene que verse y sentirse como un nivel 2: más agresivo y más brusco, con un ataque algo distinto pero basado en el del nivel 1.

## Qué hay que hacer
- El Cañón pesado (nivel 1) no cambia.
- Aspecto nuevo del Cañón de asedio en `assets/sprites/turrets/turret2_fusion/` (32x32, art.md), dibujado o generado con un script en `scripts/tools/` como `make_minigun.gd`:
  - Base: la actual con franjas de aviso rojas y casi negras en diagonal en las dos vainas laterales y remaches claros.
  - Cañón: **dos cañones gruesos** con boca roja `#dc461e`, cada uno con un pistón hidráulico por fuera (cilindro fijo y brazo que lo une al cañón), sobre una recámara común. Cada cañón tiene en la recámara una **ventana abierta** donde se ve su bala, con un cerrojo debajo.
  - Bala de recarga: 3x8 vista desde arriba (punta roja, banda oscura, vaina de latón `#ecb23c`/`#96641e`/`#ffe082`).
  - Icono `t2_full_up.png` acorde.
- Ataque (sigue siendo bala explosiva que persigue al objetivo, como el nivel 1):
  - Cada disparo es una **salva de 2 balas** separadas 0,15 s, una por cada cañón (`muzzle_offset` a cada lado).
  - La **primera** frena en seco a los enemigos de su área: los deja al 10 % de velocidad durante 0,3 s (`Enemy.slow()`). La segunda cae encima y solo hace daño.
  - Daño 55 por bala, área 32 px, cadencia 2,1 s, velocidad de bala 160.
  - Campos nuevos opcionales en `TurretData`/`BulletData` para la salva y el frenado; las demás torretas siguen igual. La ficha enseña las filas nuevas (nombres cortos, ver `StatEntry`).
- **Recarga visible**, en vez de una luz: tras disparar, la ventana de cada cañón queda vacía y su bala entra desde atrás píxel a píxel durante la recarga; cuando está dentro, el cerrojo se cierra. Al disparar, cada cañón retrocede 3 px por separado (primero uno y luego el otro) y vuelve. La animación tiene que ir sincronizada con la cadencia.
- **Bala en vuelo**: la misma bala de recarga tumbada (8x3), girada hacia donde va, con un halo naranja de 1 px, llama de cola que parpadea, estela de brasas (amarillo → rojo oscuro, con `trail_frames`) y un poco de humo gris pequeño que se queda en el camino.
- Mantener `amp_effect`, coste y alcance actuales.
- Al hacer el ticket `torretas-mejoradas-aspecto`, el Cañón de asedio queda fuera (este ticket ya cambia su aspecto).
- Referencia visual (si sigue existiendo): `C:\Users\renzo\AppData\Local\Temp\claude\f5abc0c09d7b3c11\6fb1f1bb-6013-442d-844d-ccfa4dfb6776\scratchpad\out\asedio_R1B.gif` y el script `boceto_asedio.py` de esa carpeta (`cannon_reload` con "R1", `BIG_SHELL_IMG`, `draw_big_shell`).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)", "Escena y script", "Datos" y "Tipos de ataque" › "Bala"
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación" y la fila del Cañón de asedio
- scripts/entities/Turret.gd › `_on_attack_timeout()`, `_shoot()`, `_ready()` (animaciones del cañón)
- scripts/entities/Bullet.gd › `_on_area_entered()`, `_add_trail()`
- scripts/resources/BulletData.gd, scripts/resources/TurretData.gd
- scripts/entities/Enemy.gd › `slow()`

## Archivos que toca
- assets/sprites/turrets/turret2_fusion/
- resources/turret_data/rocket_launcher_fusion.tres
- resources/bullet_data/rocket_launcher_fusion_bullet.tres
- resources/sprite_frames/rocket_launcher_fusion*.tres
- scripts/entities/Turret.gd, scripts/entities/Bullet.gd
- scripts/resources/TurretData.gd, scripts/resources/BulletData.gd
- docs/design/torretas.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con el Cañón pesado desbloqueado, colocarlo y pulsar Mejorar.
2. Se ven dos cañones con las balas en la recámara. Al disparar salen dos balas seguidas, una por cañón, y cada cañón retrocede.
3. Las naves del área del primer impacto se quedan casi paradas un momento y la segunda bala cae encima.
4. Tras disparar, las ventanas quedan vacías y las balas entran poco a poco hasta el siguiente disparo.
5. La bala en vuelo es del mismo tamaño que la de la recámara y se sigue bien con la vista por su halo y su estela.
