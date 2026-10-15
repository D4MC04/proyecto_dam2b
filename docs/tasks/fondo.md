# Tarea: fondo de espacio común

Segunda tarea del embellecimiento de la UI (plan en `docs/tasks/ui_beautify_task_plan.md`). **Modelo recomendado: Sonnet.** Necesita hecha `resolucion` (área de juego de 704x540 y mapa centrado en los dos ejes).

Pone el mismo fondo de espacio animado en todos los mapas, detrás de todo lo demás y cubriendo toda el área de juego. El fondo es parte del visual del mapa, así que cada mapa lo lleva, igual que hoy los de espacio.

## Punto de partida (en la rama `ui-beautify`)

- `scenes/maps/espacio/FondoEspacio.tscn` (raíz `Node2D`):
  - `Nebulosa`: `Parallax2D` con `repeat_size = (640, 0)`, `autoscroll = (-3, 0)` y un `Sprite2D` con `fondo_nebulosa.png` (640x272).
  - `PlanetaGigante`: `Sprite2D` con `planeta_gigante.png` (224x224) en (442, 312), medio cortado por abajo.
  - `Estrellas`: `Parallax2D` a -6 px/s con un `AnimatedSprite2D` de 8 frames (`estrellas_0` a `estrellas_7`, 640x272).
  - `Cometa`: `Sprite2D` con `cometa.png` y el script `scripts/level/Cometa.gd`, que cruza de vez en cuando dentro de `ancho` (620) y `alto` (160).
- Solo la usan los mapas de los niveles 2, 5 y 6 (`Level2_espacio`, `Level5_espacio` y `Level6_espacio`), con un nodo `Fondo` dentro de `Map`. Los niveles 1, 3 y 4 no llevan fondo.
- `scenes/maps/Map.tscn` es la plantilla de mapa (`VisualMap`, `LogicMap`, `Paths`, `SpaceStation`). Los mapas no heredan de ella: son copias, así que un cambio en la plantilla no llega a los mapas que ya existen.
- `Level._center_map()` mueve el `Map` entero para centrar su rectángulo útil (`Map.get_used_rect()`, que solo cuenta `LogicMap` y la estación), así que todo lo que hay dentro del mapa se mueve con él.
- Las barras tienen fondo opaco y se dibujan por encima de `Level`.
- Medido sobre los PNG: las estrellas se repiten sin costura en los dos ejes. La nebulosa se repite bien en horizontal, pero **en vertical tiene costura**: su fila de arriba y la de abajo no casan.

## Qué hay que hacer

### Escena del fondo

1. `FondoEspacio.tscn` pasa a ser el fondo común y se mueve a `scenes/maps/SpaceBackground.tscn`, junto a la plantilla de mapa, **conservando su `uid=`**. Sus nodos pasan a llamarse en inglés: `Nebula`, `GiantPlanet`, `Stars` y `Comet` (y `Image` y `Twinkle` dentro).
2. `Cometa.gd` pasa a `scripts/level/Comet.gd` (conservando su `.uid`), con los identificadores en inglés (`speed`, `wait_min`, `wait_max`, `width`, `height`…) y comentarios en español.
3. El fondo cubre **los 704x540 del área de juego sin huecos ni costuras**:
   - **Estrellas:** se repiten en los dos ejes (`repeat_size = (640, 272)`), con el mismo parpadeo y velocidad que ahora.
   - **Nebulosa:** como tiene costura vertical, se hace una textura nueva `fondo_nebulosa_tall.png` de 640x544 en `assets/sprites/backgrounds/espacio/`: la original arriba y debajo la misma imagen volteada en vertical. Así casa consigo misma por arriba y por abajo, y con 544 px de alto cubre los 540 sin repetirse en vertical. Se genera con un script de un solo uso en `scripts/tools/` (con la API `Image` de Godot, en headless), no a mano. La textura original no se borra. Si al verlo la simetría se nota demasiado, se apunta en "Retoques visuales pendientes" del plan y no se intenta arreglar en esta tarea.
   - **Planeta gigante:** se recoloca para el área nueva, abajo a la derecha y cortado por el borde como ahora (más o menos en la misma proporción).
   - **Cometa:** cruza todo el ancho del área (704 px) y puede salir en cualquier altura de la mitad de arriba (unos 270 px), con la misma velocidad y espera.
4. El fondo no tiene que quedar recortado a 704 px: lo que sobresalga queda tapado por las barras, que son opacas. Lo que importa es que dentro del área de juego no haya ningún hueco negro.

