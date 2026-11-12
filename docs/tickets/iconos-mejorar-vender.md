# Iconos en Mejorar y Vender

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al seleccionar una torreta, Mejorar y Vender salen como texto. Con iconos se entiende de un vistazo y queda mejor.

## Qué hay que hacer
- **Mejorar (`UpgradeButton`):** en vez de la palabra "Mejorar", un icono de flecha verde hacia arriba. El precio sigue al lado ("-X€"). Apagado (sin dinero) se ve la flecha apagada.
- **Vender (`SellButton`):** en vez de la palabra "Vender", un icono de papelera con la tapa cerrada. El precio sigue al lado ("+X€").
- **Confirmar la venta:** el primer clic, en vez de cambiar el texto a "¿Seguro?", abre la tapa de la papelera (icono o animación corta de la tapa levantándose). El segundo clic vende, como ahora. Si se suelta la torreta sin el segundo clic, la tapa vuelve a cerrarse.
- Iconos 16x16 en pixel art, en `assets/ui/`, con el estilo de los iconos de interfaz (ver docs/design/art.md).
- Quitar de `translations/textos.csv` las claves que ya no se usen (`TURRET_UPGRADE_COST`, `TURRET_SELL_VALUE`, `TURRET_SELL_CONFIRM`) solo si nada más las usa.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "TurretActions (mejorar y vender)"
- docs/design/art.md › "Iconos de interfaz"
- scripts/level_ui/TurretActions.gd
- scenes/level_ui/TurretActions.tscn

## Archivos que toca
- scripts/level_ui/TurretActions.gd
- scenes/level_ui/TurretActions.tscn
- assets/ui/ (iconos nuevos de flecha y papelera cerrada y abierta)
- translations/textos.csv
- docs/design/ui.md, docs/design/art.md

## Cómo se prueba a mano
1. Jugar el nivel 1, colocar una torreta que tenga mejora y hacer clic en ella.
2. Encima salen la flecha verde con su precio y la papelera cerrada con su precio. Sin dinero suficiente, la flecha sale apagada.
3. Clic en la papelera: se abre la tapa y no vende. Segundo clic: vende.
4. Clic en la papelera y luego clic fuera: al volver a seleccionar la torreta, la papelera está cerrada.
