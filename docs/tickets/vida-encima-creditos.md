# Vida de la estación arriba, junto a los créditos

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
La vida y el dinero son la información esencial del jugador y ahora están separadas: los créditos arriba y la vida de la estación abajo del todo, encima del pie.

## Qué hay que hacer
- Mover `StationBox` (con su `StationMargin`) arriba de la barra derecha, encima de `CreditsHeader`, visible con cualquier pestaña.
- Darle visuales a juego con `CreditsHeader`: mismo tipo de recuadro (`PanelContainer` con `StyleBoxFlat` propio y mismos márgenes), icono a la izquierda, "ESTACIÓN" y el valor a la derecha, y la barra de vida. Que vida y créditos se lean como un solo bloque (mismo ancho, separación y alturas coherentes), cada uno con su color (ámbar el dinero, cian la vida, rojo de peligro con poca vida).
- Mantener el comportamiento de `set_station_health` (rojo bajo el 30 %, destello rojo al recibir daño) y la viñeta de vida baja.
- Comprobar que la rejilla de torretas y la pestaña Oleadas siguen cabiendo (el scroll absorbe la diferencia) y que el pie de oleadas queda bien sin la vida encima.
- Si hace falta un icono de vida, 16x16 como `stat_icons/cost.png`, siguiendo docs/design/art.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Sidebar", "Vida de la estación" y "Pie de la barra"
- docs/design/art.md (solo si se dibuja un icono)
- scripts/level_ui/Sidebar.gd › `set_station_health()`, `_station_style()`
- scenes/level_ui/Sidebar.tscn › `CreditsHeader`, `StationMargin/StationBox`

## Archivos que toca
- scenes/level_ui/Sidebar.tscn
- scripts/level_ui/Sidebar.gd
- assets/ui/stat_icons/ (solo si hace falta un icono)
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 2.
2. Arriba de la barra derecha se ve la vida de la estación y justo debajo los créditos, con el mismo estilo, en las dos pestañas.
3. Dejar pasar naves: la barra baja, destella en rojo y bajo el 30 % se queda roja.
