# Renombrar "tower" a "turret" en código y assets

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
La terminología del proyecto pasa a ser "turret", y ya se usa en `resources/turret_data/` y en `assets/audio/effects/Turrets/`. Pero "tower" sigue apareciendo 529 veces en 143 archivos de scripts/, scenes/ y resources/, y también en nombres de assets.

## Qué hay que hacer
- **Hacerlo cuando no haya otro ticket en curso.** Toca casi todo el proyecto y chocaría con cualquier rama abierta.
- **Clases y archivos** (con su `.uid` y sus referencias en `.tscn` y `.tres`):
  - `Tower` → `Turret`: `scripts/entities/Tower.gd` y `scenes/entities/Tower.tscn`.
  - `TowerData` → `TurretData`: `scripts/resources/TowerData.gd`.
  - `TowerButton` → `TurretButton`: `scripts/level_ui/TowerButton.gd` y `scenes/level_ui/TowerButton.tscn`.
  - `scripts/tools/make_tower_slot_tiles.gd` → `make_turret_slot_tiles.gd`.
- **Identificadores:** variables, funciones, señales, constantes y nodos que contengan `tower`/`Tower`/`TOWER`. Por ejemplo `towers`, `_tower`, `selected_tower_changed`, `sellable_tower`, `TowersPage`, `TowerSlots`, `PICK_TOWER`, `TOWER_SLOT_SHAPES` y `TileSetAtlasSource_tower_slots`. Actualizar también sus referencias en `.tscn` y `.tres` (conexiones de señales, `%UniqueName`, rutas de nodo).
- **Acciones de input:** `select_tower_1` … `select_tower_7` → `select_turret_N` en project.godot y en el código.
- **Opción guardada:** `show_tower_range` → `show_turret_range` en `Settings.gd` y `OptionsMenu.gd`. Si el archivo de opciones guardado trae la clave vieja, leerla una vez para no perder el valor del jugador.
- **Assets:**
  - `assets/sprites/towers/` → `assets/sprites/turrets/` (498 archivos, que usan 69 `sprite_frames` y más recursos).
  - `assets/ui/tab_towers.png` → `tab_turrets.png`.
  - `assets/audio/effects/Turrets/Tesla/CharginTower.wav` → `CharginTurret.wav`.
  - Moverlos con `git mv` junto a su `.import`, y actualizar todas las rutas `res://` (grep en .gd, .tscn y .tres). No cambiar los `uid=` ni los `id` de `ext_resource`.
- Ojo: ya existe una torreta concreta llamada "Turret" (`turret_data/turret.tres`, `Turrets/Turret/`). La clase `Turret` es la de todas las torretas; no confundirlas al renombrar.
- Docs y tickets: actualizar los nombres de clase, archivos y rutas en docs/design/*.md, DESIGN.md y en los tickets abiertos de la carpeta de tickets que los citen (`Tower.gd`, `TowerData`…). Los textos en español ("torre") no se tocan.
- Al acabar, `git grep -i tower` (fuera de la carpeta de tickets) no debería dar resultados.

## Archivos que toca
- scripts/** (Tower.gd, TowerData.gd, TowerButton.gd, make_tower_slot_tiles.gd y unos 30 más)
- scenes/** (Tower.tscn, TowerButton.tscn, LevelUI y mapas)
- resources/** (turret_data, sprite_frames, level_data, tilesets…)
- project.godot
- assets/sprites/towers/, assets/ui/tab_towers.png, assets/audio/effects/Turrets/Tesla/CharginTower.wav
- docs/design/*.md, docs/DESIGN.md y los tickets abiertos

## Cómo se prueba a mano
1. Abrir el proyecto en Godot: sin errores de recurso o script perdido.
2. F5, nivel 1: las torretas se ven en la barra lateral y se pueden comprar con clic y con las teclas 1-7, colocar, seleccionar, ver su rango y vender.
3. Disparan y suenan como antes. La Tesla suena con su carga, si `audio-torres` ya está en main.
4. Opciones: "mostrar rango" conserva el valor que tenía antes del cambio.
5. El menú principal muestra el puesto avanzado con sus torretas.
