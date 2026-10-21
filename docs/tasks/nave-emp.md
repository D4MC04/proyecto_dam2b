# Nave EMP: apaga las torres al pasar cerca

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Una nave que inutiliza torres un momento hace que no baste con amontonar torres en un solo punto.

## Qué hay que hacer
- Requiere `habilidades-naves-base` en main.
- Habilidad **Pulso EMP** (`scripts/resources/abilities/EmpAbility.gd`): cada 5 s suelta un pulso que apaga 3 s las torres a 48 px o menos.
- `Tower.disable(seconds)`:
  - Mientras está apagada, la torre no apunta ni dispara.
  - Se ve oscurecida, con chispas azules en pixel art que saltan.
  - El haz continuo se corta.
- Visual del pulso: un anillo azul eléctrico que se expande (pixel art, sin antialiasing).
- Nave nueva "Saboteadora" (`resources/enemy_data/saboteadora.tres`):
  - Sprite del Spikey teñido de azul.
  - Vida 110, velocidad 30, recompensa 55, daño 10.
  - Añadirla a las oleadas del nivel 8.

## Archivos que toca
- scripts/resources/abilities/EmpAbility.gd (nuevo)
- scripts/entities/Tower.gd
- resources/enemy_data/saboteadora.tres (nuevo), resources/wave_data/level_8*.tres
- docs/design/enemigos.md, docs/design/torres.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` y jugar el nivel 8.
2. Al soltar el pulso una Saboteadora, sale un anillo azul y las torres de alrededor se oscurecen con chispas y dejan de disparar 3 s.
3. Pasado ese tiempo vuelven a disparar con normalidad.
