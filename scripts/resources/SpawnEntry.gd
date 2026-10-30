class_name SpawnEntry
extends Resource
## Una nave de una oleada con su segundo de salida. No se guarda: la calcula WaveData.get_entries().

@export var enemy_data: EnemyData
@export var time: float = 0.0
@export var path_index: int = 0

static func create(data: EnemyData, spawn_time: float, path: int) -> SpawnEntry:
	var entry := SpawnEntry.new()
	entry.enemy_data = data
	entry.time = spawn_time
	entry.path_index = path
	return entry
