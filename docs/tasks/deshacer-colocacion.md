# Deshacer la última torre colocada

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
Colocar en la casilla equivocada cuesta dinero.

## Qué hay que hacer
- Ctrl+Z (o botón) devuelve el coste completo de la última torre si no ha disparado aún y fue hace menos de 5 s.

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/level/LevelState.gd

## Cómo se prueba a mano
1. Colocar una torre y pulsar Ctrl+Z al momento: desaparece y vuelve todo el dinero.
