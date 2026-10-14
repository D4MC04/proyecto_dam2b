extends CanvasLayer
class_name LevelUI

# Estado de la UI: decide qué pantalla se ve y si el árbol está en pausa.
enum UiState { PLAYING, PAUSED, LOST, WON }
# Peticiones que la UI pasa a Game.
enum Action { RESTART, QUIT, NEXT_LEVEL }

signal action_requested(action: Action)

@onready var game_over_screen: OverlayScreen = %GameOverScreen
@onready var victory_screen: OverlayScreen = %VictoryScreen
@onready var pause_menu: OverlayScreen = %PauseMenu
@onready var sidebar: Sidebar = %Sidebar
@onready var level_indicator: LevelIndicator = %LevelIndicator
@onready var info_panel: InfoPanel = %InfoPanel
# Pantalla de cada estado; un estado sin entrada no enseña ninguna. Cada pantalla va en un solo estado.
@onready var _screens_by_state: Dictionary[UiState, OverlayScreen] = {
	UiState.PAUSED: pause_menu,
	UiState.LOST: game_over_screen,
	UiState.WON: victory_screen,
}

var _ui_state: UiState = UiState.PLAYING
var _level_state: LevelState
var _spawner: Spawner

func _ready() -> void:
	for screen: OverlayScreen in _screens_by_state.values():
		screen.option_chosen.connect(_on_option_chosen)
	sidebar.tower_selected.connect(_on_tower_selected)
	sidebar.inspect_requested.connect(_on_inspect_requested)
	sidebar.next_wave_requested.connect(_on_next_wave_requested)
	sidebar.auto_waves_toggled.connect(_on_auto_waves_toggled)
	set_state(UiState.PLAYING)

func setup(state: LevelState, towers: Array[TowerData], level_number: int, spawner: Spawner, has_next_level: bool) -> void:
	victory_screen.set_option_visible(OverlayScreen.Option.NEXT_LEVEL, has_next_level)
	level_indicator.set_level_number(level_number)
	_connect_spawner(spawner)
	if is_instance_valid(_level_state):
		if _level_state.money_changed.is_connected(sidebar.set_money):
			_level_state.money_changed.disconnect(sidebar.set_money)
		if _level_state.selected_tower_changed.is_connected(sidebar.show_selected):
			_level_state.selected_tower_changed.disconnect(sidebar.show_selected)
		if _level_state.inspected_changed.is_connected(info_panel.show_inspected):
			_level_state.inspected_changed.disconnect(info_panel.show_inspected)
	_level_state = state
	state.money_changed.connect(sidebar.set_money)
	state.selected_tower_changed.connect(sidebar.show_selected)
	state.inspected_changed.connect(info_panel.show_inspected)
	sidebar.build_buttons(towers)
	sidebar.set_money(state.money)
	# Un LevelState nuevo (al empezar o reiniciar) no tiene nada inspeccionado: la ficha vuelve al escáner.
	info_panel.show_inspected(state.inspected)

func _on_tower_selected(data: TowerData) -> void:
	if is_instance_valid(_level_state):
		_level_state.selected_tower = data

func _on_inspect_requested(data: Resource) -> void:
	if is_instance_valid(_level_state):
		_level_state.inspected = data

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

# Única función que cambia qué pantalla se ve y la pausa del árbol.
func set_state(new_state: UiState) -> void:
	_ui_state = new_state
	var shown: OverlayScreen = _screens_by_state.get(new_state)
	for screen: OverlayScreen in _screens_by_state.values():
		screen.visible = screen == shown
	get_tree().paused = new_state != UiState.PLAYING
	# Con cualquier pantalla abierta no se puede seleccionar torre.
	sidebar.set_selection_locked(new_state != UiState.PLAYING)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	match _ui_state:
		UiState.PLAYING:
			set_state(UiState.PAUSED)
		UiState.PAUSED:
			set_state(UiState.PLAYING)
		_:
			# En derrota y victoria Escape no hace nada.
			return
	get_viewport().set_input_as_handled()

func _on_option_chosen(option: OverlayScreen.Option) -> void:
	match option:
		OverlayScreen.Option.RESUME:
			set_state(UiState.PLAYING)
		OverlayScreen.Option.RESTART:
			_request_action(Action.RESTART)
		OverlayScreen.Option.QUIT:
			_request_action(Action.QUIT)
		OverlayScreen.Option.NEXT_LEVEL:
			_request_action(Action.NEXT_LEVEL)
		OverlayScreen.Option.SETTINGS:
			# El menú de ajustes aún no existe en el nivel: el botón está puesto pero no hace nada.
			pass

# Quita la pausa y la pantalla antes de avisar a Game.
func _request_action(action: Action) -> void:
	set_state(UiState.PLAYING)
	action_requested.emit(action)
