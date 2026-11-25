# Esquinas de la orilla que también se vean curvas

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La orilla de rocas ya sigue la curva en las curvas del camino. Pero en los bordes y esquinas por donde las naves no giran (por ejemplo, junto a cruces, ramas o el principio y el final de un camino), la orilla sigue viéndose en ángulo recto y debería verse curva también.

## Qué hay que hacer
- **Antes de empezar, pedir al usuario una referencia visual** (una captura marcando a qué bordes o esquinas se refiere) y esperarla. No tocar nada hasta tenerla: con ella se decide qué esquinas cambian.
- Con la referencia, hacer que esos bordes y esquinas se vean curvos, con el mismo criterio que la orilla de las curvas (`_place_bend_edges`): piezas variadas cuyo borde sigue una curva, sin filas de piedrecitas.
- Cambiarlo en el generador y regenerar todos los mapas con él (`godot --headless --path . -s scripts/tools/map_generator.gd`), nunca a mano. Que los caminos, las curvas de las naves y las casillas de torreta no cambien.

## Qué leer
- docs/design/niveles.md › "Generador de mapas" y "Mapas de los niveles"
- scripts/tools/map_generator.gd › cabecera (constantes de la orilla de las curvas), `_place_bend_edges()`, `_place_bend_run()` y `_place_edge_side()`

## Archivos que toca
- scripts/tools/map_generator.gd
- scenes/maps/levels/*.tscn y scenes/maps/Navedex*.tscn (los regenera el generador)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Abrir un nivel con las esquinas que marcó el usuario en la referencia.
2. Esas esquinas y bordes deberían verse curvos, como la orilla de las curvas.
3. Las naves siguen el mismo camino y los huecos de torreta no se han movido.
