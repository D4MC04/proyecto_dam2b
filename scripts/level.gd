extends Node
class_name Level

signal lost

@export var towers: Array[TowerData]

@onready var spawner: Spawner = $Spawner
@onready var build_manager: BuildManager = $BuildManager
@onready var game_state: GameState = $GameState

func _ready() -> void:
	build_manager.state = game_state
	spawner.enemy_died.connect(game_state.add_money)
	spawner.enemy_reached_end.connect(_lose)

func on_tower_selected(data: TowerData) -> void:
	game_state.selected_tower = data

func _lose() -> void:
	lost.emit()
