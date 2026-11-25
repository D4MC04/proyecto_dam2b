# Estación: todo el anillo gira, también el daño

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La animación de la estación se ve a medias:
- Las 4 aspas no se ven unidas al núcleo, y tampoco al anillo, porque no giran con él.
- Con la estación dañada, el anillo gira pero las zonas rotas se quedan quietas encima.

La causa está en `scripts/tools/make_estacion_giro.py`: las fases dañadas son `fase_0` girando con los píxeles de daño de las tiras antiguas pegados encima, sin girar.

## Qué hay que hacer
- **Todo lo del anillo gira junto:** el anillo, lo que esté unido a él y su daño en cada fase.
- **Aspas:** o se unen de forma que se vea (al anillo, girando con él, o al núcleo, quietas pero claramente conectadas), o se cambian por otra cosa más bonita, si queda mejor que arreglarlas. Las aspas no le gustan especialmente al usuario, así que cambiarlas está permitido; decidir y explicar por qué.
- **Fases de daño (`fase_1` a `fase_3`):** el daño se dibuja en las piezas antes de girarlas, para que gire con ellas. Revisar que la explosión y `estacion_destruida.png` siguen encajando con el diseño.
- **Generador:** sustituir el script de un solo uso por un generador que dibuje la estación y sus fases desde cero, para poder repetirlo (como los demás `make_*.gd` o `.py`).
- Seguir `docs/design/art.md`: 80x80 centrada en frames de 96x96, contorno `#0c0e16` y paleta de la estación.
- **Antes de integrarlo, enseñar al usuario y esperar su visto bueno:**
  - Si cambia el diseño, el boceto nuevo: una imagen ampliada de la estación sana y de cada fase de daño.
  - Siempre, la animación nueva: un GIF ampliado (x4) de cada fase girando, cambie o no el diseño.

## Qué leer
- scripts/tools/make_estacion_giro.py (entero, es corto)
- docs/design/art.md › la fila de la estación en la tabla de tamaños y la línea de `estacion_fase_<n>_sheet.png` (sacarlas con Grep "stación")
- scripts/entities/Base.gd › `_phase_for()` y las animaciones que reproduce
- El `SpriteFrames` de la estación que usa `scenes/entities/Base.tscn` (número de frames y velocidad)

## Archivos que toca
- assets/sprites/base/estacion/*.png
- scripts/tools/make_estacion_giro.py (se sustituye por el generador nuevo)
- el SpriteFrames de la estación (si cambian frames o velocidad)
- docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel y mirar la estación: todo el anillo debería girar unido, y lo que no gire debería verse claramente fijo al núcleo.
2. Dejar pasar naves hasta llevarla a cada fase de daño: las zonas rotas deberían girar con el anillo, sin piezas quietas encima.
3. Dejar que la destruyan: la explosión y los restos deberían encajar con el diseño nuevo.
