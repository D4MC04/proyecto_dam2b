extends Node
class_name Game

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@export var level_data: LevelData

@onready var level: Level = $Level
@onready var ui: GameUI = $LevelUI

var _level_scene: PackedScene

func _ready() -> void:
	_level_scene = load(level.scene_file_path)
	ui.restart_requested.connect(_restart_level)
	ui.quit_requested.connect(_quit_to_menu)
	_setup_level()

func _setup_level() -> void:
	level.setup(level_data)
	level.lost.connect(_on_level_lost)
	ui.sidebar.tower_selected.connect(level.on_tower_selected)
	ui.setup(level.game_state, level.towers)

func _on_level_lost() -> void:
	ui.show_game_over()

func _restart_level() -> void:
	ui.hide_game_over()
	ui.sidebar.tower_selected.disconnect(level.on_tower_selected)
	var index := level.get_index()
	remove_child(level)
	level.queue_free()
	level = _level_scene.instantiate()
	add_child(level)
	move_child(level, index)
	_setup_level()

func _quit_to_menu() -> void:
	var menu: Node = load(MAIN_MENU_PATH).instantiate()
	menu.start_on_level_selection = true
	var tree := get_tree()
	var old_scene := tree.current_scene
	tree.root.add_child(menu)
	tree.current_scene = menu
	old_scene.queue_free()
