# Dinero flotante al matar y al vender

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al matar un enemigo o vender una torre el dinero sube en la cabecera, pero en el mapa no se ve nada: no se nota qué ha dado cada cosa. Vender ni siquiera tiene efecto visual.

## Qué hay que hacer
- Un texto pequeño `+X€` (con `UiFormat.money`, color dorado de la UI) que sale donde muere el enemigo, sube unos 12 px y se desvanece en ~0,6 s, y luego se libera. Una función estática tipo `FloatingText.spawn(parent, position, text)` en un script nuevo, sin escena.
- `Enemy.die()` lo lanza con `data.reward` (como el sonido de muerte, colgando del padre, porque el enemigo se libera enseguida). Si llega a la estación no sale.
- `LevelState.sell_selected_tower()` lo lanza en la posición de la torre con el valor de venta.
- Fuente pixel de la UI, sin suavizado, y por encima de enemigos y torres (`z_index`).
- Actualizar docs/design/enemigos.md, docs/design/torres.md ("Vender") y docs/design/ui.md (`UiFormat`).

## Archivos que toca
- scripts/entities/FloatingText.gd (nuevo)
- scripts/entities/Enemy.gd
- scripts/level/LevelState.gd
- docs/design/enemigos.md, docs/design/torres.md, docs/design/ui.md

## Cómo se prueba a mano
1. F5, nivel 1, colocar torres y lanzar la oleada.
2. Cada enemigo que muere deja un `+X€` que sube y se borra, con su recompensa.
3. Seleccionar una torre colocada y venderla: sale `+X€` con la mitad de lo invertido sobre su casilla.
4. Con ×2 y en cámara lenta de derrota el texto va al ritmo del juego, sin quedarse colgado.
