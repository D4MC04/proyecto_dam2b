# Mapas nuevos para los 9 niveles principales

Estado: aceptada
Modelo recomendado: opus

## Por qué
Los mapas actuales miden unos 33x17 casillas (como mucho 480x272 px). Eso era antes de las barras laterales: ahora el área de juego es de 704x540 px y alrededor del mapa solo se ve fondo (docs/design/niveles.md, "Dudas"). Además, los niveles 1, 3 y 4 todavía usan mapas de hierba. Hay que hacer 9 mapas de espacio que llenen el área de juego, con una dificultad de trazado que suba de nivel en nivel y con la estación en un sitio distinto en cada nivel.

## Tamaño de los mapas
- Pantalla de 960x540 px, barras de 128 px a cada lado: el área de juego mide 704x540 px, es decir, 44 x 33,75 casillas.
- Cada mapa nuevo mide **43x33 casillas** (688x528 px), con la casilla (0, 0) arriba a la izquierda. Al ser impares, hay una columna central (21) y una fila central (16), así que un camino de 1 casilla puede ir justo por el eje y los mapas simétricos quedan exactos.
- Al centrarse, sobran 8 px a cada lado y 6 px arriba y abajo. Ahí se ve el fondo de espacio, igual que bajo el resto del mapa. Las capas de decoración (`VisualMap`, `Polvo`) pueden tener una columna o fila más de rocas que se meta en esa franja: no cuentan para el centrado, que solo mira la `LogicMap` y la estación.
- La estación (`Base.tscn`, 96x96 px) se coloca con su centro en el centro de una casilla y sobresale media casilla por cada lado (ocupa 5 casillas enteras más dos medias). Las casillas de `LogicMap` que tapa son de decorado. Centro de la estación en cada una de las 9 posiciones:

| | Izquierda (col. 4) | Centro (col. 21) | Derecha (col. 38) |
|---|---|---|---|
| **Arriba (fila 4)** | nivel 6 | nivel 4 | nivel 2 |
| **Centro (fila 16)** | nivel 1 | nivel 9 | nivel 5 |
| **Abajo (fila 28)** | nivel 3 | nivel 8 | nivel 7 |

Cada posición se usa una sola vez y el último nivel tiene la estación en el centro.

## Diseño de cada nivel
Los esquemas son orientativos. Cada carácter equivale más o menos a 2x2 casillas (21x17 caracteres ≈ 43x33 casillas); la columna central del esquema (10) es la columna 21 del mapa y la fila central (8) es la fila 16. Leyenda: `#` camino, `a`/`b` dos caminos distintos, `+` bifurcación o unión, `X` cruce, `B` estación. Entre dos tramos paralelos debe haber al menos 4 casillas de centro a centro, para que quepan rocas y planetas de torre.

Los niveles 4, 8 y 9 son **simétricos** respecto a la columna central (el 9, también respecto a la fila central): al pasarlos a casillas hay que reflejar las columnas exactamente (la columna c tiene su reflejo en la 42 - c, y la fila f en la 32 - f).

### Nivel 1: un camino con curvas · estación en el centro a la izquierda
Referencia: `scenes/maps/Level1.tscn` (hierba): misma idea, un solo camino en zigzag hasta la estación. Ahora el mapa tiene que ocupar casi toda la pantalla. 1 `Path2D`.
```
.....................
.....................
.....################
.....#...............
.....#...............
.....##############..
..................#..
.BBB..............#..
.BBB###########...#..
.BBB..........#...#..
..............#...#..
......#########...#..
......#...........#..
......#...........#..
......#############..
.....................
.....................
```

### Nivel 2: la bifurcación es lo principal · estación arriba a la derecha
Referencia: `scenes/maps/espacio/Level2_espacio.tscn`. Misma premisa (un camino que se desdobla y vuelve a juntarse antes de la estación, a la que llega por debajo), pero ahora la bifurcación es lo que define el nivel. El camino entra por abajo a la izquierda y casi enseguida se parte en dos rutas largas y muy distintas:
- **Ruta norte:** sube por la izquierda y hace eses verticales por la mitad de arriba. Es la más larga.
- **Ruta sur:** va recta por abajo y luego hace eses horizontales por la esquina de abajo a la derecha. Es más corta.

