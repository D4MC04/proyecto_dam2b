# Animación de colocar y mejorar: holograma que se solidifica

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La animación de colocar y mejorar (escala con rebote y flash blanco) desentona con el estilo del juego. Se quiere que la torreta se materialice.

## Qué hay que hacer
- Sustituir `Turret.play_build(fused)` por una sola animación para colocar y mejorar: una línea de escaneo cian (`#40e0f0`) recorre la torreta (base y cañón) de abajo arriba; por debajo de la línea la torreta ya es sólida y por encima se ve como holograma cian translúcido con parpadeo. Al terminar, la torreta queda normal.
- Probablemente con un shader en `resources/shaders/` aplicado a `AnimatedSprite2D` y `Cannon` mientras dura, y quitado al acabar (que no choque con los tintes de apagado por EMP ni de sobrecalentamiento).
- Quitar `BUILD_FLASH`, `FUSE_FLASH` y la escala con rebote si ya no se usan.

## Archivos que toca
- scripts/entities/Turret.gd
- resources/shaders/ (shader nuevo)
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y colocar una torreta: debería verse subir la línea cian y la torreta pasar de holograma a sólida.
2. Seleccionarla y pulsar Mejorar: la versión mejorada aparece con la misma animación.
3. Al acabar, la torreta se ve con sus colores normales y dispara.
