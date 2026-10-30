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
# Respiro de la victoria, en segundos de tiempo real: el juego sigue a velocidad normal (se ve
# explotar al último enemigo) antes de pausarse y enseñar la pantalla.
const VICTORY_BREATH_TIME := 0.6
# Valor de Engine.time_scale con el botón ×2 activo.
const FAST_SPEED := 2.0
# Viñeta roja de vida baja: se enciende por debajo de esta fracción y late entre estas intensidades.
const LOW_HEALTH_FRACTION := 0.25
const VIGNETTE_MIN_INTENSITY := 0.25
const VIGNETTE_MAX_INTENSITY := 0.8
const VIGNETTE_PULSE_TIME := 0.5

@onready var game_over_screen: GameOverScreen = %GameOverScreen
@onready var victory_screen: VictoryScreen = %VictoryScreen
@onready var pause_menu: OverlayScreen = %PauseMenu
@onready var sidebar: Sidebar = %Sidebar
@onready var level_indicator: LevelIndicator = %LevelIndicator
@onready var info_panel: InfoPanel = %InfoPanel
@onready var turret_actions: TurretActions = %TurretActions
@onready var boss_alert: BossAlert = %BossAlert
@onready var wave_announcer: WaveAnnouncer = %WaveAnnouncer
@onready var low_health_vignette: ColorRect = %LowHealthVignette
@onready var fps_label: Label = %FpsLabel
@onready var tutorial_hints: TutorialHints = %TutorialHints
# Pantalla de cada estado; un estado sin entrada no enseña ninguna. Cada pantalla va en un solo estado.
@onready var _screens_by_state: Dictionary[UiState, OverlayScreen] = {
	UiState.PAUSED: pause_menu,
	UiState.LOST: game_over_screen,
	UiState.WON: victory_screen,
}

var _ui_state: UiState = UiState.PLAYING
var _level_state: LevelState
var _spawner: Spawner
var _powers: Powers
# Secuencia en curso antes de enseñar la pantalla (cámara lenta de LOST o respiro de WON); null si no hay.
var _screen_delay: Tween
# Velocidad ×2 elegida con el botón; vuelve a false al perder, ganar, reiniciar o salir.
var _fast_speed := false
# Latido de la viñeta; null si está apagada.
var _vignette_pulse: Tween

func _ready() -> void:
	_update_fps_label()
	Settings.changed.connect(_update_fps_label.unbind(1))
	for screen: OverlayScreen in _screens_by_state.values():
		screen.option_chosen.connect(_on_option_chosen)
	sidebar.turret_selected.connect(_on_turret_selected)
	sidebar.inspect_requested.connect(_on_inspect_requested)
	turret_actions.sell_requested.connect(_on_sell_requested)
	turret_actions.upgrade_requested.connect(_on_upgrade_requested)
	sidebar.next_wave_requested.connect(_on_next_wave_requested)
	sidebar.auto_waves_toggled.connect(_on_auto_waves_toggled)
	sidebar.fast_speed_toggled.connect(_on_fast_speed_toggled)
	info_panel.meteor_button.pressed.connect(_use_power.bind(Powers.Power.METEOR))
	info_panel.freeze_button.pressed.connect(_use_power.bind(Powers.Power.FREEZE))
	info_panel.orbital_button.pressed.connect(_use_power.bind(Powers.Power.ORBITAL))
	tutorial_hints.sidebar = sidebar
	tutorial_hints.info_panel = info_panel
	set_state(UiState.PLAYING)

# El contador de FPS solo se ve (y solo se actualiza) con la opción show_fps activada.
func _update_fps_label() -> void:
	fps_label.visible = Settings.get_value(&"show_fps")
	set_process(fps_label.visible)

func _process(_delta: float) -> void:
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()

