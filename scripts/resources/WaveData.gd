class_name WaveData
extends Resource

## Multiplica la vida máxima de todos los enemigos de la oleada (no cambia la recompensa).
@export var health_multiplier: float = 1.0
## Grupos en orden de salida; el primero sale en el tiempo 0.
@export var groups: Array[SpawnGroup] = []

## Una entrada por nave, con su tiempo calculado a partir de los grupos, ordenadas por tiempo.
func get_entries() -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []
	var start := 0.0
	for group in groups:
		for n in group.count:
			result.append(SpawnEntry.create(group.enemy_data, start + group.spacing * n, group.path_index))
		start += group.spacing * maxi(group.count - 1, 0) + group.pause_after
	result.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)
	return result
