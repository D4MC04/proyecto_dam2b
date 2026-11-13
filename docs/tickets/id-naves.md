# Id fijo en cada nave para ordenarlas

Creador: David
Responsable: David
Estado: propuesta
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La pestaña Oleadas enseña las naves de cada oleada en un orden fijo. Ahora se ordenan por vida máxima (y por nombre a igualdad), porque `EnemyData` no tiene un id. Con un id propio el orden lo decide el diseño y no cambia al retocar la vida de una nave.

## Qué hay que hacer
- **Antes de tocar nada**, enseñar al usuario el orden propuesto de los ids (p. ej. por el orden en que aparecen en la campaña) y ajustarlo a lo que diga.
- Añadir a `EnemyData` un `id: int` y ponérselo a cada nave de `resources/enemy_data/` (sin repetir; los trozos de la Divisora también).
- `WaveBlock.setup` ordena las celdas por `id` en vez de por vida máxima.
- Si el Navedex u otra lista de naves tiene su propio orden, valorar con el usuario si pasa a usar el id.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/ui.md › "Pestaña Oleadas" (`WaveBlock`)
- docs/design/enemigos.md (tabla de naves)
- scripts/level_ui/WaveBlock.gd › `setup()`
- scripts/resources/EnemyData.gd

## Archivos que toca
- scripts/resources/EnemyData.gd
- resources/enemy_data/*.tres
- scripts/level_ui/WaveBlock.gd
- docs/design/ui.md, docs/design/enemigos.md

## Cómo se prueba a mano
1. Jugar cualquier sector y abrir la pestaña Oleadas.
2. En todas las oleadas las naves salen en el orden de sus ids, aunque lleguen en otro orden.
