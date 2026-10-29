# Balance de torretas: que destaquen por mecánicas, no por stats

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Cada torreta nueva tiene mucho más daño que las anteriores (el Rail cuesta 7,5 veces el Cañón doble y pega 40 veces más por disparo), y como el dinero crece las viejas quedan obsoletas solo por números. La idea del juego es otra: las torretas destacan por sus mecánicas.

## Qué hay que hacer
- Rebalancear daño, cadencia, alcance y coste de las 10 torretas y sus fusiones con esta filosofía:
  - **Precio ≈ valor:** a igual dinero, el daño útil es parecido. 3 Cañones dobles rinden más o menos como su equivalente en euros de una torreta cara.
  - **Lo que justifica las caras es la casilla:** los huecos son limitados, así que en niveles avanzados se prefiere la cara porque saca más de cada casilla (más daño por casilla, alcance, área, perforación), no porque las baratas sean malas por euro.
  - **Cañón doble:** básico pero digno. Se nota peor por poco alcance, menos daño y nada de área, no por una diferencia absurda. Sirve para aprender y en niveles avanzados ya no tiene argumentos fuertes.
  - **Torretas con mecánicas** (Cryo, Tesla, Orbitador, Amplificador, Disintegrator, Rail, Minero...): cada una tiene su sitio en combos, contra ciertos enemigos o en ciertas posiciones; ninguna queda obsoleta por stats.
- Hacer antes y después una tabla con DPS, DPS por euro y DPS por casilla de cada torreta (estimando área, objetivos o perforación) y decidir con ella. Contar con las fusiones (cada mejora cuesta el doble) y con los efectos del Amplificador (`amp_effect`).
- No tocar oleadas ni enemigos: eso es `dificultad-oleadas`, que va después.
- Reescribir en docs/design/torretas.md la nueva filosofía (párrafo "Balance de costes") y la tabla de "Datos" con los valores nuevos.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Datos", "Amplificador", "Minero" y "Tipos de ataque"
- docs/design/enemigos.md › "Datos" (vidas y velocidades, para estimar)
- resources/turret_data/*.tres y los datos de ataque que usan

## Archivos que toca
- resources/turret_data/
- resources/bullet_data/, pulse_data/, chain_data/, beam_data/, focus_beam_data/, orbit_data/, amp_effects/
- resources/collision_shapes/ (alcances)
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar el nivel 4 solo con Cañones dobles y luego con Cañones pesados por el mismo dinero: rinden parecido.
2. Jugar el nivel 9: con pocas casillas compensa poner las caras, pero las baratas no son inútiles.
3. Mirar la ficha de cada torreta: salen los números nuevos.
