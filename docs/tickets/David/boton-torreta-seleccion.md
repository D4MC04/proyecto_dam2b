# Botón de torreta: mejor aspecto al seleccionarlo

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El cambio que hace el botón de una torreta de la barra al seleccionarlo se ve feo.

## Qué hay que hacer
- **Antes de empezar, pedir al usuario la referencia visual** de cómo lo quiere y esperarla. No tocar nada hasta tenerla.
- Con la referencia, rehacer el aspecto del estado seleccionado de `TurretButton` (y su hover estando seleccionado). Hoy usa `SELECTED_COLOR` `#ecb23c` y `SELECTED_HOVER_BORDER_COLOR` `#ffe082`.
- Que los demás estados (normal, hover, sin dinero, bloqueado) sigan igual, salvo que la referencia diga otra cosa.

## Qué leer
- docs/design/ui.md › "TurretButton"
- scripts/level_ui/TurretButton.gd › constantes `SELECTED_*` y `set_selected()`

## Archivos que toca
- scripts/level_ui/TurretButton.gd
- scenes/level_ui/TurretButton.tscn (si hace falta)
- docs/design/ui.md

## Cómo se prueba a mano
1. Empezar cualquier nivel y seleccionar una torreta de la barra derecha.
2. El botón seleccionado debería verse como en la referencia, también al pasar el ratón por encima.
3. Al soltarla, vuelve a su aspecto normal.
