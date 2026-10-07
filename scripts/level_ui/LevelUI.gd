extends CanvasLayer
class_name GameUI

signal restart_requested
signal quit_requested

@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_menu: Control = %PauseMenu
@onready var sidebar: Sidebar = %Sidebar

var _state: LevelState

func _ready() -> void:
	pause_menu.resume_requested.connect(_set_paused.bind(false))
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.quit_requested.connect(_on_quit_requested)
	game_over_screen.restart_requested.connect(_on_restart_requested)
	game_over_screen.quit_requested.connect(_on_quit_requested)
	sidebar.tower_selected.connect(_on_tower_selected)

func setup(state: LevelState, towers: Array[TowerData]) -> void:
	if _state and _state.money_changed.is_connected(sidebar.set_money):
		_state.money_changed.disconnect(sidebar.set_money)
	_state = state
	state.money_changed.connect(sidebar.set_money)
	sidebar.build_buttons(towers)
	sidebar.set_money(state.money)

func _on_tower_selected(data: TowerData) -> void:
	if is_instance_valid(_state):
		_state.selected_tower = data

func show_game_over() -> void:
	game_over_screen.show()
	get_tree().paused = true

func hide_game_over() -> void:
	game_over_screen.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not game_over_screen.visible:
		_set_paused(not pause_menu.visible)
		get_viewport().set_input_as_handled()

func _set_paused(paused: bool) -> void:
	pause_menu.visible = paused
	get_tree().paused = paused

func _on_restart_requested() -> void:
	_set_paused(false)
	restart_requested.emit()

func _on_quit_requested() -> void:
	_set_paused(false)
	quit_requested.emit()
