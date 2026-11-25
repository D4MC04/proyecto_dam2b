# Vida de la estación: todo el recuadro cambia de color

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Con poca vida, la barra de la estación y su número se ponen rojos, pero el marco, el icono y el rótulo "ESTACIÓN" siguen azules, y se ve mal.

## Qué hay que hacer
- Cuando la barra cambie de color, que cambie todo el recuadro `StationHeader`: el borde del marco, el icono `station.png`, `ESTACIÓN`, el número y la barra (relleno y borde). Pasa en los dos casos en que cambia hoy:
  - En peligro (menos del 30 %, `STATION_DANGER_FRACTION`): todo en el rojo de peligro `#ff3c5a`. El fondo y el texto pueden ir en tonos de esa rampa roja si el rojo puro no se lee bien.
  - En el parpadeo al recibir un golpe (`STATION_HIT_TIME`): todo parte del rojo y vuelve a su color.
- Al subir de nuevo por encima del 30 %, todo vuelve al cian de siempre.

## Qué leer
- docs/design/ui.md › "Vida de la estación"
- scripts/level_ui/Sidebar.gd › `set_station_health()` y las constantes `STATION_*`
- scenes/level_ui/Sidebar.tscn › nodo `StationHeader` y sus hijos

## Archivos que toca
- scripts/level_ui/Sidebar.gd
- scenes/level_ui/Sidebar.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar cualquier nivel y dejar pasar naves hasta bajar del 30 % de vida.
2. Todo el recuadro de la estación (marco, icono, rótulo, número y barra) debería ponerse rojo a la vez.
3. Con cada golpe, todo el recuadro debería parpadear en rojo y volver a su color.