### En los mapas

5. **Cada mapa lleva su fondo** en un nodo `Background` (instancia de `SpaceBackground.tscn`), el **primer hijo de `Map`**, para que todo lo demás se dibuje encima:
   - En la plantilla `Map.tscn`, para que los mapas nuevos ya lo tengan.
   - En los mapas de los 6 niveles: `Level1`, `Level3` y `Level4` lo añaden; en `Level2_espacio`, `Level5_espacio` y `Level6_espacio` el nodo `Fondo` pasa a llamarse `Background` y apunta a la escena nueva (con el mismo id de `ext_resource`).
   - **No se toca nada más de los mapas**: ni capas, ni `tile_map_data`, ni posiciones. No se cambia ningún `uid=` ni id de `ext_resource` existente.
6. **El fondo no se mueve con el centrado.** Aunque vive dentro del mapa, tiene que cubrir siempre el área de juego. `Map` tiene una función (por ejemplo `place_background(area_rect: Rect2)`) que coloca `Background` en coordenadas globales en el origen del área de juego, (128, 0). `Level._center_map()` la llama después de mover el mapa. El fondo no cuenta en `get_used_rect()`, así que no cambia el centrado.
7. Un mapa sin `Background` (por ejemplo uno de pruebas) sigue funcionando: `place_background` no hace nada.
8. Al reiniciar o pasar de nivel se monta un mapa nuevo con su fondo. Con el juego en pausa se queda quieto, como ahora el de los mapas de espacio.
9. Los mapas de hierba (niveles 1, 3 y 4) se ven encima del fondo de espacio, con sus bordes tal como están. No se añade nada para disimularlos: los mapas se rehacen en otra rama.

## Criterios de hecho

**Código**
- [ ] `scenes/maps/SpaceBackground.tscn` existe con el `uid=` que tenía `FondoEspacio.tscn` y nodos `Nebula`, `GiantPlanet`, `Stars` y `Comet`. `FondoEspacio.tscn` ya no existe.
- [ ] `scripts/level/Comet.gd` existe con el `.uid` de `Cometa.gd`, tipado, con identificadores en inglés. `Cometa.gd` ya no existe.
- [ ] `fondo_nebulosa_tall.png` mide 640x544 y la genera un script de `scripts/tools/` que explica en su cabecera cómo ejecutarlo.
- [ ] `Map.tscn` y los mapas de los 6 niveles tienen `Background` como primer hijo de `Map`, y no han cambiado en nada más.
- [ ] `Map` coloca el fondo en el origen del área de juego y `Level._center_map()` lo llama después de centrar. Un mapa sin `Background` no da error.
- [ ] `get_used_rect()` no cuenta el fondo.
- [ ] Ninguna escena ni script hace referencia a `FondoEspacio`, `Cometa` ni a un nodo `Fondo`.
- [ ] No se ha cambiado ningún `uid=` ni ningún id de `ext_resource` existente.
- [ ] El proyecto carga sin errores en headless.

**Juego**
- [ ] En los 6 niveles, toda el área de juego tiene el fondo de espacio, sin ningún hueco negro, y el mapa se ve encima.
- [ ] Las estrellas parpadean y el fondo se desplaza despacio hacia la izquierda sin ningún salto ni costura, ni en horizontal ni en vertical. Mirarlo al menos 30 segundos.
- [ ] De vez en cuando cruza un cometa de lado a lado del área de juego.
- [ ] El planeta gigante sale abajo a la derecha, cortado por el borde.
- [ ] El fondo es el mismo en los 6 niveles y cubre el área de juego entera también en los niveles donde el mapa queda más desplazado.
- [ ] Con la pausa abierta, el fondo se queda quieto. Al continuar, sigue moviéndose.
- [ ] Al reiniciar el nivel y al pasar al siguiente desde la victoria, el fondo sigue ahí.
- [ ] Las torres se siguen colocando, viendo y disparando igual que antes.

**Documentación**
- [ ] `docs/design/niveles.md` describe `SpaceBackground` (qué tiene y que cubre el área de juego), el nodo `Background` de cada mapa y de la plantilla, cómo se coloca al centrar, y quita la nota de los mapas de hierba que dejan fondo negro.
- [ ] `docs/design/art.md` lista `fondo_nebulosa_tall.png` (640x544) y cómo se generó.
- [ ] Este archivo de tarea está borrado.
