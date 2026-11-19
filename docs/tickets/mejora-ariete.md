# Mejora: el Ariete embiste en las rectas

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El Ariete (240 de vida, 40 px/s) es casi un Acorazado pequeño: los dos son tanques lentos sin nada propio. Si gana velocidad en las rectas y frena en las curvas tiene su papel, y premia poner torretas en las curvas en vez de a lo largo de las rectas.

## Qué hay que hacer
- Mientras va en la misma dirección acelera poco a poco hasta ×2 en 1,5 s; al cambiar de dirección (curva; ya se detecta para la animación) vuelve a su velocidad de golpe, con una sacudida de 1 px y polvo de píxeles.
- Campos en `EnemyData` (`ram_max_speed`, `ram_ramp_time`; 0 = no embiste).
- Con más de ×1,5 el morro brilla y deja estela.
- Botín: revisarlo con la fórmula usando su velocidad media en los mapas del 5 al 9. Si cambia, retocar los presupuestos de `make_waves.gd` y regenerar.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Movimiento", "Animación"
- docs/design/niveles.md › "Generador de oleadas" (solo si cambia el botín)
- scripts/entities/Enemy.gd › `_process()` y donde elige la animación

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/ariete.tres
- docs/design/enemigos.md (y niveles.md si cambian los presupuestos)

## Cómo se prueba a mano
1. Jugar el nivel 5.
2. El Ariete acelera en las rectas largas, con el morro brillando, y frena de golpe en cada curva.
3. Una torreta en una curva le da mucho más tiempo que una en mitad de una recta.
