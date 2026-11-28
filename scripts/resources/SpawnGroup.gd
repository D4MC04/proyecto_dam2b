class_name SpawnGroup
extends Resource
## Grupo de naves iguales que salen seguidas por el mismo camino. La separación entre ellas
## depende de su velocidad (SpawnSpacing, res://resources/spawn_spacing.tres).

@export var enemy_data: EnemyData
@export var count: int = 1
## Segundos desde la última nave del grupo hasta la primera del siguiente. Negativo: el siguiente
## empieza antes de que acabe este (se solapan, útil con varios caminos).
@export var pause_after: float = 3.0
@export var path_index: int = 0
