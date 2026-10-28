# Desbloquear una torreta por nivel, con botones bloqueados

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Hoy cada nivel trae un grupo de torretas y los botones de las que faltan no salen. Con una torreta nueva por nivel y los 10 botones siempre a la vista, el jugador ve qué le falta por conseguir y en qué orden llega.

## Qué hay que hacer
- Orden de desbloqueo de las 10 torretas principales (la torreta N aparece en el nivel N):
  1. Cañón doble, 2. Minigun, 3. Cryo, 4. Cañón pesado, 5. Generadora, 6. Tesla, 7. Mortero (anillo), 8. Amplificador, 9. Disintegrator, 10. Rail.
  - El Rail es la 10.ª porque es la más de final de juego: llega con el nivel 10, que aún no existe. Mientras tanto, en el nivel 9 sale bloqueado.
- Una lista ordenada con las 10 torretas en un solo sitio (p. ej. `GameData`) y `LevelData.turrets` de cada nivel con las N primeras.
- La barra de compra crea siempre los 10 botones en ese orden (`Sidebar.build_buttons`). Los que no están desbloqueados en el nivel salen como silueta oscura del icono con un candado encima, o con un aire de "error / no reconocido" que encaje con la tablet. Si hace falta un icono de candado, en pixel art siguiendo docs/design/art.md.
- Los botones bloqueados no se pueden comprar ni seleccionar, no enseñan el coste y no cambian con el dinero.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Sidebar", "TurretButton"
- docs/design/niveles.md › "Datos de nivel"
- docs/design/art.md › "Paleta", "Contorno"
- scripts/level_ui/Sidebar.gd › `build_buttons()`
- scripts/level_ui/LevelUI.gd › donde llama a `sidebar.build_buttons(turrets)`
- scripts/level_ui/TurretButton.gd › `_refresh()`
- scripts/autoloads/GameData.gd

## Archivos que toca
- scripts/autoloads/GameData.gd, scenes/GameData.tscn
- scripts/level_ui/Sidebar.gd, scripts/level_ui/TurretButton.gd, scenes/level_ui/TurretButton.tscn
- scripts/level_ui/LevelUI.gd
- resources/level_data/level_*.tres (y el nivel 5 de `GameData.tscn`)
- assets/ui/ (icono de candado, si hace falta)
- docs/design/ui.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1: salen 10 botones; solo el Cañón doble se puede comprar y los otros 9 se ven bloqueados.
2. Jugar el nivel 5: las 5 primeras se pueden comprar en el orden de arriba y las otras 5 salen bloqueadas.
3. Pulsar una bloqueada no hace nada.
