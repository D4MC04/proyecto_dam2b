class_name Spawner
extends Node2D

@export var map: Map
@export var enemy_scene: PackedScene
@export var wave: WaveData

var paths: Array[Path2D]
var _elapsed: float = 0.0
var _next_index: int = 0

signal enemy_reached_end

func _ready() -> void:
	paths = map.get_paths()
	wave.entries.sort_custom(func(a, b): return a.time < b.time)

func _process(delta: float) -> void:
	_elapsed += delta
	while _next_index < wave.entries.size() and wave.entries[_next_index].time <= _elapsed:
		_spawn(wave.entries[_next_index])
		_next_index += 1

func _spawn(entry: SpawnEntry) -> void:
	var enemy := enemy_scene.instantiate()
	var path := paths[entry.path_index % paths.size()]
	path.add_child(enemy)
	enemy.setup(entry.enemy_data)
	enemy.reached_end.connect(enemy_reached_end.emit)
