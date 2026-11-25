# El Meteorito y el Ataque orbital hacen más daño en las oleadas con más vida

Estado: propuesta
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
El Meteorito (150) y el Ataque orbital (300) hacen siempre el mismo daño, pero la vida de las naves se multiplica por oleada (`health_multiplier`, hasta ×6,6 en la 10 del nivel 4). Al final de cada nivel casi no hacen nada y no merece la pena usarlos justo cuando más falta harían.

## Qué hay que hacer
- El daño del Meteorito y del Ataque orbital se multiplica por el `health_multiplier` de la oleada en curso (si no hay oleada en curso, el de la última que salió; ×1 si aún no ha salido ninguna). `METEOR_DAMAGE` y `ORBITAL_DAMAGE` pasan a ser el daño base (con vida ×1).
- `Powers` necesita saber el multiplicador: dárselo desde el `Spawner` (por ejemplo con un getter del `health_multiplier` de `waves[_wave_index]`) o guardarlo en `LevelState` al empezar cada oleada.
- Si la ficha o el tooltip de los poderes enseña el daño, que enseñe el daño real de la oleada actual.
- Congelar no cambia (frena en porcentaje, ya sirve igual en cualquier oleada).
- Ojo: `David/poderes-desbloqueables` también toca `Powers.gd`; no hacer los dos a la vez.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/niveles.md › "Poderes"
- scripts/level/Powers.gd › `METEOR_DAMAGE`, `ORBITAL_DAMAGE` y donde se llama a `take_damage`
- scripts/level/Spawner.gd › `enemy.setup(data, waves[_wave_index].health_multiplier)`

## Archivos que toca
- scripts/level/Powers.gd
- scripts/level/Spawner.gd (o scripts/level/LevelState.gd)
- docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el Sector 4 hasta la oleada 8 o la 10.
2. Lanzar el Meteorito sobre un grupo de Darts y el Ataque orbital sobre una fila con un Juggernaut.
3. Los Darts deberían morir del golpe y el Juggernaut perder una parte clara de su vida, no casi nada como ahora.
