class_name WaveData
extends Resource

## Separación entre naves de un grupo según su velocidad.
const SPAWN_SPACING: SpawnSpacing = preload("res://resources/spawn_spacing.tres")

## Multiplica la vida máxima de todos los enemigos de la oleada (no cambia la recompensa).
@export var health_multiplier: float = 1.0
## Grupos en orden de salida; el primero sale en el tiempo 0.
@export var groups: Array[SpawnGroup] = []

## Una entrada por nave, con su tiempo calculado a partir de los grupos, ordenadas por tiempo.
func get_entries() -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []
	var start: float = 0.0
	for group: SpawnGroup in groups:
		var spacing: float = group_spacing(group)
		for n: int in group.count:
			result.append(SpawnEntry.create(group.enemy_data, start + spacing * n, group.path_index))
		start += spacing * maxi(group.count - 1, 0) + group.pause_after
	result.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)
	return result


## Segundos entre dos naves del grupo: los de la velocidad de su nave en la tabla.
static func group_spacing(group: SpawnGroup) -> float:
	if group.enemy_data == null:
		return SpawnSpacing.DEFAULT_SPACING
	return SPAWN_SPACING.get_spacing(group.enemy_data.speed)
