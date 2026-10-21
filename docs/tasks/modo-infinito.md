# Modo infinito con récord de oleada

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Los niveles se acaban. Un modo de oleadas sin fin que cada vez aprietan más da rejugabilidad y un récord que batir.

## Qué hay que hacer
- Botón "Infinito" en la selección de nivel del menú principal. Usa un mapa que ya existe (el del nivel 3 o el que mejor quede, sin tocar mapas) y todas las torres.
- Oleadas generadas por código: cada vez que se limpia una, se genera la siguiente (más enemigos, más tipos y más duros según el número de oleada; los enemigos de `resources/enemy_data/`). `Spawner` nunca se queda sin oleadas en este modo: no hay victoria.
- La vida de los enemigos sube un poco por oleada (multiplicador al instanciarlos, sin cambiar los `.tres`).
- Al perder, la pantalla de derrota enseña la oleada alcanzada y el récord; si se bate, "¡NUEVO RÉCORD!".
- `GameState` guarda el récord en `progress.cfg` (validando lo leído) y "Borrar progreso" lo borra.
- La barra de oleadas enseña "OL. X" sin total en este modo.
- Actualizar docs/design/flujo.md, docs/design/niveles.md, docs/design/menu.md y docs/design/ui.md.

## Archivos que toca
- scripts/level/EndlessWaves.gd (nuevo: generador de oleadas)
- scripts/level/Spawner.gd
- scripts/screens/Game.gd, scripts/screens/MainMenu.gd + scenes/MainMenu.tscn (botón)
- scripts/autoloads/GameState.gd
- scripts/level_ui/GameOverScreen.gd, scripts/level_ui/Sidebar.gd (texto de oleada)
- docs/design/flujo.md, niveles.md, menu.md, ui.md

## Cómo se prueba a mano
1. F5, Jugar → Infinito.
2. Lanzar oleadas: cada una trae más naves y más duras; después de la 10 no se acaba.
3. Perder: la derrota enseña la oleada alcanzada y "¡NUEVO RÉCORD!". Reintentar y perder antes: enseña el récord anterior sin el aviso.
4. Opciones → Borrar progreso: el récord vuelve a 0.
