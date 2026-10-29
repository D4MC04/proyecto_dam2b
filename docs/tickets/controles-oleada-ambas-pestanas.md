# Créditos y controles de oleada en las dos pestañas

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los créditos solo se ven en la pestaña Torretas e INICIAR, AUTO y ×1/×2 solo en Oleadas, así que hay que cambiar de pestaña para lanzar una oleada o ver cuánto dinero hay.

## Qué hay que hacer
- En `Sidebar.tscn`, sacar `CreditsHeader` de `TurretsPage` y `WaveControls` (con `NextWaveButton`, `AutoWaveButton` y `SpeedButton`) de `WavesPage` y ponerlos en `Content`, fuera de las páginas, para que se vean con cualquier pestaña: créditos arriba (debajo de `TabBar`) y los controles abajo (encima de `StationMargin`). No cambiar `uid` ni `unique_id`.
- Actualizar las rutas de esos nodos en `Sidebar.gd` y donde más se usen (`@onready`, `%`, `get_node`).
- Comprobar que todo cabe en los 508 px útiles en las dos pestañas: en Torretas la rejilla tiene scroll; en Oleadas la oleada con más tipos de enemigo no debe salirse.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Sidebar", "Pestaña Oleadas" (punto "Controles")
- scenes/level_ui/Sidebar.tscn › `Content`, `CreditsHeader`, `WaveControls`
- scripts/level_ui/Sidebar.gd › `_ready()`, `_style_wave_controls()`, `set_money()`

## Archivos que toca
- scenes/level_ui/Sidebar.tscn
- scripts/level_ui/Sidebar.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar un nivel con muchos tipos de enemigo en una oleada (p. ej. el 10).
2. En la pestaña Torretas: se ven los créditos e INICIAR, AUTO y ×1; pulsar INICIAR lanza la oleada.
3. Cambiar a Oleadas: siguen los créditos y los tres botones, y la rejilla de enemigos no se sale de la barra.
4. Las teclas Espacio, A y F siguen funcionando.
