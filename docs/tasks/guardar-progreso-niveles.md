# Desbloquear niveles al ganar y guardar el progreso

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
`GameState.current_level` vale 50 fijo, así que todos los niveles están abiertos y no se guarda nada (docs/design/flujo.md). Desbloquear al ganar da sensación de avance y hace que "SECTORES X/Y" del menú signifique algo.

## Qué hay que hacer
- `GameState.current_level` empieza en 1 y se carga de `user://progress.cfg` con `ConfigFile`, igual que `Settings` guarda `user://settings.cfg`.
- Al ganar un nivel, si es el más alto desbloqueado, subir `current_level` y guardar.
- "Siguiente nivel" en la victoria sigue funcionando (ya estará desbloqueado).
- Añadir en Opciones un botón "Borrar progreso" solo si es sencillo; si no, apuntarlo en el doc como pendiente.
- Actualizar docs/design/flujo.md y docs/design/menu.md.

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/ (donde `Game` gestiona `won`)
- docs/design/flujo.md, docs/design/menu.md

## Cómo se prueba a mano
1. Borrar `%APPDATA%/Godot/app_userdata/<proyecto>/progress.cfg` si existe.
2. Abrir `scenes/MainMenu.tscn` → selección de nivel: solo el nivel 1 abierto, "SECTORES 1/Y".
3. Ganar el nivel 1 y volver al menú: el nivel 2 abierto, "SECTORES 2/Y".
4. Cerrar el juego y abrirlo otra vez: el nivel 2 sigue abierto.