Las dos se juntan justo debajo de la estación, con solo un tramo corto en común al final. 2 `Path2D`, uno por ruta.
```
.....................
.................BBB.
..#####...#####..BBB.
..#...#...#...#..BBB.
..#...#...#...#...#..
..#...#...#...#...#..
..#...#...#...####+..
..#...#...#.......#..
..#...#...#.......#..
..#...#...#.......#..
..#...#####..######..
..#..........#.......
..#..........######..
..#...............#..
..+################..
..#..................
..#..................
```

### Nivel 3: un camino que se divide en dos · estación abajo a la izquierda
Diseño nuevo (el `Level3.tscn` de ahora no tiene bifurcación): **dos ramas en espejo**. El camino entra por arriba a la derecha, baja por el borde derecho y gira hacia la izquierda hasta el punto de bifurcación, en el centro a la derecha. Desde ahí, las dos ramas se separan y no vuelven a tocarse:
- **Rama norte:** hace eses verticales por la mitad de arriba y baja por el borde izquierdo hasta la estación, a la que llega por arriba.
- **Rama sur:** hace eses verticales por la mitad de abajo, reflejo aproximado de la norte, y llega a la estación por la derecha.

El tronco antes de la bifurcación es el único sitio donde una torre cubre a todos los enemigos. Después, hay que repartir la defensa entre las dos mitades del mapa. 2 `Path2D`, uno por rama.
```
...................#.
...................#.
..#####....#####...#.
..#...#....#...#...#.
..#...#....#...#...#.
..#...#....#...#...#.
..#...######...#...#.
..#............#...#.
..#............+####.
..#............#.....
..#...######...#.....
..#...#....#...#.....
..#...#....#...#.....
.BBB..#....#...#.....
.BBB###....#####.....
.BBB.................
.....................
```

### Nivel 4: dos caminos que se juntan en uno · estación arriba en el centro · simétrico
Diseño nuevo (en el `Level4.tscn` de ahora los dos caminos llegan por separado). Las dos entradas están en las esquinas de arriba. Cada camino baja haciendo eses por su mitad del mapa, que es el reflejo exacto de la otra, y los dos se juntan abajo en el centro. Desde ahí, un tronco común sube recto por la columna central hasta la estación, a la que llega por debajo. 2 `Path2D`, que comparten el tronco.
```
.#.................#.
.#.......BBB.......#.
.#.......BBB.......#.
.#.......BBB.......#.
.#..####..#..####..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.#..#..#..#..#..#..#.
.####..#..#..#..####.
.......#..#..#.......
.......###+###.......
.....................
.....................
```

### Nivel 5: dos caminos entrelazados · estación en el centro a la derecha
Diseño nuevo. **Ojo:** el `Level5_espacio.tscn` de ahora pasa a ser la referencia del nivel 8 (ver abajo); este archivo se rehace con el diseño nuevo. Los dos caminos entran por la izquierda, uno arriba y otro abajo, y van haciendo eses desfasadas, de modo que se cruzan al menos dos veces. Nunca se juntan: uno llega a la estación por la izquierda y el otro por abajo. 2 `Path2D`.
```
.....................
.....................
aaaa.....aaaaaaa.....
...a.....a.....a.....
...a..bbbXbbb..a.....
...a..b..a..b..a.....
...a..b..a..b..a.....
...a..b..a..b..a.BBB.
...a..b..a..b..aaBBB.
...a..b..a..b....BBB.
...a..b..a..b.....b..
...a..b..a..b.....b..
...aaaXaaa..b.....b..
......b.....b.....b..
bbbbbbb.....bbbbbbb..
.....................
.....................
```

### Nivel 6: el anillo y los dos que lo cruzan · estación arriba a la izquierda
Diseño nuevo. **Ojo:** el `Level6_espacio.tscn` de ahora pasa a ser la referencia del nivel 9; este archivo se rehace con el diseño nuevo. Tres caminos:
- **A, el anillo:** entra por la izquierda, abajo, y rodea todo el mapa por fuera (abajo, derecha y arriba) hasta llegar solo a la estación, por su derecha.
- **B:** entra por arriba y cruza el anillo.
- **C:** entra por abajo y también cruza el anillo.

