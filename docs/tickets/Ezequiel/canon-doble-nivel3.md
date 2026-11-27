# Cañón doble nivel 3: Lanza dorada (aspecto y dardo perforante)

Creador: Ezequiel
Responsable: 
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El nivel 3 del Cañón doble (Cañón cuádruple III) es ahora el nivel 2 con otros números y el mismo aspecto. Con la Lanza dorada se ve a simple vista que es otra torreta: color oro, base blindada cuadrada y dos lanzas. Además añade una mecánica que se ve y se nota: cada dardo atraviesa una nave.

## Qué hay que hacer
Referencia visual: `C:\Users\Jotaro\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_6f9fb21a-cefb-448f-845f-57a32a5f0967\cuadruple3\cuadruple3v2_A.gif`. En el panel de la derecha, el nivel 2 y el nivel 3 salen a x4. En la misma carpeta están las plantillas de píxeles: `A_ROWS`, `DART` y `make_base()` en `boceto_cuadruple3_v2.py`, y el motor en `boceto_cuadruple3.py`. Partir de ellas y pulirlas sin cambiar la silueta.

- **Números** (`resources/turret_data/turret_level3.tres` y sus recursos `turret_level3`):
  - Coste 400, sin cambios.
  - `attack_cooldown` 0,12.
  - Radio de `collision_shapes/turret_level3.tres` 84.
  - En `bullet_data/turret_level3_bullet.tres`: `damage` 7, `speed` 340, `pierce` 1.
  - `amp_effect` sin cambios.
  - Esto da 58 DPS a un objetivo y unos 99 de DPS efectivo con las naves en fila. El provisional hace 50 DPS.
- **Sprites nuevos** en `assets/sprites/turrets/turret_level3/`, con los mismos nombres y frames que `turret_fusion/`. Los sprites del nivel 1 y del nivel 2 no se tocan.
  - **Acento oro:** `#4a3210`, `#96641e`, `#ecb23c`, `#ffe082`, `#fff8e6`. Sustituye al verde del nivel 2.
  - **Base:** la del nivel 2 con el verde cambiado a oro. Las cuatro esquinas se rellenan con placas de blindaje, con su contorno y una luz oro en cada placa, así que la silueta queda cuadrada.
  - **Cañón:** dos lanzas, que son tubos de 4 px que llegan a la fila 0, con un freno de boca oro de 6 px ranurado. A los lados de las cápsulas, cuchillas en diagonal hacia delante (filas 7-13). En el centro, una cuña en punta con una franja oro, y detrás, dos cargadores (filas 23-26).
  - **Recarga visible:** cada cápsula tiene una ventana de 7x2 (filas 15-16). En ella entra el dardo de 7x2 (blanco, crema, oro claro, oro, oro oscuro), y la abrazadera de las filas 14 y 17 destella en oro claro al cerrarse.
  - **Disparo:** `fire_0` dispara la lanza izquierda y `fire_1` la derecha, alternándose como en el nivel 2. Cada animación dura como mucho 0,12 s: fogonazo oro con retroceso de 1 px, la ventana se vacía y el dardo entra y queda cerrado. La otra ventana sigue cargada.
  - **Icono** `t1_full_up.png`: la base con el cañón en reposo.
- **Dardo en vuelo:** es el mismo dardo de la ventana, de pie (2x7, punta blanca), con halo oro de 1 px y una estela corta (`trail_frames`, 3-4 frames). El impacto es un chispazo oro (`impact_frames`). Al atravesar la primera nave sigue recto.
- **`resources/sprite_frames/`:** `turret_level3.tres` (base), `turret_level3_cannon.tres`, `turret_level3_bullet.tres`, `turret_level3_trail.tres` y `turret_level3_impact.tres`. `turret_level3.tres` (TurretData) tiene que apuntar a ellos y al icono nuevo. El `muzzle_offset` va en la boca de las lanzas, que están en las columnas 8,5 y 22,5 de la fila 0.
- **Textos** en `translations/textos.csv`:
  - `TURRET_TURRET_LEVEL3_NAME`: "Lanza dorada" / "Golden Lance".
  - `TURRET_TURRET_LEVEL3_DESC`: frase corta sobre los dardos que atraviesan una nave.
- **Documentación:**
  - `docs/design/torretas.md`, fila del Cañón cuádruple III en "Nivel 3": queda como diseño propio, no provisional. En la tabla de balance (DPS) se añade su fila.
  - `docs/design/torretas.md`, tabla de "Mejorar (fusión)": corregir el daño del Cañón cuádruple, que pone 8 y en `turret_fusion_bullet.tres` es 5.
  - `docs/design/art.md`: fila de la Lanza dorada.

## Qué leer
- docs/design/torretas.md › "Mejorar (fusión)" (tabla y "Nivel 3 (provisional)") y "Tipos de ataque" › Bala (`pierce`, `trail_frames`, `impact_frames`)
- docs/design/art.md › fila "Cañón cuádruple" y "Torretas fusionadas"
- resources/turret_data/turret_fusion.tres y turret_level3.tres; resources/sprite_frames/turret_fusion_cannon.tres (cómo están `fire_0` y `fire_1`)
- scripts/resources/BulletData.gd › `pierce`, `trail_frames`

## Archivos que toca
- resources/turret_data/turret_level3.tres
- resources/bullet_data/turret_level3_bullet.tres
- resources/collision_shapes/turret_level3.tres
- resources/sprite_frames/turret_level3*.tres (nuevos)
- assets/sprites/turrets/turret_level3/ (nuevo)
- translations/textos.csv
- docs/design/torretas.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar un nivel con dinero suficiente, colocar un Cañón doble y mejorarlo dos veces (200 € y 400 €).
2. El nivel 3 tiene que verse dorado, con la base cuadrada y las dos lanzas, claramente distinto del Cañón cuádruple verde.
3. Al disparar, las lanzas se alternan y en cada ventana se ve entrar el dardo.
4. Con naves en fila, un dardo daña a dos naves: atraviesa la primera con chispas y golpea a la siguiente.
5. La ficha enseña daño 7, perfora 1, alcance 84 y cadencia 0,12.
