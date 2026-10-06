extends Node
class_name Level

signal lost

var map: Map
var towers: Array[TowerData]

@onready var grid: Grid = $Grid
@onready var spawner: Spawner = $Spawner
@onready var build_manager: BuildManager = $BuildManager
@onready var game_state: LevelState = $LevelState

func _ready() -> void:
	build_manager.state = game_state
	spawner.enemy_died.connect(game_state.add_money)
	spawner.enemy_reached_end.connect(_lose)

func setup(data: LevelData) -> void:
	map = data.map.instantiate()
	map.name = "Map"
	towers = data.towers
	add_child(map)
	move_child(map, 0)
	grid.setup(map.logic_map)
	spawner.setup(map.get_paths(), data.waves)

func on_tower_selected(data: TowerData) -> void:
	game_state.selected_tower = data

func _lose() -> void:
	lost.emit()
