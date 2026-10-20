# Vender torres colocadas

Estado: propuesta
Modelo recomendado: sonnet

## Por qué
Ahora no se puede quitar una torre puesta (docs/design/torres.md, "Dudas"). Si el jugador se equivoca de casilla, pierde el dinero para siempre. Vender da margen para corregir y cambiar de estrategia.

## Qué hay que hacer
- Al seleccionar una torre colocada, la ficha de la barra izquierda muestra un botón "Vender (+X)", con X = la mitad de su coste redondeado hacia abajo.
- Al pulsarlo: se suma X al dinero de `LevelState`, se libera la casilla en `Grid` y se borra la torre (con un `Effect` pequeño si hay uno que encaje).
- Usar el botón de esquinas recortadas que ya usa el resto de la UI.
- Contar las ventas en el resumen de partida solo si es trivial; si no, dejarlo.
- Actualizar docs/design/torres.md y docs/design/ui.md.

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/level/Grid.gd
- scripts/level_ui/ (ficha de la barra izquierda)
- scenes/level_ui/InfoPanel.tscn
- docs/design/torres.md, docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn`, darle a jugar y entrar al nivel 1.
2. Comprar y colocar una torre. Apuntar el dinero.
3. Hacer clic en la torre: en la ficha sale "Vender (+X)".
4. Pulsarlo: la torre desaparece, el dinero sube X y se puede volver a construir en esa casilla.
