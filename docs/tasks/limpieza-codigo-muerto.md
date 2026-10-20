# Limpieza: código que no se usa y detalles pequeños

Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Los docs de diseño apuntan varias cosas sueltas que sobran o están a medias. Ninguna rompe el juego, pero confunden a quien lee el código y algunas van contra CLAUDE.md.

## Qué hay que hacer
- Borrar funciones que nadie llama: `Tower.fit_to_tile`, `GameState.is_completed`, y `Grid.get_kind` y `Grid.path_cells` si de verdad no se usan fuera de `Grid` (comprobar con grep antes).
- `EnemyData.hp`: pasarlo de `int` a `float`, que es lo que guardan los `.tres` y usa `Enemy.hp`.
- `project.godot`: `config/name` de "DAM_Game" a "Astro Artillery" (es el título de la ventana).
- `MainMenu.gd`: poner tipo de retorno a las funciones que no lo tienen.
- Botón "Borrar progreso": si se pulsa, se confirma y se vuelve a pulsar enseguida, el temporizador viejo cancela el "¿Seguro?" antes de 3 s. Ignorar los temporizadores antiguos (por ejemplo, con un contador de pulsaciones).
- Quitar de los docs/design las dudas resueltas y la línea vieja de los `.tmp` en niveles.md (ya no existen).

## Archivos que toca
- scripts/entities/Tower.gd
- scripts/autoloads/GameState.gd
- scripts/level/Grid.gd
- scripts/resources/EnemyData.gd
- scripts/screens/MainMenu.gd
- scripts/screens/OptionsMenu.gd
- project.godot
- docs/design/torres.md, flujo.md, niveles.md, enemigos.md, menu.md

## Cómo se prueba a mano
1. Abrir el proyecto: la ventana del juego se llama "Astro Artillery".
2. F5 y jugar el nivel 1: todo funciona igual.
3. Opciones → "Borrar progreso" → pulsar, pulsar otra vez y enseguida pulsar una tercera: el "¿Seguro?" dura 3 segundos enteros.
