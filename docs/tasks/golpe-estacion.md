# Aviso visual cuando un enemigo golpea la estación

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Cuando un enemigo llega al final, la estación pierde vida sin que se note: el escudo que parpadeaba está desactivado (`Shield.visible = false`) y solo cambia el número de la barra izquierda. Es fácil no darse cuenta de que se escapan enemigos.

## Qué hay que hacer
- En `Base.take_damage` (si no la destruye): destello rojo del sprite de la estación (~0,2 s con un tween de `modulate`, volviendo a blanco), como el `flash()` de los enemigos.
- En la barra izquierda, `Sidebar.set_station_health`: si la vida baja respecto a la anterior, la barra y el número parpadean en el color de peligro un momento y vuelven a su color normal (o al de peligro si ya está por debajo del 30 %).
- No tocar el escudo ni los mapas.
- Actualizar docs/design/base.md y docs/design/ui.md.

## Archivos que toca
- scripts/entities/Base.gd
- scripts/level_ui/Sidebar.gd
- docs/design/base.md, docs/design/ui.md

## Cómo se prueba a mano
1. F5, nivel 1, lanzar la oleada sin colocar torres.
2. Cada enemigo que llega a la estación la hace destellar en rojo y la barra de vida de la izquierda parpadea.
3. Al reiniciar el nivel, la barra empieza llena sin parpadear.
