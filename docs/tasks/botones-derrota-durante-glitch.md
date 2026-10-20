# Que los botones de la derrota no se puedan pulsar invisibles

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
Durante los 0,5 s del glitch de entrada de la pantalla de derrota, los botones están invisibles (marco a opacidad 0), pero siguen recibiendo clics (docs/design/ui.md, "Dudas"). Un clic rápido puede reiniciar o salir al menú sin que el jugador haya visto nada.

## Qué hay que hacer
- En `GameOverScreen`, desactivar los botones (`disabled = true` o `mouse_filter = IGNORE`) al empezar el glitch y activarlos cuando termine.
- Comprobar si `VictoryScreen` tiene el mismo problema mientras entra deslizando; si lo tiene, arreglarlo igual.
- Quitar la duda de docs/design/ui.md.

## Archivos que toca
- scripts/level_ui/GameOverScreen.gd
- scripts/level_ui/VictoryScreen.gd (solo si tiene el mismo problema)
- docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y entrar al nivel 1.
2. Lanzar oleadas sin torres hasta perder.
3. Durante la cámara lenta y el glitch, hacer clic varias veces donde aparecen los botones: no pasa nada.
4. Cuando los botones ya se ven, "Reiniciar" funciona normal.
