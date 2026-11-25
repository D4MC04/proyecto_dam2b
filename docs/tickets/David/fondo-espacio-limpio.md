# Fondo de espacio más limpio en la pantalla principal y la oficina

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El fondo de espacio de la pantalla principal y el ventanal de la oficina está demasiado cargado de cosas que pasan. Se quiere un fondo más limpio.

## Qué hay que hacer
- En la pantalla principal (`StartScreen`) y en el espacio de la oficina (`MainMenu` › `Space`), quitar:
  - La estación con sus torretas (`Outpost`) y las naves que cruzan disparándose (`Skirmish`).
  - El satélite (`Satellites`).
  - Las estrellas fugaces (`Comets` y el nodo `Comet` de `MenuBackground.tscn`).
  - Los asteroides que cruzan (`Asteroids`).
- Se queda lo demás: la nebulosa, el planeta con anillos y las estrellas fijas (`StarField`, que también hace el efecto del salto al hiperespacio).
- **Estrellas fugaces y asteroides:** guardar su código y sus assets para poder volver a ponerlos más adelante (por ejemplo, en una carpeta `archive/`, como `scenes/maps/archive/`). Sin usarlos en ninguna escena, pero el proyecto tiene que seguir cargando sin errores.
- **Estación, naves y satélite:** borrar sus scripts y los assets que solo usan ellos. Antes, comprobar con Grep que nada más los usa (por ejemplo, el sprite de estación o de cometa de los niveles se queda si lo usan los niveles).
- Quitar los `ext_resource` que se queden sin uso en las escenas, sin cambiar los uid= ni los id de los que se quedan.

## Qué leer
- docs/design/menu.md › "Fondo" y "Decoración"
- scenes/MainMenu.tscn › nodos hijos de `Space`
- scenes/StartScreen.tscn › nodos de fondo
- scenes/MenuBackground.tscn › nodo `Comet`

## Archivos que toca
- scenes/MainMenu.tscn, scenes/StartScreen.tscn, scenes/MenuBackground.tscn
- scripts/main_menu/Outpost.gd, Skirmish.gd, Satellites.gd (se borran)
- scripts/main_menu/Comets.gd, Asteroids.gd y sus assets (se archivan)
- scripts/screens/MainMenu.gd y StartScreen.gd (si los nombran)
- docs/design/menu.md

## Cómo se prueba a mano
1. Abrir el juego: en la pantalla principal solo deberían verse la nebulosa, el planeta y las estrellas fijas, sin nada que cruce.
2. Entrar en la oficina y mirar por el ventanal: tampoco deberían salir la estación, las naves, el satélite, las estrellas fugaces ni los asteroides.
3. Saltar a un sector: el efecto del hiperespacio sigue funcionando.
