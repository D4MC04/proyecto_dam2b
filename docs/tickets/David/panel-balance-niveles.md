# Panel de balanceo: pestaña Niveles y oleadas editables

Estado: aceptada
Espera a: panel-balance-torretas-enemigos
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Para balancear los niveles hay que ver juntos el dinero, la vida y las recompensas de cada oleada, y poder cambiar las oleadas sin tocar `.tres` ni tablas de GDScript a mano. Las oleadas pasan a editarse directamente en sus `.tres` desde el panel y `make_waves.gd` deja de usarse.

## Qué hay que hacer
- Requiere el panel de `panel-balance-torretas-enemigos` (base en `tools/balance/`, con su lector y escritor de `.tres`, ya en main).
- **Tabla de niveles**: una fila por `resources/level_data/*.tres` (1-9 y emergencia). Columnas:
  - `starting_money` (editable).
  - Torretas disponibles (solo se ven).
  - Número de oleadas, recompensa total y vida total.
- **Detalle de un nivel** (al pulsar su fila): una fila por oleada (`resources/wave_data/level_N[_K].tres`). Columnas:
  - `health_multiplier` (editable).
  - Número de naves, recompensa de la oleada y vida total (`count` × `hp` × `health_multiplier`, contando los trozos de `split_into`).
  - Duración de la salida, calculada con `spacing` y `pause_after`.
  - Ratio dificultad/dinero con la estimación de niveles.md › "Dificultad frente a dinero" (construyendo). Colorear por encima de 1.
- **Grupos de una oleada**: tabla editable con enemigo (desplegable de `resources/enemy_data/`), `count`, `spacing`, `pause_after` y `path_index`. Se pueden añadir, quitar y reordenar grupos.
  - Un grupo nuevo es un `sub_resource` con id nuevo y se añade al array `groups`.
  - Una nave que la oleada no usaba es un `ext_resource` nuevo (con id nuevo).
  - Los ids y `uid` que ya existen no se tocan.
  - Al cambiar cualquier dato se recalculan las columnas de la oleada y del nivel.
- **Retirar `make_waves.gd`**: los `.tres` de `resources/wave_data/` pasan a ser los datos de verdad de las oleadas.
  - Borrar `scripts/tools/make_waves.gd` y su `.uid`.
  - Comprobar con Grep que nada más lo usa.
- En docs/design/niveles.md › "Generador de oleadas": quitar lo del generador y las tablas (`LEVELS`, `LEVEL_1..4`, `HAND_LEVELS`, presupuestos, semillas) y decir que las oleadas se editan en sus `.tres` con el panel. Mantener "Dificultad frente a dinero" (es lo que calcula el panel) y la tabla de niveles.
- En los tickets de `docs/tickets/*/` con `Estado: propuesta` que mencionan `make_waves.gd`, `LEVELS` o `LEVEL_N`: cambiar esos pasos por "añadir la nave a las oleadas del nivel N con el panel (pestaña Niveles)" y quitar `make_waves.gd` de "Archivos que toca". Los tickets aceptados no se tocan.
- Ampliar la sección del panel en docs/CLAUDE-CODE.md con la pestaña Niveles.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Datos de nivel", "Generador de oleadas", "Dificultad frente a dinero"
- scripts/resources/LevelData.gd, WaveData.gd (`get_entries()`), SpawnGroup.gd
- resources/wave_data/level_1_3.tres y resources/level_data/level_1.tres (formato)
- tools/balance/ (lo que dejó el ticket de la base)

## Archivos que toca
- tools/balance/*.js, tools/balance/index.html
- scripts/tools/make_waves.gd (se borra)
- docs/design/niveles.md
- docs/CLAUDE-CODE.md
- docs/tickets/*/ (los que estén en propuesta y mencionen make_waves)

## Cómo se prueba a mano
1. Abrir el panel, elegir la carpeta del juego y entrar en Niveles: deberían salir los 9 niveles y el de emergencia con su dinero, sus oleadas y sus totales.
2. Abrir el nivel 1, oleada 3: subir el `count` del primer grupo de 3 a 6, añadir un grupo de Wasps y guardar.
3. Jugar el nivel 1 hasta la oleada 3: deberían salir 6 naves en el primer grupo y el grupo nuevo al final. La pestaña Oleadas del juego debería enseñar lo mismo.
4. Godot debería cargar `level_1_3.tres` sin errores y `git diff` no debería cambiar ningún `uid` ni id que ya existiera.
