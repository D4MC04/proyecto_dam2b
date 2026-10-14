# Tarea: derrota rediseñada

Duodécima tarea del rediseño de la UI de nivel (plan en `ui_task_plan.md`). La 11 (ajustes en pausa) se ha saltado: los ajustes llegarán más tarde con otro menú.

Necesita hechas `pantallas` (tarea 8) y `pausa` (tarea 10), que deja en `OverlayScreen` el marco común con `@export` de acento y oscurecido, el selector `>` y el bloqueo de la selección con una pantalla abierta. Si la 9 (`ganar`) ya está hecha, el nivel ya acaba una sola vez; si no, esta tarea lo añade para la derrota.

La derrota pasa a tener su propia personalidad (señal perdida, en rojo): el juego entra en cámara lenta, se corta con un glitch y aparece el panel con un resumen de la partida. Ese resumen es un componente que reutilizará la victoria en la tarea 13.

## Punto de partida (en la rama)

- `Level` emite `lost` desde `_lose()`, conectado a `spawner.enemy_reached_end`, con el primer enemigo que llega al final.
- `Game._on_level_lost()` llama a `ui.set_state(LevelUI.UiState.LOST)`, que enseña `GameOverScreen` y pausa el árbol al momento.
- `GameOver.tscn` hereda de `OverlayScreen.tscn` sin script propio: "GAME OVER" con Reiniciar (`RESTART`) y Salir (`QUIT`). Tras la tarea 10 tiene el marco rojo `#ff3c5a`.
- `LevelState` guarda el dinero, pero nadie cuenta los enemigos destruidos ni el dinero gastado. La oleada actual la da `Spawner.get_wave_index()`.
- `Base` tiene vida y la señal `destroyed`, pero nadie la usa. La vida de la base sigue fuera de esta tarea.

## Qué hay que hacer

### Secuencia de derrota

1. **Cámara lenta antes de pausar.**
   - Al pasar a `LOST`, el juego no se congela de golpe. `Engine.time_scale` baja de 1 a 0,2 aproximadamente en algo más de 1 s de tiempo real, con una curva suave.
   - Después vuelve a 1, el árbol se pausa y entra la pantalla.
   - Las duraciones y el valor mínimo son constantes con nombre.
   - El tween de la cámara lenta usa tiempo real (que no se frene a sí mismo) y sigue funcionando con el árbol en pausa.
2. **Sigue mandando `set_state()`.** `LevelUI.set_state()` sigue siendo lo único que escribe `get_tree().paused` y ahora también `Engine.time_scale`.
   - Desde que se pasa a `LOST`, la selección de torre ya está bloqueada (tarea 10), aunque el árbol aún no esté en pausa.
   - Escape no hace nada en `LOST`, tampoco durante la cámara lenta.
   - Cualquier `set_state()` a otro estado durante la secuencia la cancela y deja `Engine.time_scale` en 1. `PLAYING` siempre lo deja en 1.
3. **El nivel acaba una sola vez y deja de aceptar órdenes.** Durante la cámara lenta los enemigos siguen moviéndose, así que:
   - `Level` emite `lost` una sola vez aunque lleguen más enemigos al final. Si la tarea 9 ya lo hace, no se duplica.
   - Una vez perdido, el nivel no puede ganarse.
   - Al perder, `BuildManager` deja de colocar torres y de enseñar la vista previa. El nivel deja de construir, sin depender de la UI.
   - Los enemigos que mueran durante la cámara lenta pueden sumar al recuento, pero no cambian el resultado.

### Pantalla de derrota

4. **Aspecto** (dentro del marco común, acento rojo `#ff3c5a`):
   - Título "SEÑAL PERDIDA" en rojo. PressStart2P dibuja mal algunas mayúsculas con tilde; si la Ñ sale mal, se usa "ESTACION PERDIDA" y se avisa a David.
   - Oscurecido con un tinte rojo muy oscuro en vez de negro puro, alrededor del 60 %.
   - Opciones: **Reintentar** (`RESTART`) y **Menú** (`QUIT`).
   - El resumen de partida va entre el título y las opciones (ver abajo).
5. **Glitch de entrada.**
   - Durante 0,4 a 0,6 s, el área de juego se corta con estática y líneas horizontales desplazadas, y el título y el panel parpadean.
   - Después el panel se queda estable. Quedan unas líneas de estática muy tenues y, cada pocos segundos, un parpadeo corto del título.
   - Todo en pixel art: líneas de 1 px o múltiplos, sin desenfoque ni antialiasing.
   - Solo afecta al área de juego. Las barras no se tocan y siguen activas para inspeccionar.
   - Puede ser un shader de `canvas_item` en un `ColorRect` o algo dibujado a mano. Es parte de la escena de derrota, no de la base.
6. La pantalla de derrota tiene su propio script, que extiende `OverlayScreen`, para el glitch y el resumen. Sigue sin conectar botones a mano.

### Resumen de partida (componente reutilizable)