func setup(state: LevelState, turrets: Array[TurretData], level_number: int, spawner: Spawner, has_next_level: bool, base: Base) -> void:
	victory_screen.set_option_visible(OverlayScreen.Option.NEXT_LEVEL, has_next_level)
	level_indicator.set_level_number(level_number)
	_connect_spawner(spawner)
	# La base es nueva en cada nivel o reinicio, así que no hay conexión anterior que quitar.
	base.health_changed.connect(sidebar.set_station_health)
	base.health_changed.connect(_update_low_health_vignette)
	_update_low_health_vignette(base.health, base.max_health)
	sidebar.set_station_health(base.health, base.max_health)
	if is_instance_valid(_level_state):
		if _level_state.money_changed.is_connected(sidebar.set_money):
			_level_state.money_changed.disconnect(sidebar.set_money)
		if _level_state.selected_turret_changed.is_connected(sidebar.show_selected):
			_level_state.selected_turret_changed.disconnect(sidebar.show_selected)
		if _level_state.inspected_changed.is_connected(info_panel.show_inspected):
			_level_state.inspected_changed.disconnect(info_panel.show_inspected)
		if _level_state.sellable_turret_changed.is_connected(info_panel.show_sellable):
			_level_state.sellable_turret_changed.disconnect(info_panel.show_sellable)
		if _level_state.sellable_turret_changed.is_connected(_on_sellable_turret_changed):
			_level_state.sellable_turret_changed.disconnect(_on_sellable_turret_changed)
		if _level_state.money_changed.is_connected(turret_actions.set_money):
			_level_state.money_changed.disconnect(turret_actions.set_money)
	_level_state = state
	state.money_changed.connect(sidebar.set_money)
	state.selected_turret_changed.connect(sidebar.show_selected)
	state.inspected_changed.connect(info_panel.show_inspected)
	state.sellable_turret_changed.connect(info_panel.show_sellable)
	state.sellable_turret_changed.connect(_on_sellable_turret_changed)
	state.money_changed.connect(turret_actions.set_money)
	sidebar.build_buttons(turrets)
	sidebar.set_money(state.money)
	# Un LevelState nuevo (al empezar o reiniciar) no tiene nada inspeccionado: la ficha vuelve al escáner.
	info_panel.show_inspected(state.inspected)
	info_panel.show_sellable(state.sellable_turret)
	turret_actions.show_for(state.sellable_turret, state.money)
	# El tutorial sale en el nivel 1 hasta que se acaba o se salta; necesita setup_powers antes.
	if level_number == 1 and not GameState.tutorial_done:
		tutorial_hints.start(state, spawner, _powers)
	else:
		tutorial_hints.stop()

## Powers es nuevo en cada nivel o reinicio: los botones pasan a leer el nuevo. Va antes que setup.
func setup_powers(powers: Powers) -> void:
	_powers = powers
	info_panel.meteor_button.powers = powers
	info_panel.freeze_button.powers = powers
	info_panel.orbital_button.powers = powers

# Enciende la viñeta si la vida está por debajo del umbral y la apaga si no (solo jugando).
func _update_low_health_vignette(current: int, maximum: int) -> void:
	_set_vignette(_ui_state == UiState.PLAYING and current > 0 and float(current) / maximum < LOW_HEALTH_FRACTION)

func _set_vignette(active: bool) -> void:
	low_health_vignette.visible = active
	if active == (_vignette_pulse != null):
		return
	if not active:
		_vignette_pulse.kill()
		_vignette_pulse = null
		return
	var material := low_health_vignette.material as ShaderMaterial
	_vignette_pulse = create_tween().set_loops().set_ignore_time_scale().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_vignette_pulse.tween_method(func(value: float) -> void: material.set_shader_parameter(&"intensity", value),
			VIGNETTE_MIN_INTENSITY, VIGNETTE_MAX_INTENSITY, VIGNETTE_PULSE_TIME).set_trans(Tween.TRANS_SINE)
	_vignette_pulse.tween_method(func(value: float) -> void: material.set_shader_parameter(&"intensity", value),
			VIGNETTE_MAX_INTENSITY, VIGNETTE_MIN_INTENSITY, VIGNETTE_PULSE_TIME).set_trans(Tween.TRANS_SINE)

# Los poderes solo se usan jugando.
func _use_power(power: Powers.Power) -> void:
	if is_instance_valid(_powers) and _ui_state == UiState.PLAYING:
		_powers.use(power)

# Cualquier clic sobre la interfaz suelta la torreta colocada. Va diferido para que antes se atiendan
# Mejorar y Vender; los clics sobre el mapa no pasan por aquí (los atiende BuildManager).
func _input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and get_viewport().gui_get_hovered_control() != null and is_instance_valid(_level_state):
		_level_state.set_deferred("sellable_turret", null)

