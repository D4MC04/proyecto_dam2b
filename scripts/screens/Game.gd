extends Node
class_name Game

const ENTER_FADE_TIME := 0.2
const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@export var level_data: LevelData
var from_hyperspace: bool = false

@onready var level: Level = $Level
@onready var ui: LevelUI = $LevelUI

var _level_scene: PackedScene

func _ready() -> void:
	_level_scene = load(level.scene_file_path)
	ui.action_requested.connect(_on_action_requested)
	_setup_level()
	if from_hyperspace:
		_fade_in_from_white()

# Fundido desde blanco al llegar del salto al hiperespacio.
func _fade_in_from_white() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var white := ColorRect.new()
	white.color = Color.WHITE
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(white)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(white, "color:a", 0.0, ENTER_FADE_TIME)
	tween.finished.connect(layer.queue_free)

func _setup_level() -> void:
	level.setup(level_data)
	level.lost.connect(_on_level_lost)
	level.won.connect(_on_level_won)
	# Posición del nivel en la lista + 1; 0 si no está (no se muestra número)
	var level_number: int = GameData.levels.find(level_data) + 1
	var has_next_level: bool = level_number > 0 and level_number < GameData.levels.size()
	ui.setup_powers(level.get_node(^"Powers"))
	ui.setup(level.game_state, level.towers, level_number, level.spawner, has_next_level, level.base)

func _on_level_lost() -> void:
	# La UI recibe el resumen ya hecho; no lee el nivel por su cuenta.
	ui.show_run_stats(level.get_run_stats())
	ui.set_state(LevelUI.UiState.LOST)

func _on_level_won() -> void:
	# Si no está en la lista, find devuelve -1 y el número es 0: no desbloquea nada.
	GameState.complete_level(GameData.levels.find(level_data) + 1)
	ui.show_run_stats(level.get_run_stats())
	ui.set_state(LevelUI.UiState.WON)

func _on_action_requested(action: LevelUI.Action) -> void:
	match action:
		LevelUI.Action.RESTART:
			_restart_level()
		LevelUI.Action.QUIT:
			_quit_to_menu()
		LevelUI.Action.NEXT_LEVEL:
			_next_level()

# Monta el siguiente nivel de la lista por el mismo camino que el reinicio.
func _next_level() -> void:
	var next_index: int = GameData.levels.find(level_data) + 1
	if next_index <= 0 or next_index >= GameData.levels.size():
		return
	level_data = GameData.levels[next_index]
	_restart_level()

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
