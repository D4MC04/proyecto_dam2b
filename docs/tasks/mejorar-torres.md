# Mejorar torres colocadas (nivel 2)

Estado: propuesta
Modelo recomendado: opus

## Por qué
Ahora una torre colocada solo se puede vender (docs/design/torres.md, "Dudas"). Poder mejorarla da otra forma de gastar el dinero y decisiones más interesantes: ¿pongo otra torre o mejoro esta?

## Qué hay que hacer
- Diseño simple: cada torre tiene un solo nivel de mejora. En `TowerData`, campos tipados `upgrade_cost: int` y multiplicadores `upgrade_damage_mult` y `upgrade_range_mult` (por ejemplo ×1,5 y ×1,2).
- En la ficha de una torre colocada, al lado de "Vender", un botón "Mejorar (−X)". Gris si no hay dinero; oculto si ya está mejorada.
- Al mejorar: se resta el dinero, la torre aplica los multiplicadores y se marca visualmente (por ejemplo un tinte o una marca pequeña en el sprite, siguiendo docs/design/art.md).
- Vender una torre mejorada devuelve también parte de lo gastado en la mejora.
- Dar valores en los 7 `.tres` de `resources/turret_data/`.
- Actualizar docs/design/torres.md y docs/design/ui.md.

## Archivos que toca
- scripts/resources/TowerData.gd
- scripts/entities/Tower.gd
- scripts/level/BuildManager.gd
- scripts/level_ui/InfoPanel.gd
- scenes/level_ui/InfoPanel.tscn
- resources/turret_data/*.tres
- docs/design/torres.md, docs/design/ui.md

## Cómo se prueba a mano
1. Abrir `scenes/MainMenu.tscn` (F5) y entrar al nivel 1.
2. Poner una torre y hacer clic en ella: salen "Vender" y "Mejorar (−X)".
3. Pulsar "Mejorar": baja el dinero, la torre se ve distinta, dispara más fuerte y llega más lejos.
4. El botón "Mejorar" ya no sale. "Vender" devuelve más que antes.
