class_name Spawner
extends Node

signal enemy_died(reward: int)
signal enemy_reached_end
signal wave_finished(index: int)

const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")

var paths: Array[Path2D]
var waves: Array[WaveData]
var _elapsed: float = 0.0
var _next_index: int = 0
var _wave_index: int = -1
var _entries: Array = []
var _active: bool = false

func setup(p: Array[Path2D], w: Array[WaveData]) -> void:
	paths = p
	waves = w
	start_next_wave()

func start_next_wave() -> bool:
	if _active or _wave_index + 1 >= waves.size():
		return false
	_wave_index += 1
	_entries = waves[_wave_index].entries.duplicate()
	_entries.sort_custom(func(a, b): return a.time < b.time)
	_elapsed = 0.0
	_next_index = 0
	_active = true
	return true

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	while _next_index < _entries.size() and _entries[_next_index].time <= _elapsed:
		_spawn(_entries[_next_index])
		_next_index += 1
	if _next_index >= _entries.size():
		_active = false
		wave_finished.emit(_wave_index)

func _spawn(entry: SpawnEntry) -> void:
	var enemy := ENEMY_SCENE.instantiate()
	var path := paths[entry.path_index % paths.size()]
	path.add_child(enemy)
	enemy.setup(entry.enemy_data)
	enemy.reached_end.connect(enemy_reached_end.emit)
	enemy.died.connect(enemy_died.emit)