B y C dan vueltas por el interior y se juntan en el centro. Desde ahí, un tronco común va hacia la izquierda y sube hasta la estación, a la que llega por debajo. Los cruces con el anillo son puntos calientes: allí pasan dos caminos a la vez. 3 `Path2D`.
```
.....................
.BBB.................
.BBB########X######..
.BBB........#.....#..
..#.........#.....#..
..#.........####..#..
..#............#..#..
..#............#..#..
..###########..#..#..
............#..#..#..
............#..#..#..
............#..#..#..
........####+##+##+##
........#.........#..
........#.........#..
########X##########..
........#............
```

### Nivel 7: dos caminos con bifurcaciones serias · estación abajo a la derecha
Diseño nuevo que lleva la idea del nivel 2 a dos caminos. Cada camino se parte nada más entrar en dos rutas largas y muy distintas, que solo se vuelven a juntar justo antes de la estación:
- **Camino A:** entra por la izquierda, arriba. Una ruta va recta por el borde de arriba; la otra hace eses por la franja de arriba. Llega a la estación por arriba, bajando por la derecha.
- **Camino B:** entra por la izquierda, abajo. Una ruta va recta por el centro y baja; la otra hace eses por la franja de abajo. Llega a la estación por la izquierda.

4 `Path2D`: A recto, A en eses, B recto y B en eses.
```
.....................
..#################..
..#...............#..
..#...............#..
##+...#####...####+..
..#...#...#...#...#..
..#...#...#...#...#..
..#####...#####...#..
..................#..
..................#..
..#############...#..
..#...........#...#..
##+...#####...#...#..
..#...#...#...#..BBB.
..#...#...#...+##BBB.
..#####...#####..BBB.
.....................
```

### Nivel 8: dos entradas con atajo y vuelta larga · estación abajo en el centro · simétrico
Referencia: `scenes/maps/espacio/Level5_espacio.tscn` (el actual). Misma premisa: dos entradas en esquinas opuestas que bajan por los lados. Cada una se parte en un atajo, que va directo a la estación, y en una vuelta larga, que sube y llega a la estación por el otro lado. Como aquí la estación está abajo, las entradas están en las dos esquinas de arriba y las dos mitades del mapa son reflejo exacto una de otra. Los atajos llegan por los lados de la estación; las vueltas largas se juntan arriba en el centro y bajan por la columna central hasta ella. 4 `Path2D`, como en el mapa de referencia.
```
.#.................#.
.#.................#.
.#..######+######..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#.....#.....#..#.
.#..#....BBB....#..#.
.###+####BBB####+###.
.........BBB.........
.....................
```

### Nivel 9: cuatro esquinas, ocho rutas · estación en el centro · simétrico en los dos ejes
Referencia: `scenes/maps/espacio/Level6_espacio.tscn` (el actual). Misma premisa, adaptada al tamaño nuevo: una entrada en cada esquina, y cada una se parte en una ruta que llega a la estación por arriba o por abajo y otra que llega por su lado. Los cuatro cuartos del mapa son reflejo exacto unos de otros. 8 `Path2D`, como en el mapa de referencia.
```
.#.................#.
.#.................#.
.#.................#.
.+########+########+.
.#........#........#.
.#........#........#.
.#........#........#.
.#.......BBB.......#.
.+#######BBB#######+.
.#.......BBB.......#.
.#........#........#.
.#........#........#.
.#........#........#.
.+########+########+.
.#.................#.
.#.................#.
.#.................#.
```