func _on_turret_selected(data: TurretData) -> void:
	if is_instance_valid(_level_state):
		_level_state.selected_turret = data

# El recuadro de Mejorar y Vender sale sobre la torreta colocada seleccionada y se cierra al soltarla.
func _on_sellable_turret_changed(turret: Turret) -> void:
	turret_actions.show_for(turret, _level_state.money)

func _on_inspect_requested(data: Resource) -> void:
	if is_instance_valid(_level_state):
		_level_state.inspected = data

# Solo se vende jugando: con pausa, derrota o victoria el botón no hace nada.
func _on_sell_requested() -> void:
	if is_instance_valid(_level_state) and _ui_state == UiState.PLAYING:
		_level_state.sell_selected_turret()

# Solo se mejora jugando, igual que vender.
func _on_upgrade_requested() -> void:
	if is_instance_valid(_level_state) and _ui_state == UiState.PLAYING:
		_level_state.upgrade_requested.emit()

# Cambia el Spawner que sigue la pestaña Oleadas, desconectando el anterior.
func _connect_spawner(spawner: Spawner) -> void:
	if is_instance_valid(_spawner):
		for connection in _spawner_connections(_spawner):
			if connection[0].is_connected(connection[1]):
				connection[0].disconnect(connection[1])
	_spawner = spawner
	sidebar.build_waves(spawner.waves)
	sidebar.set_current_wave(spawner.get_wave_index())
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
	if _spawner.wave_has_boss(index):
		boss_alert.show_alert("Nodriza")
	else:
		wave_announcer.show_wave(index + 1, total)
	sidebar.set_current_wave(index)
	_refresh_wave_controls()

func _on_wave_cleared(index: int) -> void:
	# Si quedan oleadas, la vista pasa a la siguiente, que es la que se va a lanzar.
	if _spawner.has_waves_left():
		sidebar.view_wave(index + 1)
	_refresh_wave_controls()

func _refresh_wave_controls() -> void:
	# Antes de la primera oleada el botón parpadea para invitar a empezar.
	sidebar.set_next_wave_available(_spawner.can_start_next_wave(), _spawner.get_wave_index() < 0)
	var index := _spawner.get_wave_index()
	var total := _spawner.waves.size()
	if not _spawner.is_clear():
		sidebar.set_wave_status(Sidebar.WaveStatus.IN_PROGRESS, index + 1, total)
		level_indicator.set_wave(index + 1, total)
	elif _spawner.has_waves_left():
		sidebar.set_wave_status(Sidebar.WaveStatus.READY, index + 2, total)
		level_indicator.set_wave(index + 2, total)
	else:
		sidebar.set_wave_status(Sidebar.WaveStatus.COMPLETE, index + 1, total)
		level_indicator.set_wave(index + 1, total)

func _on_next_wave_requested() -> void:
	if is_instance_valid(_spawner):
		_spawner.start_next_wave()

func _on_auto_waves_toggled(enabled: bool) -> void:
	if is_instance_valid(_spawner):
		_spawner.auto_waves = enabled

# El botón ×2 solo cambia la velocidad jugando; set_state sigue siendo quien escribe Engine.time_scale.
func _on_fast_speed_toggled(enabled: bool) -> void:
	_set_fast_speed(enabled)
	if _ui_state == UiState.PLAYING:
		set_state(UiState.PLAYING)

func _set_fast_speed(enabled: bool) -> void:
	_fast_speed = enabled
	sidebar.show_fast_speed(enabled)

## Pasa el resumen de la partida a las pantallas de derrota y victoria. Game lo llama antes de
## set_state(LOST) o set_state(WON).
func show_run_stats(stats: RunStats) -> void:
	game_over_screen.show_run_stats(stats)
	victory_screen.show_run_stats(stats)