7. **Datos.**
   - `LevelState` lleva la cuenta de lo que pasa en la partida: enemigos destruidos y dinero gastado. Este último se suma en `spend_money`.
   - Se reinicia solo, porque al reiniciar se crea un `LevelState` nuevo.
   - Un objeto pequeño de datos (por ejemplo `RunStats`, `RefCounted`) junta la oleada alcanzada, el total de oleadas, los enemigos destruidos y el dinero gastado. `Level` lo construye con una función (por ejemplo `get_run_stats()`).
8. **Paso a la UI.** `Game`, al recibir `lost`, pasa ese objeto a la UI antes o junto con `set_state(LOST)`. La UI no lee el `Level` ni el `LevelState` por su cuenta para esto.
9. **Componente `RunSummary`** (`scenes/level_ui/RunSummary.tscn` + script). Recibe un `RunStats` y pinta tres filas:
   - Oleada: "X/Y".
   - Enemigos destruidos.
   - Dinero gastado, con €.
   - Cada fila lleva un icono de 8x8 y el valor, con el estilo de las filas de la ficha (fondo alterno, tooltip con el nombre).
   - Los números usan `UiFormat`.
   - Tiene `@export` de color de acento para que la victoria lo use en ámbar.
   - No depende de la pantalla de derrota.
10. **Iconos nuevos** de 8x8 en `assets/ui/stat_icons/`: `wave.png` (oleada) y `kills.png` (enemigos destruidos), con el estilo de los existentes. El dinero reutiliza `cost.png`.
11. **Estética:** queremos que la derrota quede bonita y cuidada, en pixel art y con la paleta de `docs/design/art.md`. Lo que no convenza se apunta y se corrige en la fase de estilo final.

## Criterios de hecho

**Código**
- [ ] `LevelUI.set_state()` es lo único que escribe `get_tree().paused` y `Engine.time_scale`.
- [ ] Las duraciones y el `time_scale` mínimo de la cámara lenta son constantes, y el tween usa tiempo real.
- [ ] Pasar a `PLAYING` (reiniciar o salir) deja siempre `Engine.time_scale` en 1.
- [ ] `Level` emite `lost` una sola vez por partida y, tras perder, no emite victoria ni deja construir.
- [ ] `LevelState` cuenta enemigos destruidos y dinero gastado. Existe un objeto de datos con oleada alcanzada, total, enemigos y dinero, construido por `Level`.
- [ ] `Game` pasa ese objeto a la UI; la UI no lee el nivel por su cuenta.
- [ ] Existe `scenes/level_ui/RunSummary.tscn`, sin dependencias de la pantalla de derrota y con `@export` de acento.
- [ ] El glitch está en la escena de derrota (o su script), no en `OverlayScreen`.
- [ ] Existen `assets/ui/stat_icons/wave.png` y `kills.png`.
- [ ] `GameOver.tscn` sigue heredando de `OverlayScreen.tscn` y conserva su `uid=`.
- [ ] No se ha cambiado ningún `uid=` ni ningún id de `ext_resource` existente.
- [ ] Código tipado y con los nombres en inglés.
- [ ] El proyecto carga sin errores en headless.

**Juego**
- [ ] Al dejar llegar un enemigo al final, el juego se frena poco a poco durante algo más de un segundo y luego se congela.
- [ ] Después llega el glitch en el área de juego y aparece el panel rojo "SEÑAL PERDIDA" (o el título alternativo) con el resumen, Reintentar y Menú.
- [ ] Durante la cámara lenta no se puede colocar ni seleccionar una torre, y Escape no hace nada.
- [ ] Si llegan más enemigos al final durante la cámara lenta, la secuencia no se repite ni se reinicia.
- [ ] El resumen enseña la oleada correcta ("1/1" en los niveles actuales), los enemigos destruidos y el dinero gastado en torres. Comprobar comprando, por ejemplo, dos Cañones dobles al empezar y dejando pasar un enemigo: el dinero gastado es el doble de su coste.
- [ ] Tras el glitch, el panel se queda estable, con estática tenue y algún parpadeo ocasional del título.
- [ ] Las barras siguen activas: clic derecho en una torre o en un enemigo de la pestaña Oleadas enseña su ficha.
- [ ] Reintentar vuelve a empezar el nivel a velocidad normal y, al perder otra vez, el resumen empieza desde cero.
- [ ] Menú lleva a la selección de nivel, y al entrar en otro nivel el juego va a velocidad normal.
- [ ] La pausa sigue como en la tarea 10 y no se ve afectada por el glitch ni por la cámara lenta.

**Documentación**
- [ ] `docs/design/ui.md` describe la secuencia de derrota (cámara lenta, pausa y glitch), la pantalla de derrota y `RunSummary`. La tabla de comunicación está actualizada.
- [ ] `docs/design/niveles.md` explica los contadores de `LevelState`, el objeto de resumen y que tras perder el nivel no construye ni puede ganarse.
- [ ] `docs/design/flujo.md` actualiza el apartado de derrota.
- [ ] `docs/design/art.md` lista los iconos nuevos.
- [ ] Este archivo de tarea está borrado.
