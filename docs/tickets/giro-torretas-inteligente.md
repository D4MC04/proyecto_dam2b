# Giro de torretas que tiene en cuenta hacia dónde va el enemigo

Creador: D4MC04
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Las torretas que giran poco a poco (`turn_speed > 0`) giran siempre por el camino más corto hacia el enemigo. Muchas veces ese camino es ir hacia el lado del que viene el enemigo, no hacia el que va: el enemigo se aleja del cañón mientras este gira y lo alcanza tarde o nunca. Tiene que girar hacia el lado en el que lo encuentra antes.

## Qué hay que hacer
- En `Turret._process`, en vez de `rotate_toward` por el camino más corto, elegir el sentido de giro (horario o antihorario) con el que el cañón alcanza antes al objetivo, teniendo en cuenta cómo se mueve el ángulo del enemigo visto desde la torreta:
  - Velocidad del enemigo: la dirección del camino en su `progress` (tangente de la curva del `Path2D`) por `speed` y su ralentización actual (`_slow`). Exponerla en `Enemy` con una función (p. ej. `get_move_velocity()`), sin duplicar el cálculo del movimiento.
  - Velocidad angular del enemigo alrededor de la torreta a partir de esa velocidad. Para cada sentido, tiempo hasta alcanzarlo: ángulo a recorrer en ese sentido / (velocidad de giro ∓ velocidad angular del enemigo). Si en un sentido no lo alcanza nunca (el enemigo gira más rápido que el cañón en ese sentido), descartarlo. Elegir el de menor tiempo; si ninguno lo alcanza, girar hacia donde va el enemigo.
  - Que no cambie de sentido a cada frame por diferencias pequeñas (p. ej. mantener el sentido elegido mientras el objetivo sea el mismo, salvo que el otro sea claramente mejor).
- Con el cañón ya alineado (dentro de `AIM_TOLERANCE`) debe seguir al enemigo como ahora, sin temblar.
- No cambiar las torretas con `turn_speed = 0` (giran al instante), ni el criterio de elección de objetivo, ni `_is_aimed`.
- Actualizar docs/design/torretas.md › "Apuntado".

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Objetivo" y "Apuntado"
- scripts/entities/Turret.gd › `_process()`, `_target_angle()`, `_is_aimed()`, `AIM_TOLERANCE`
- scripts/entities/Enemy.gd › `_process()` (movimiento: `progress += speed * _slow * delta`)

## Archivos que toca
- scripts/entities/Turret.gd
- scripts/entities/Enemy.gd
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar un nivel con curvas (p. ej. el 2) y colocar una torreta de giro lento (Raíl o Lanzacohetes) en el interior de una curva, con el enemigo pasando de un lado a otro de ella.
2. Cuando la torreta cambia de objetivo a uno que está "detrás" de su cañón, debería girar hacia el lado al que va el enemigo, no perseguirlo por detrás.
3. Con una torreta de giro instantáneo y con enemigos que van de frente hacia la torreta, todo debería verse igual que antes; el cañón no tiembla ni cambia de sentido a cada momento.
