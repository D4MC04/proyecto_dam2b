# Orbitador: la órbita más lejos

Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
La órbita del Orbitador queda demasiado cerca de la torreta: se quiere que el anillo vaya más lejos y alcance más camino.

## Qué hay que hacer
- Subir el alcance máximo del Orbitador (`attack_range` de `resources/turret_data/orbiter.tres`, y de sus versiones `orbiter_fusion` y `orbiter_level3`), para que el anillo de los orbes quede más lejos de la torreta. El radio de la órbita es la media entre `min_range` (40 px) y el alcance máximo (`Orbit.orbit_radius()`).
- Ojo: `attack_range` es un recurso compartido (`ExtResource`). Si lo usan otras torretas, darle al Orbitador uno propio en vez de cambiar el compartido.
- Elegir cuánto probándolo en el juego, y decírselo al usuario. Mantener la diferencia entre los tres niveles si la había.
- Actualizar `docs/design/torretas.md` › Orbitador.

## Qué leer
- docs/design/torretas.md › la sección del Orbitador (sacarla con Grep `^#`)
- resources/turret_data/orbiter*.tres › `attack_range` y `min_range`
- scripts/entities/Orbit.gd › `orbit_radius()` y `hit_radius()`

## Archivos que toca
- resources/turret_data/orbiter.tres, orbiter_fusion.tres, orbiter_level3.tres
- el recurso de alcance del Orbitador (nuevo, si el actual es compartido)

## Cómo se prueba a mano
1. Poner un Orbitador junto al camino.
2. Su anillo de orbes debería girar más lejos de la torreta que antes y alcanzar naves más alejadas.
3. Mejorarlo a nivel 2 y 3: el anillo sigue más lejos.