## Qué hay que hacer
1. **Generador.** Ampliar `scripts/tools/space_decoration.gd` para que cada trabajo de `JOBS` tenga su propio origen de cuadrícula (los mapas nuevos empiezan en (0, 0); `GRID_ORIGIN` es ahora (-2, -1) para todos). Para cada nivel, un `resources/map_data/level_N.txt` con una sección por capa: `LogicMap` (camino, hueco de torre y decorado), `Pista`, `Planetas`, `VisualMap` y `Polvo`. Ninguna capa se escribe a mano en el `.tscn`. Los `.txt` de 33x17 (`level_5_decor.txt` y `level_6_decor.txt`) se borran: los sustituyen los nuevos.
2. **Escenas**, todas en `scenes/maps/espacio/` y con la estructura de los mapas de espacio de ahora (`Background`, `Polvo`, `VisualMap`, `Planetas`, `Pista`, `LogicMap`, `Paths`, `SpaceStation`):
   - Se rehacen en el mismo archivo, conservando `uid=` y `unique_id`: `Level2_espacio.tscn`, `Level5_espacio.tscn` y `Level6_espacio.tscn`. Antes de rehacer los dos últimos hay que haber terminado los niveles 8 y 9, que los toman como referencia.
   - Archivos nuevos: `Level1_espacio.tscn`, `Level3_espacio.tscn`, `Level4_espacio.tscn`, `Level7_espacio.tscn`, `Level8_espacio.tscn` y `Level9_espacio.tscn`.
   - Los mapas de hierba (`Level1.tscn`, `Level3.tscn` y `Level4.tscn`) no se borran. Solo dejan de usarse.
3. **Visual.** Seguir las reglas de "Decoración de los mapas de espacio" de docs/design/niveles.md: un corredor libre alrededor del camino, una hilera de rocas a 2 casillas y planetas de torre a lo largo de todas las rutas, sobre todo en curvas, bifurcaciones y cruces. La densidad de planetas, parecida a la del `Level2_espacio.tscn` de ahora. Los tramos pegados a un borde siguen la regla del nivel 5 (en el borde, solo chatarra y piedras pequeñas). En los niveles simétricos, los planetas y la decoración principal también son simétricos; la chatarra y las piedras pequeñas pueden variar. Si en `tileset_espacio.tres` falta alguna pieza de pista (un cruce o una T), usar la más parecida y apuntarlo en "Dudas" de niveles.md.
4. **Caminos (`Path2D`).** Los puntos van por el centro de las casillas de camino. Cada camino empieza 1 casilla fuera del mapa, para que los enemigos entren desde fuera de la pantalla, y acaba en el borde de la estación (esto cubre también el ticket `caminos-hasta-la-estacion.md`). Los caminos que comparten tramo pasan por los mismos puntos en ese tramo.
5. **Niveles y oleadas.**
   - `level_1.tres`, `level_3.tres` y `level_4.tres` pasan a apuntar a su `LevelN_espacio.tscn`.
   - En las oleadas de los niveles 1 a 6, repartir los `path_index` para que se usen todos los caminos del mapa nuevo. No se cambian enemigos ni tiempos.
   - Crear `level_7.tres`, `level_8.tres` y `level_9.tres` con las 7 torres y, de momento, las tres `WaveData` del nivel 6. Registrarlos en `GameData.tscn`, detrás del nivel 6. El equilibrado de sus oleadas queda para otro ticket.
6. Ejecutar el generador y comprobar que el proyecto carga sin errores en headless (agente `probador`).

## Archivos que toca
- scripts/tools/space_decoration.gd
- resources/map_data/level_1.txt … level_9.txt (nuevos); se borran level_5_decor.txt y level_6_decor.txt
- scenes/maps/espacio/Level1_espacio.tscn … Level9_espacio.tscn
- resources/level_data/level_1.tres … level_9.tres
- resources/wave_data/level_1*.tres … level_6*.tres (solo `path_index`)
- scenes/GameData.tscn
- docs/design/niveles.md (tablas de niveles y centrado, decoración, generador, "Dudas") y docs/design/base.md (quitar la duda de que los caminos no llegan a la estación)

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5): en la selección de nivel tienen que salir 9 niveles.
2. Entrar en cada nivel. El mapa llena el área entre las dos barras, sin franjas de fondo vacío, y la estación está en la posición de la tabla.
3. En los niveles 4, 8 y 9, comprobar que las dos mitades del mapa se ven iguales (en el 9, también la de arriba y la de abajo).
4. Lanzar las tres oleadas sin poner torres. Los enemigos entran desde fuera de la pantalla, recorren todas las rutas del esquema y desaparecen al tocar la estación.
5. Colocar torres en planetas de varias zonas: solo se puede construir en los planetas, no en el camino ni en las rocas.
