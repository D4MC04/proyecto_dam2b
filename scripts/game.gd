extends Node
class_name Game

@export var level_data: LevelData

@onready var level: Level = $Level
@onready var ui: GameUI = $LevelUI

func _ready() -> void:

	level.setup(level_data)
	level.lost.connect(_on_level_lost)
	ui.setup(level.game_state, level.towers)
	ui.sidebar.tower_selected.connect(level.on_tower_selected)

func _on_level_lost() -> void:

	get_tree().reload_current_scene()
