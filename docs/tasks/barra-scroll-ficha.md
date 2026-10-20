# Que se vea que la ficha de la torre tiene más texto abajo

Estado: aceptada
Modelo recomendado: sonnet

## Por qué
En las fichas que no caben (Cryo, Disintegrator) la descripción queda cortada abajo y no hay ninguna pista de que se puede bajar: `StatScroll` tiene la barra oculta (docs/design/ui.md, "Dudas").

## Qué hay que hacer
- Mostrar una pista solo cuando el contenido no cabe: una barra de scroll fina con el estilo holograma, o una flecha ▼ abajo que desaparece al llegar al final. Elegir la que encaje mejor con el estilo y explicar por qué.
- Que no aparezca en fichas que caben enteras.
- Quitar la duda de docs/design/ui.md y describir la pista.

## Archivos que toca
- scripts/level_ui/InfoPanel.gd
- scenes/level_ui/InfoPanel.tscn
- docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5) y entrar al nivel 1.
2. Hacer clic en la torre Cryo de la tienda: en la ficha se ve la pista de que hay más abajo.
3. Bajar con la rueda: la pista desaparece al llegar al final.
4. Hacer clic en una torre con ficha corta: no hay pista.
