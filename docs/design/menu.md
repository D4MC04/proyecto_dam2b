# Menú principal y música

## Escena y script

`scenes/MainMenu.tscn` + `scripts/screens/MainMenu.gd`. Es la escena inicial del proyecto.

Nodos, de fondo a frente:

- `Background`: `ColorRect` negro.
- `StarField`, `Comets`, `Asteroids`, `Satellites`, `Planets`: decoración (ver abajo).
- `TitleScreen`: título "ASTRO ARTILLERY" y botones "Jugar", "Opciones" y "Salir".
- `LevelSelectionScreen` (oculto al empezar): texto "SELECCIONA UN NIVEL", `LevelButtonsContainer` (`GridContainer` de 5 columnas) y botón "Volver".
- `VolumePanel`: etiqueta "MUSICA", botón de silencio ("ON"/"OFF") y deslizador de 0 a 1 en pasos de 0,05.

## Comportamiento

- "Jugar" y "Volver" cambian entre las dos pantallas con un fundido de 0,25 s de salida y otro de entrada.
- "Salir" cierra el juego.
- Si `start_on_level_selection` es `true` (lo pone `Game` al volver de un nivel), el menú abre directamente en la selección de nivel.
- `_build_level_buttons()` crea un `LevelButton` de 40x40 por cada entrada de `GameData.levels`, numerado desde 1 y desactivado si `GameState.is_unlocked(i)` es `false`.
- `LevelButton` (`scripts/level_ui/LevelButton.gd`) emite `level_selected(data)` al pulsarse.
- `_open_level(data)` instancia `scenes/Game.tscn`, le asigna `level_data` y la pone como escena actual.

## Decoración

Todos son `Node2D` que dibujan o crean sprites por código, con posiciones y tiempos al azar.

| Nodo | Script | Qué hace |
|---|---|---|
| `StarField` | `scripts/main_menu/Starfield.gd` | 77 estrellas de 1 px en tres brillos (un 30 % parpadea) y 6 destellos de cuatro puntas en blanco, cian, morado o naranja |
| `Comets` | `scripts/main_menu/Comets.gd` | Cada 1,5 a 4 s cruza un cometa en diagonal suave por la franja superior o inferior, a 220 px/s, con estela |
| `Asteroids` | `scripts/main_menu/Asteroids.gd` | Hasta 2 asteroides a la vez cruzan de un borde al opuesto a 60 px/s, con estela; aparece uno cada 3 a 7 s |
| `Satellites` | `scripts/main_menu/Satellites.gd` | Un satélite cada vez, a 20-30 px/s y girando despacio; el siguiente sale entre 8 y 15 s después de irse el anterior |
| `Planets` | instancias de `scenes/SpaceBody.tscn` | 6 planetas animados fijos y un asteroide oculto |

`scripts/main_menu/SpaceBody.gd` es un `AnimatedSprite2D` con `@tool` que construye su `SpriteFrames` a partir de `sheet`, una tira horizontal de frames cuadrados (lado = alto de la imagen), a la velocidad `fps`. Lo usan los planetas del menú y los asteroides.

## Música

`scripts/autoloads/MusicManager.gd`, autoload de tipo `AudioStreamPlayer`.

- Carga `assets/audio/music/theme.mp3`, la pone en bucle y la reproduce al arrancar. Si el archivo no existe, avisa y no suena nada.
- `process_mode = ALWAYS`: sigue sonando con el juego en pausa. Al ser autoload no se corta al cambiar de escena.
- `set_volume(v)` (0 a 1) y `toggle_mute()`. El estado está en las variables `volumen` y `muteado`.

Es el único audio del juego: no hay efectos de sonido.

## Dudas

- El botón "Opciones" (`SettingsButton`) no tiene ninguna señal conectada.
- El control de volumen solo existe en el menú principal; el menú de pausa no lo tiene.
- El volumen y el silencio no se guardan entre ejecuciones.
- Los scripts de `scripts/main_menu/` y `MusicManager.gd` tienen variables sin tipo y nombres en español (`volumen`, `muteado`, `_aplicar`, `_actualizar`), al contrario de lo que pide `CLAUDE.md`. Lo mismo `scripts/level/Cometa.gd`.
