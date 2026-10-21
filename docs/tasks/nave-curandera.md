# Nave curandera: cura a las naves de alrededor

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Una nave que cura a las demás se convierte en objetivo prioritario y cambia dónde conviene poner las torres.

## Qué hay que hacer
- Requiere `habilidades-naves-base` en main.
- Habilidad **Reparación** (`scripts/resources/abilities/HealAbility.gd`):
  - Cada 3 s cura un 10 % de su vida máxima a los enemigos (grupo `enemies`) a 48 px o menos, sin incluirse a sí misma, con `Enemy.heal`.
  - Al curar sale un anillo verde que se expande desde la nave (pixel art, `draw_arc` sin antialiasing) y un "+" verde pequeño sobre cada nave curada (`FloatingText` en verde).
- Nave nueva "Reparadora" (`resources/enemy_data/reparadora.tres`):
  - Sprite de la Wasp teñido de verde.
  - Vida 90, velocidad 38, recompensa 50, daño 5.
  - Añadirla a las oleadas del nivel 6, en medio de grupos.

## Archivos que toca
- scripts/resources/abilities/HealAbility.gd (nuevo)
- resources/enemy_data/reparadora.tres (nuevo), resources/wave_data/level_6*.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 6.
2. Cerca de una Reparadora, cada 3 s sale un anillo verde y a las naves dañadas de alrededor les sale "+".
3. Si se mata antes a la Reparadora, las demás dejan de curarse.
