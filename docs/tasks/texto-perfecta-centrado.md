# Centrar el texto "PERFECTA +dinero" sobre la estación

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Al acabar una oleada sin daño, el texto "PERFECTA +X" sale desplazado a la izquierda de la estación en vez de centrado, y queda raro.

## Qué hay que hacer
- Averiguar por qué no sale centrado. `Level._award()` lo pone en `base.global_position + (0, -20)` y `FloatingText.spawn()` resta `label.size / 2`, pero calcula el tamaño (`reset_size()`) antes de añadir la etiqueta al árbol: es probable que mida mal el ancho. Comprobar también que `base.global_position` es el centro de la estación.
- Arreglarlo en `FloatingText` para que todos los textos flotantes queden centrados en su punto, sin romper los demás usos.
- Actualizar `docs/design/niveles.md` o `docs/design/ui.md` (donde se describa el texto flotante) si cambia algo.

## Archivos que toca
- scripts/entities/FloatingText.gd
- scripts/level/Level.gd (solo si el problema está en el punto)
- docs/design/niveles.md o docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1 y pasar la primera oleada sin que entre ningún enemigo en la estación.
2. El texto "PERFECTA +25" debería salir centrado justo encima de la estación.
3. Los textos de dinero al matar enemigos deberían seguir saliendo centrados sobre cada nave.
