# Mejora del Cañón pesado al de asedio con transformación de piezas

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Al mejorar, el cambio de Cañón pesado a Cañón de asedio tiene que verse como una transformación coherente: las piezas del nivel 1 se mueven y se convierten en las del nivel 2, no aparecen de la nada.

## Qué hay que hacer
- Va después de `asedio-martillo` (usa sus sprites nuevos).
- Solo para esta mejora, en vez del holograma de `play_build()`: una animación de unos 2,3 s en la que cada pieza del nivel 1 acaba siendo una del nivel 2:
  1. Se apaga la lente cian de la cúpula y la torreta hace "clac" (baja 1 px con una chispa).
  2. El cañón se parte por la mitad a lo largo y cada mitad se aparta 2 px.
  3. El tubo viejo se mete dentro de la cúpula y por el mismo sitio salen los dos tubos nuevos, pasándose un poco y volviendo.
  4. La cúpula se convierte en la recámara doble de arriba abajo, con una línea naranja que marca por dónde va.
  5. Los postes laterales bajan, se separan y se ensanchan hasta ser los cilindros; luego los brazos suben hasta los cañones.
  6. La base se queda en su sitio: sus luces pasan de ámbar a rojo una a una, en círculo, y bajan las placas de franjas de aviso.
  7. Se abren las tapas de las ventanas, entran las dos balas, se cierran los cerrojos con un golpe y sale vapor por los lados.
- Mientras dura, la torreta no dispara. Las demás torretas siguen con el holograma de siempre.
- Referencia visual (si sigue existiendo): `C:\Users\renzo\AppData\Local\Temp\claude\f5abc0c09d7b3c11\6fb1f1bb-6013-442d-844d-ccfa4dfb6776\scratchpad\out\asedio_transformacion.gif` y el script `boceto_transform_v1.py` de esa carpeta (tiempos y piezas).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)" y "Animaciones de construir, fusionar y vender"
- scripts/level/BuildManager.gd › `upgrade_selected()`
- scripts/entities/Turret.gd › `play_build()`, `BUILD_TIME`

## Archivos que toca
- scripts/entities/Turret.gd, scripts/level/BuildManager.gd
- assets/sprites/turrets/turret2_fusion/ (frames de la transformación, si se hace por sprites)
- resources/sprite_frames/ (si se añade una animación)
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar un nivel con el Cañón pesado desbloqueado, colocarlo y pulsar Mejorar.
2. Se ve la transformación: el cañón se parte, el tubo viejo entra, salen dos tubos, los postes se vuelven pistones, las luces pasan a rojo y se cargan las balas.
3. Al acabar dispara con normalidad. Mejorar otra torreta sigue enseñando el holograma.
