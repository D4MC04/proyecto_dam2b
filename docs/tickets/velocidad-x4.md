# Velocidad ×4 además de ×2

Creador: David
Responsable: David
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
A ×2 algunas oleadas siguen haciéndose largas. Un ×4 deja pasarlas rápido cuando la defensa ya aguanta sola.

## Qué hay que hacer
- `SpeedButton` pasa de alternar ×1/×2 a recorrer ×1 → ×2 → ×4 → ×1 en cada pulsación (y el atajo de teclado de `LevelUI._input`, que hoy invierte `button_pressed`, hace lo mismo).
- `LevelUI`: cambiar `_fast_speed: bool` por la velocidad elegida (×1, ×2 o ×4) y `FAST_SPEED` por las constantes de cada velocidad. `set_state` sigue siendo el único sitio que escribe `Engine.time_scale` (en `PLAYING`, la velocidad elegida; en el resto, 1). La pausa la conserva y `LOST`, `WON` y `_request_action` la devuelven a ×1, como ahora.
- `Sidebar`: la señal y `show_fast_speed` pasan a llevar la velocidad; el texto del botón es "×1", "×2" o "×4" y el estilo ámbar se ve en ×2 y ×4.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "LevelUI" (punto "Velocidad ×2") y el punto de `SpeedButton` en la barra lateral
- scripts/level_ui/LevelUI.gd › `FAST_SPEED`, `_fast_speed`, `_on_fast_speed_toggled()`, `_set_fast_speed()`, `set_state()` y el atajo de velocidad en `_input`
- scripts/level_ui/Sidebar.gd › `fast_speed_toggled`, `show_fast_speed()`, `_on_speed_toggled()`

## Archivos que toca
- scripts/level_ui/LevelUI.gd
- scripts/level_ui/Sidebar.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y lanzar una oleada.
2. Pulsar el botón de velocidad: pasa a "×2" (naves al doble), otra vez a "×4" (naves al cuádruple), otra vez a "×1".
3. Pausar con Escape a ×4 y reanudar: sigue a ×4. Perder o reiniciar: vuelve a "×1".
