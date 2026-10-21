# Reutilizar balas en vez de crearlas cada disparo

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
Cada disparo instancia un `Bullet.tscn` y lo libera al impactar; con muchas torres en los niveles 7-9 eso son cientos de nodos por segundo.

## Qué hay que hacer
- Crear un pool sencillo (en `Level` o un nodo hijo) que guarde balas ocultas y las reactive.
- `Tower._shoot` pide la bala al pool; `Bullet` vuelve al pool en vez de `queue_free`.
- Reiniciar bien su estado (objetivo, posición, rotación, sprite).
- Documentar en docs/design/torres.md.

## Archivos que toca
- scripts/entities/Bullet.gd
- scripts/entities/Tower.gd
- scripts/level/Level.gd
- docs/design/torres.md

## Cómo se prueba a mano
1. Jugar el nivel 9 con muchos Cañones dobles.
2. Las balas se ven y aciertan igual; con el monitor de Godot, el número de nodos no sube sin parar.
