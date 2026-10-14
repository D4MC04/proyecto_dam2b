extends CanvasLayer
class_name LevelUI

# Estado de la UI: decide qué pantalla se ve y si el árbol está en pausa.
enum UiState { PLAYING, PAUSED, LOST, WON }
# Peticiones que la UI pasa a Game.
enum Action { RESTART, QUIT, NEXT_LEVEL }

signal action_requested(action: Action)

# Cámara lenta de la derrota, en segundos de tiempo real: el juego se frena hasta
# SLOW_MOTION_MIN_SCALE en SLOW_MOTION_RAMP_TIME, se queda ahí SLOW_MOTION_HOLD_TIME y se pausa.
const SLOW_MOTION_MIN_SCALE := 0.2
const SLOW_MOTION_RAMP_TIME := 1.1
const SLOW_MOTION_HOLD_TIME := 0.2

@onready var game_over_screen: GameOverScreen = %GameOverScreen
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
# Secuencia de cámara lenta en curso al entrar en LOST; null si no hay.
var _slow_motion: Tween

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

## Pasa el resumen de la partida a la pantalla de derrota. Game lo llama antes de set_state(LOST).
func show_run_stats(stats: RunStats) -> void:
	game_over_screen.show_run_stats(stats)

# Única función que cambia qué pantalla se ve, la pausa del árbol y Engine.time_scale.
func set_state(new_state: UiState) -> void:
	_ui_state = new_state
	# Cualquier cambio de estado corta la cámara lenta que hubiera y devuelve la velocidad normal.
	if _slow_motion != null:
		_slow_motion.kill()
		_slow_motion = null
	Engine.time_scale = 1.0
	# Con cualquier pantalla abierta (o en camino, durante la cámara lenta) no se puede seleccionar torre.
	sidebar.set_selection_locked(new_state != UiState.PLAYING)
	if new_state == UiState.LOST:
		# Sin pantalla ni pausa todavía: el juego se frena y, al acabar, entra la derrota.
		_show_screen(null)
		get_tree().paused = false
		# Tiempo real y activo en pausa, para que la cámara lenta no se frene a sí misma.
		_slow_motion = create_tween().set_ignore_time_scale().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_slow_motion.tween_method(func(time_scale: float) -> void: Engine.time_scale = time_scale,
				1.0, SLOW_MOTION_MIN_SCALE, SLOW_MOTION_RAMP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_slow_motion.tween_interval(SLOW_MOTION_HOLD_TIME)
		_slow_motion.tween_callback(func() -> void:
			_slow_motion = null
			Engine.time_scale = 1.0
			get_tree().paused = true
			_show_screen(game_over_screen))
		return
	_show_screen(_screens_by_state.get(new_state))
	get_tree().paused = new_state != UiState.PLAYING

func _show_screen(shown: OverlayScreen) -> void:
	for screen: OverlayScreen in _screens_by_state.values():
		screen.visible = screen == shown

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
