# Mejora: la Nave agresiva embiste

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La Nave agresiva va a 48 px/s, más lenta que la Nave normal (75), y no hace nada especial: el nombre no cuadra y el nivel 3 estrena la Cryo sin una nave que la pida. Con acelerones periódicos se vuelve agresiva de verdad y enseña para qué sirve frenar.

## Qué hay que hacer
- Cada 4 s avisa 0,3 s (tiembla y brillan los motores) y acelera a ×2,2 durante 0,8 s, con estela de píxeles. La ralentización multiplica también el acelerón.
- Campos nuevos en `EnemyData` (`dash_interval`, `dash_time`, `dash_speed`; 0 = no embiste), para poder usarlos en otras naves.
- Mantener vida (110) y botín (50): su velocidad media sube a unos 58 px/s, y con la fórmula de botín sigue dando unos 50 €.
- Actualizar su `description` y la tabla de enemigos.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos", "Movimiento", "Ralentización"
- scripts/entities/Enemy.gd › `setup()` y `_process()`

## Archivos que toca
- scripts/resources/EnemyData.gd
- scripts/entities/Enemy.gd
- resources/enemy_data/nave_agresiva.tres
- docs/design/enemigos.md

## Cómo se prueba a mano
1. Jugar el nivel 3.
2. Las Naves agresivas tiemblan y dan acelerones cortos con estela.
3. Dentro de la onda de una Cryo el acelerón se nota mucho menos.
