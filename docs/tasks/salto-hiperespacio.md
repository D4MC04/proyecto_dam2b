# Salto al hiperespacio al entrar en un nivel

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Al elegir un nivel se cambia de escena de golpe. Un salto al hiperespacio (estrellas que se estiran en líneas) hace la entrada mucho más espectacular.

## Qué hay que hacer
- Al pulsar un nivel en la selección: las estrellas del `StarField` se estiran en líneas desde el centro hacia fuera (0,5 s), destello blanco, y se carga el nivel.
- Al empezar el nivel, el mapa entra con un fundido desde blanco (0,2 s).
- Pixel art: líneas de 1 px sin antialiasing, colores del `StarField`.
- También al pulsar "Siguiente nivel" en la victoria, si es fácil reutilizarlo; si no, solo desde el menú.

## Archivos que toca
- scripts/screens/MainMenu.gd (`_open_level`)
- scripts/main_menu/Starfield.gd
- scripts/screens/Game.gd (fundido de entrada)
- docs/design/menu.md, docs/design/flujo.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn`, pulsar Jugar y elegir el nivel 1.
2. Las estrellas se estiran hacia fuera como un salto, destello blanco y entra el nivel.
3. Volver al menú y entrar en otro nivel: pasa lo mismo.
