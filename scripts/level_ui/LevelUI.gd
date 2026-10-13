extends CanvasLayer
class_name GameUI

signal restart_requested
signal quit_requested

@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_menu: Control = %PauseMenu
@onready var sidebar: Sidebar = %Sidebar
@onready var level_indicator: LevelIndicator = %LevelIndicator

var _state: LevelState
var _spawner: Spawner

func _ready() -> void:
	pause_menu.resume_requested.connect(_set_paused.bind(false))
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.quit_requested.connect(_on_quit_requested)
	game_over_screen.restart_requested.connect(_on_restart_requested)
	game_over_screen.quit_requested.connect(_on_quit_requested)
	sidebar.tower_selected.connect(_on_tower_selected)
	sidebar.next_wave_requested.connect(_on_next_wave_requested)
	sidebar.auto_waves_toggled.connect(_on_auto_waves_toggled)

func setup(state: LevelState, towers: Array[TowerData], level_number: int, spawner: Spawner) -> void:
	level_indicator.set_level_number(level_number)
	_connect_spawner(spawner)
	if is_instance_valid(_state):
		if _state.money_changed.is_connected(sidebar.set_money):
			_state.money_changed.disconnect(sidebar.set_money)
		if _state.selected_tower_changed.is_connected(sidebar.show_selected):
			_state.selected_tower_changed.disconnect(sidebar.show_selected)
	_state = state
	state.money_changed.connect(sidebar.set_money)
	state.selected_tower_changed.connect(sidebar.show_selected)
	sidebar.build_buttons(towers)
	sidebar.set_money(state.money)

func _on_tower_selected(data: TowerData) -> void:
	if is_instance_valid(_state):
		_state.selected_tower = data

# Cambia el Spawner que sigue la pestaña Oleadas, desconectando el anterior.
func _connect_spawner(spawner: Spawner) -> void:
	if is_instance_valid(_spawner):
		for connection in _spawner_connections(_spawner):
			if connection[0].is_connected(connection[1]):
				connection[0].disconnect(connection[1])
	_spawner = spawner
	sidebar.build_waves(spawner.waves)
	sidebar.set_current_wave(spawner.get_wave_index(), spawner.waves.size())
	sidebar.show_auto_waves(spawner.auto_waves)
	_refresh_wave_controls()
	for connection in _spawner_connections(spawner):
		connection[0].connect(connection[1])

func _spawner_connections(spawner: Spawner) -> Array[Array]:
	return [
		[spawner.wave_started, _on_wave_started],
		[spawner.wave_cleared, _on_wave_cleared],
		[spawner.auto_waves_changed, sidebar.show_auto_waves],
	]

func _on_wave_started(index: int, total: int) -> void:
	sidebar.set_current_wave(index, total)
	_refresh_wave_controls()

func _on_wave_cleared(_index: int) -> void:
	_refresh_wave_controls()

func _refresh_wave_controls() -> void:
	# Antes de la primera oleada el botón parpadea para invitar a empezar.
	sidebar.set_next_wave_available(_spawner.can_start_next_wave(), _spawner.get_wave_index() < 0)

func _on_next_wave_requested() -> void:
	if is_instance_valid(_spawner):
		_spawner.start_next_wave()

func _on_auto_waves_toggled(enabled: bool) -> void:
	if is_instance_valid(_spawner):
		_spawner.auto_waves = enabled

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
