# Botón de torreta bloqueada en rojo con "?"

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Las torretas bloqueadas salen como silueta oscura con un candado pequeño, y como todas las torretas tienen casi la misma silueta no aporta nada: no se ve de un vistazo que no se tienen.

## Qué hay que hacer
- En `TurretButton`, cambiar el estado bloqueado: no enseñar el icono (fuera la silueta) y pintar la caja en rojo (fondo oscuro rojizo y borde rojo, a partir del `#ff3c5a` de "sin dinero"), con un "?" grande centrado en el sitio del icono y debajo, donde iría el coste, "???" en rojo.
- El "?" se pinta en `_draw` con píxeles (como ahora `PADLOCK_PIXELS`) para que se vea grande y nítido. Quitar el candado y `PADLOCK_PIXELS` si dejan de usarse.
- El resto del comportamiento bloqueado no cambia (no selecciona ni enseña ficha).

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "TurretButton" (punto "Bloqueado")
- docs/design/art.md › paleta
- scripts/level_ui/TurretButton.gd › `setup()`, `_refresh()`, `_draw()`, `PADLOCK_PIXELS`

## Archivos que toca
- scripts/level_ui/TurretButton.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Jugar el nivel 1 (solo una torreta desbloqueada).
2. Los otros 9 botones salen en rojo con "?" y sin silueta.
3. Clic izquierdo y derecho sobre ellos no hacen nada; el botón desbloqueado se ve como siempre.