# Única función que cambia qué pantalla se ve, la pausa del árbol y Engine.time_scale.
func set_state(new_state: UiState) -> void:
	_ui_state = new_state
	# Al perder o ganar la viñeta se apaga; al reiniciar vuelve a evaluarse con la vida nueva.
	if new_state == UiState.LOST or new_state == UiState.WON:
		_set_vignette(false)
	# Cualquier cambio de estado corta la cámara lenta o el respiro que hubiera y devuelve la velocidad normal.
	if _screen_delay != null:
		_screen_delay.kill()
		_screen_delay = null
	# La derrota y la victoria devuelven la velocidad a ×1; la pausa la conserva para volver a ella.
	if new_state == UiState.LOST or new_state == UiState.WON:
		_set_fast_speed(false)
	Engine.time_scale = FAST_SPEED if _fast_speed and new_state == UiState.PLAYING else 1.0
	# Con cualquier pantalla abierta (o en camino, durante la cámara lenta o el respiro) no se puede
	# seleccionar torreta.
	sidebar.set_selection_locked(new_state != UiState.PLAYING)
	# Tampoco se sigue apuntando el meteorito.
	if new_state != UiState.PLAYING and is_instance_valid(_powers):
		_powers.cancel_aiming()
	if new_state == UiState.LOST or new_state == UiState.WON:
		# Sin pantalla ni pausa todavía: el juego sigue un momento y, al acabar, entra la pantalla.
		_show_screen(null)
		tutorial_hints.visible = false
		get_tree().paused = false
		# Tiempo real y activo en pausa, para que la cámara lenta no se frene a sí misma.
		_screen_delay = create_tween().set_ignore_time_scale().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if new_state == UiState.LOST:
			# Cámara lenta: el juego se frena hasta casi pararse.
			_screen_delay.tween_method(func(time_scale: float) -> void: Engine.time_scale = time_scale,
					1.0, SLOW_MOTION_MIN_SCALE, SLOW_MOTION_RAMP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_screen_delay.tween_interval(SLOW_MOTION_HOLD_TIME)
		else:
			# Respiro: el juego sigue a velocidad normal.
			_screen_delay.tween_interval(VICTORY_BREATH_TIME)
		var screen: OverlayScreen = _screens_by_state[new_state]
		_screen_delay.tween_callback(func() -> void:
			_screen_delay = null
			Engine.time_scale = 1.0
			get_tree().paused = true
			_show_screen(screen))
		return
	_show_screen(_screens_by_state.get(new_state))
	# Con una pantalla abierta el tutorial no se ve (no tapa la pausa ni señala botones de debajo).
	tutorial_hints.visible = new_state == UiState.PLAYING
	get_tree().paused = new_state != UiState.PLAYING

func _show_screen(shown: OverlayScreen) -> void:
	for screen: OverlayScreen in _screens_by_state.values():
		screen.visible = screen == shown

func _unhandled_input(event: InputEvent) -> void:
	if _ui_state == UiState.PLAYING and _handle_shortcut(event):
		get_viewport().set_input_as_handled()
		return
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

# Atajos de teclado: pasan por los mismos botones que el ratón. Solo se llaman jugando.
func _handle_shortcut(event: InputEvent) -> bool:
	for i in Sidebar.TURRET_SHORTCUT_COUNT:
		if event.is_action_pressed("select_turret_%d" % (i + 1)):
			sidebar.press_turret_button(i)
			return true
	if event.is_action_pressed("next_wave"):
		sidebar.next_wave_button.pressed.emit()
	elif event.is_action_pressed("toggle_auto"):
		sidebar.auto_wave_button.button_pressed = not sidebar.auto_wave_button.button_pressed
	elif event.is_action_pressed("toggle_speed"):
		sidebar.speed_button.button_pressed = not sidebar.speed_button.button_pressed
	elif event.is_action_pressed("power_meteor"):
		_use_power(Powers.Power.METEOR)
	elif event.is_action_pressed("power_freeze"):
		_use_power(Powers.Power.FREEZE)
	elif event.is_action_pressed("power_orbital"):
		_use_power(Powers.Power.ORBITAL)
	else:
		return false
	return true

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
			# Las opciones las abre PauseScreen dentro de la propia pausa: LevelUI sigue en PAUSED.
			pass

# Quita la pausa y la pantalla antes de avisar a Game.
func _request_action(action: Action) -> void:
	_set_fast_speed(false)
	set_state(UiState.PLAYING)
	action_requested.emit(action)
