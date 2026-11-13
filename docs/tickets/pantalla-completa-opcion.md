# La opción Pantalla completa no hace nada

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
En los ajustes, el pomo y el botón de Pantalla completa no cambian nada: aunque lo pongas en ON, la ventana se queda como está. La opción tiene que cambiar de verdad entre pantalla completa y ventana.

## Qué hay que hacer
- Encontrar la causa antes de cambiar nada. Hay tres sospechosas:
  - `project.godot` arranca en pantalla completa (`window/size/mode=3`, con `window_width_override` 1920x1080), pero `fullscreen` vale `false` por defecto en `Settings`. El juego empieza con lo que dice el proyecto y la opción enseña otra cosa.
  - `Settings._apply(&"fullscreen")` solo llama a `DisplayServer.window_set_mode`. Hay que comprobar que ese cambio llega a la ventana en Windows (el renderizador es d3d12) y que no lo pisa nada después.
  - Al probar con F5, Godot 4.7 mete el juego dentro del editor, y así la pantalla completa no tiene efecto (docs/design/menu.md › "Dudas"). Si es eso, que la opción se vea desactivada o lo avise cuando el juego va incrustado (`Engine.is_embedded_in_editor()`), y que funcione cuando el juego va en su propia ventana.
- Que lo que marca la opción coincida siempre con cómo está la ventana: al arrancar, al cambiarla y al volver a abrir el juego (se guarda en `Settings`).
- Tiene que funcionar igual desde el pomo de la consola de opciones del menú (`OptionsCloseUp`) y desde el botón de la pausa (`OptionsMenu`).
- Actualizar docs/design/menu.md (la parte de `Settings` y, si ya no aplica, la duda sobre el juego incrustado).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/menu.md › la sección de `Settings` (la línea "`fullscreen` y `vsync` se aplican con `DisplayServer`") y "Dudas"
- scripts/autoloads/Settings.gd › `_ready()`, `set_value()`, `_apply()`
- project.godot › `[display]` (`window/size/*`)
- scripts/main_menu/OptionsCloseUp.gd y scripts/screens/OptionsMenu.gd › dónde llaman a `Settings.set_value(&"fullscreen", ...)`

## Archivos que toca
- scripts/autoloads/Settings.gd
- project.godot (si la causa es el modo de arranque)
- scripts/main_menu/OptionsCloseUp.gd / scripts/screens/OptionsMenu.gd (si hay que desactivar o avisar)
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego en su propia ventana (no incrustado en el editor) y abrir las opciones en la consola del menú.
2. Poner Pantalla completa en ON: la ventana pasa a pantalla completa. En OFF, vuelve a ser una ventana.
3. Hacer lo mismo desde la pausa de un nivel.
4. Cerrar el juego y volver a abrirlo: arranca como quedó la opción, y la opción enseña lo mismo.
5. Con F5 dentro del editor: la opción funciona o se ve claro que ahí no se puede usar.
