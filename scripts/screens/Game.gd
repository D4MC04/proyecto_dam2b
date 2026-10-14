extends Node
class_name Game

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@export var level_data: LevelData

@onready var level: Level = $Level
@onready var ui: LevelUI = $LevelUI

var _level_scene: PackedScene

func _ready() -> void:
	_level_scene = load(level.scene_file_path)
	ui.action_requested.connect(_on_action_requested)
	_setup_level()

func _setup_level() -> void:
	level.setup(level_data)
	level.lost.connect(_on_level_lost)
	# Posición del nivel en la lista + 1; 0 si no está (no se muestra número)
	var level_number: int = GameData.levels.find(level_data) + 1
	ui.setup(level.game_state, level.towers, level_number, level.spawner)

func _on_level_lost() -> void:
	ui.set_state(LevelUI.UiState.LOST)

func _on_action_requested(action: LevelUI.Action) -> void:
	match action:
		LevelUI.Action.RESTART:
			_restart_level()
		LevelUI.Action.QUIT:
			_quit_to_menu()

func _restart_level() -> void:
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
