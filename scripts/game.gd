extends Node
class_name Game

@onready var level: Level = $Level
@onready var ui: GameUI = $LevelUI

func _ready() -> void:

	ui.setup(level.game_state, level.towers)
	ui.sidebar.tower_selected.connect(level.on_tower_selected)
	level.lost.connect(_on_level_lost)

func _on_level_lost() -> void:

	get_tree().reload_current_scene()
