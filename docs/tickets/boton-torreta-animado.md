# Botones de torreta con su animación de reposo

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los botones de torreta enseñan una imagen fija (`data.icon`, el `full_up.png`) en vez de la torreta con su animación de reposo, como se ve en el mapa.

## Qué hay que hacer
- En `TurretButton`, cambiar el `IconRect` estático por la torreta animada: la base (`data.sprite_frames`) y encima el cañón (`data.cannon`), los dos en su animación de reposo (`default`; la Minigun usa `spin` a la velocidad de reposo) en bucle, mirando hacia arriba, a escala 1 y en el mismo hueco de 32x32 que el icono actual.
- Las torretas sin cañón o sin animación salen con su primer frame, como ahora.
- Mantener los estados: sin dinero, al 35 % de opacidad; bloqueada, oculta sin perder el hueco.
- La ficha (`InfoPanel`) no cambia: sigue con `data.icon`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "TurretButton"
- docs/design/art.md › "Animación"
- scripts/level_ui/TurretButton.gd › `setup()`, `_refresh()`, nodo `IconRect`
- scripts/entities/Turret.gd › `_ready()` (cómo se montan `sprite` y `cannon` con `data.sprite_frames` y `data.cannon`)

## Archivos que toca
- scripts/level_ui/TurretButton.gd
- scenes/level_ui/TurretButton.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 9.
2. En la rejilla de torretas, Cryo, Tesla, Orbitador, Amplificador, Minero y Disintegrator se animan en bucle como en el mapa.
3. Sin dinero, el botón sale atenuado pero sigue animado; las bloqueadas no enseñan la torreta.
