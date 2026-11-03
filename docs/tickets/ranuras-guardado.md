# Tres ranuras de guardado

Creador: D4MC04
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Hoy todo el progreso vive en un solo `user://progress.cfg`. Para la nueva pantalla de inicio hacen falta 3 partidas guardadas independientes, con un resumen de cada una. Este ticket es solo la parte de datos, sin UI.

## Qué hay que hacer
- `GameState` guarda cada partida en su propio archivo: `user://saves/slot_1.cfg`, `slot_2.cfg` y `slot_3.cfg` (`SLOT_COUNT = 3`). Todo lo que hoy va en `progress.cfg` pasa a ser de la ranura: `current_level`, `tutorial_done`, `seen_enemies`, `stats`, `fused_turrets`, `unlocked` y `play_time`. `Settings` no cambia: las opciones siguen siendo comunes a todas las partidas.
- Ranura activa: `active_slot: int` (0 = ninguna, al arrancar el juego). `load_slot(slot)` carga esa ranura (si el archivo no existe, empieza una partida nueva con los valores por defecto) y la deja activa. Mientras no hay ranura activa, `_save()` no escribe nada.
- Cada guardado escribe también `saved_at` (`Time.get_unix_time_from_system()`).
- `has_save(slot) -> bool` y `delete_slot(slot)` (borra el archivo; si era la activa, la deja sin ranura y con los valores por defecto).
- `get_slot_summary(slot) -> Dictionary` lee el archivo sin cargarlo en la partida activa y devuelve: `saved_at`, `play_time`, `sector` (el `current_level`, el nivel más alto desbloqueado), `achievements` (cuántos de `unlocked`) y `achievements_total` (`ACHIEVEMENTS.size()`). Vacío si no hay partida.
- Migración: si existe el `progress.cfg` antiguo y no hay ninguna ranura, se copia a `slot_1.cfg` (con `saved_at` = ahora) y se borra el antiguo, para no perder el progreso de nadie. Mantener la migración de nombres que ya hace `_ready` (`fused_towers` → `fused_turrets`, etc.).
- `reset_progress()` sigue funcionando sobre la ranura activa.
- Mientras no haya pantalla de ranuras (ticket `pantalla-inicio-ranuras`), `MainMenu._ready` llama a `GameState.load_slot(1)` si no hay ranura activa, para que el juego se pueda seguir jugando. Ese ticket quitará la llamada.

## Qué leer
- docs/design/flujo.md › tabla de autoloads (`GameState`) y el párrafo de `progress.cfg`
- docs/design/menu.md › "Logros"
- scripts/autoloads/GameState.gd › `_ready()`, `_save()`, `reset_progress()`, `_load_list()`
- scripts/screens/MainMenu.gd › `_ready()`

## Archivos que toca
- scripts/autoloads/GameState.gd
- scripts/screens/MainMenu.gd (solo la línea de `load_slot(1)`)
- docs/design/flujo.md
- docs/design/menu.md (sección "Logros": dónde se guardan)

## Cómo se prueba a mano
1. Con progreso ya guardado del juego antiguo, abrir el juego: los niveles desbloqueados, los logros y las stats siguen igual (migrado a la ranura 1).
2. En `%APPDATA%/Godot/app_userdata/Astro Artillery/saves/` está `slot_1.cfg` con `saved_at`, y `progress.cfg` ya no está.
3. Ganar un nivel y cerrar: al volver a abrir, el progreso sigue ahí.
