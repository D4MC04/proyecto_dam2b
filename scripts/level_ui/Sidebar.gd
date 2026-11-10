extends PanelContainer
class_name Sidebar

signal turret_selected(data: TurretData)
## Petición de enseñar algo en la ficha; no guarda qué está inspeccionado.
signal inspect_requested(data: Resource)
## Petición de lanzar la siguiente oleada.
signal next_wave_requested
## Petición de cambiar el modo AUTO; no guarda el estado.
signal auto_waves_toggled(enabled: bool)
## Petición de cambiar la velocidad ×1 / ×2; no guarda el estado.
signal fast_speed_toggled(enabled: bool)

## Estado de la oleada que enseña el pie; lo decide LevelUI.
enum WaveStatus { READY, IN_PROGRESS, COMPLETE }

# Torretas con atajo de teclado (1-7), en el orden de la rejilla.
const TURRET_SHORTCUT_COUNT: int = 7

const TURRET_BUTTON: PackedScene = preload("res://scenes/level_ui/TurretButton.tscn")

const WAVE_BLOCK: PackedScene = preload("res://scenes/level_ui/WaveBlock.tscn")

const TAB_BG_COLOR: Color = Color("#0e1626")
const TAB_BORDER_COLOR: Color = Color("#1c4a60")
const TAB_ACTIVE_BG_COLOR: Color = Color("#14304a")
const TAB_ACTIVE_BORDER_COLOR: Color = Color("#40e0f0")
const TAB_HOVER_BORDER_COLOR: Color = Color("#1c7496")
const TAB_ICON_INACTIVE_COLOR: Color = Color(1, 1, 1, 0.45)

const STATION_BAR_COLOR: Color = Color("#40e0f0")
const STATION_DANGER_COLOR: Color = Color("#ff3c5a")
# Por debajo de esta fracción de vida la barra de la estación pasa al color de peligro.
const STATION_DANGER_FRACTION: float = 0.3
# Duración del parpadeo de la barra al perder vida.
const STATION_HIT_TIME: float = 0.3

const CONTROL_HOVER_BG_COLOR: Color = Color("#16243c")
const CONTROL_DISABLED_BG_COLOR: Color = Color("#0a0f1a")
const NEXT_BORDER_COLOR: Color = Color("#1c7496")
const NEXT_GLOW_COLOR: Color = Color("#befaff")
const AUTO_HOVER_BORDER_COLOR: Color = Color("#96641e")
const AUTO_ON_BORDER_COLOR: Color = Color("#ecb23c")
const AUTO_ON_HOVER_BORDER_COLOR: Color = Color("#ffe082")
# Fondo de pestaña mezclado al 25 % con el ámbar, como la torreta seleccionada.
const AUTO_ON_BG_COLOR: Color = Color("#453d2b")
const CONTROL_ICON_DIM_COLOR: Color = Color(1, 1, 1, 0.3)
# Rejilla de torretas con la selección bloqueada.
const LOCKED_GRID_COLOR: Color = Color(1, 1, 1, 0.5)
# Duración de medio ciclo del parpadeo del botón de siguiente oleada.
const NEXT_PULSE_TIME: float = 0.5
const STATUS_TEXTS: Dictionary[WaveStatus, String] = {
	WaveStatus.READY: "WAVE_READY",
	WaveStatus.IN_PROGRESS: "WAVE_IN_PROGRESS",
	WaveStatus.COMPLETE: "WAVE_COMPLETE",
}
const STATUS_COLORS: Dictionary[WaveStatus, Color] = {
	WaveStatus.READY: Color("#ecb23c"),
	WaveStatus.IN_PROGRESS: Color("#40e0f0"),
	WaveStatus.COMPLETE: Color("#7fa6b8"),
}

@onready var turrets_tab: Button = %TurretsTab
@onready var waves_tab: Button = %WavesTab
@onready var turrets_page: Control = %TurretsPage
@onready var waves_page: Control = %WavesPage
@onready var money_label: Label = %MoneyLabel
@onready var turret_buttons: GridContainer = %TurretButtons
@onready var wave_blocks: Control = %WaveBlocks
@onready var prev_wave_arrow: Button = %PrevWaveArrow
@onready var next_wave_arrow: Button = %NextWaveArrow
@onready var wave_title_panel: PanelContainer = %WaveTitlePanel
@onready var wave_title_label: Label = %WaveTitleLabel
@onready var station_header: Control = %StationHeader
@onready var station_bar: ProgressBar = %StationBar
@onready var station_value_label: Label = %StationValueLabel
@onready var footer_wave_label: Label = %FooterWaveLabel
@onready var footer_status_label: Label = %FooterStatusLabel
@onready var next_wave_button: Button = %NextWaveButton
@onready var auto_wave_button: Button = %AutoWaveButton
@onready var speed_button: Button = %SpeedButton

## Lo pone LevelUI; con el tutorial en marcha decide qué controles responden.
var tutorial_hints: TutorialHints

var _money: int = 0
var _buttons: Array[TurretButton] = []
var _wave_blocks: Array[WaveBlock] = []
var _current_wave: int = -1
var _viewed_wave: int = 0
var _selection_locked: bool = false
# Estilo normal del botón de siguiente oleada; su borde parpadea para invitar a pulsarlo.
var _next_normal_style: ClippedBoxStyle
var _next_pulse: Tween
# Vida anterior de la estación (-1 si aún no se ha puesto) para detectar golpes.
var _station_health: int = -1
var _station_hit_tween: Tween
# Último estado del pie (estado, oleada, total) para repintarlo al cambiar de idioma; vacío si aún no hay.
var _footer_status: Array = []

# Al cambiar de idioma se repintan los textos que pone el script (los de la escena se traducen solos).
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	if not _wave_blocks.is_empty():
		view_wave(_viewed_wave)
	if not _footer_status.is_empty():
		set_wave_status(_footer_status[0], _footer_status[1], _footer_status[2])

func _ready() -> void:
	var tab_group: ButtonGroup = ButtonGroup.new()
	for tab: Button in [turrets_tab, waves_tab]:
		tab.button_group = tab_group
		_style_tab(tab)
	turrets_tab.toggled.connect(_on_tab_toggled)
	_style_wave_controls()
	station_bar.add_theme_stylebox_override("background", _station_style(TAB_BG_COLOR, TAB_BORDER_COLOR))
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	auto_wave_button.toggled.connect(_on_auto_toggled)
	speed_button.toggled.connect(_on_speed_toggled)
	prev_wave_arrow.pressed.connect(_on_wave_arrow_pressed.bind(-1))
	next_wave_arrow.pressed.connect(_on_wave_arrow_pressed.bind(1))

## Crea un botón por cada torreta de `GameData.turret_order`; las que no están en `unlocked` salen bloqueadas.
func build_buttons(unlocked: Array[TurretData]) -> void:
	for b: TurretButton in _buttons:
		b.queue_free()
	_buttons.clear()
	for data: TurretData in GameData.turret_order:
		var button: TurretButton = TURRET_BUTTON.instantiate()
		turret_buttons.add_child(button)
		button.setup(data, _money, not unlocked.has(data))
		button.set_selection_locked(_selection_locked)
		button.selection_changed.connect(_on_button_selection_changed)
		button.inspect_requested.connect(inspect_requested.emit)
		_buttons.append(button)

## Pulsa el botón de torreta número `index` (desde 0) como un clic; no hace nada si no existe.
func press_turret_button(index: int) -> void:
	if index < _buttons.size():
		_buttons[index].pressed.emit()

func set_money(amount: int) -> void:
	_money = amount
	money_label.text = UiFormat.money(amount)
	for b: TurretButton in _buttons:
		b.set_money(amount)

## Enseña la vida de la estación; con menos del 30 % la barra cambia al color de peligro.
func set_station_health(current: int, maximum: int) -> void:
	station_bar.max_value = maximum
	station_bar.value = current
	station_value_label.text = str(current)
	var danger: bool = current < maximum * STATION_DANGER_FRACTION
	var color: Color = STATION_DANGER_COLOR if danger else STATION_BAR_COLOR
	var label_color: Color = color if danger else NEXT_GLOW_COLOR
	var fill: StyleBoxFlat = _station_style(color, color)
	station_bar.add_theme_stylebox_override("fill", fill)
	station_value_label.add_theme_color_override("font_color", label_color)
	if _station_hit_tween:
		_station_hit_tween.kill()
	# Si la vida baja, barra y número parpadean en peligro y vuelven a su color
	if _station_health >= 0 and current < _station_health:
		fill.bg_color = STATION_DANGER_COLOR
		fill.border_color = STATION_DANGER_COLOR
		station_value_label.add_theme_color_override("font_color", STATION_DANGER_COLOR)
		_station_hit_tween = create_tween().set_parallel()
		_station_hit_tween.tween_property(fill, "bg_color", color, STATION_HIT_TIME)
		_station_hit_tween.tween_property(fill, "border_color", color, STATION_HIT_TIME)
		_station_hit_tween.tween_method(func(c: Color) -> void: station_value_label.add_theme_color_override("font_color", c), STATION_DANGER_COLOR, label_color, STATION_HIT_TIME)
	_station_health = current

func _station_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	return style

## Refleja la selección de LevelState sin volver a emitir turret_selected.
func show_selected(data: TurretData) -> void:
	for b: TurretButton in _buttons:
		b.set_selected(data != null and b.data == data)

## Con una pantalla abierta la rejilla se atenúa y el clic izquierdo en una torreta solo enseña su ficha.
func set_selection_locked(locked: bool) -> void:
	_selection_locked = locked
	turret_buttons.modulate = LOCKED_GRID_COLOR if locked else Color.WHITE
	for b: TurretButton in _buttons:
		b.set_selection_locked(locked)

## Crea un bloque por oleada (todos ocultos salvo el que se ve) y borra los anteriores.
func build_waves(waves: Array[WaveData]) -> void:
	for block: WaveBlock in _wave_blocks:
		wave_blocks.remove_child(block)
		block.queue_free()
	_wave_blocks.clear()
	for wave: WaveData in waves:
		var block: WaveBlock = WAVE_BLOCK.instantiate()
		wave_blocks.add_child(block)
		block.setup(wave)
		block.inspect_requested.connect(inspect_requested.emit)
		_wave_blocks.append(block)
	set_current_wave(-1)

## Marca la oleada en curso (índice desde 0, -1 si ninguna) y vuelve a ver la que toca.
func set_current_wave(index: int) -> void:
	_current_wave = index
	view_wave(maxi(index, 0))

## Enseña la oleada `index` (desde 0) con el color de su estado respecto a la que está en curso.
func view_wave(index: int) -> void:
	if _wave_blocks.is_empty():
		return
	_viewed_wave = clampi(index, 0, _wave_blocks.size() - 1)
	for i: int in _wave_blocks.size():
		_wave_blocks[i].visible = i == _viewed_wave
	var state: WaveBlock.State = WaveBlock.State.FUTURE
	if _viewed_wave < _current_wave:
		state = WaveBlock.State.PAST
	elif _viewed_wave == _current_wave:
		state = WaveBlock.State.CURRENT
	elif _viewed_wave == _current_wave + 1:
		state = WaveBlock.State.NEXT
	_wave_blocks[_viewed_wave].set_state(state)
	wave_title_label.text = tr("HUD_WAVE_N") % (_viewed_wave + 1)
	WaveBlock.apply_title_style(wave_title_panel, wave_title_label, state)
	prev_wave_arrow.disabled = _viewed_wave == 0
	next_wave_arrow.disabled = _viewed_wave == _wave_blocks.size() - 1

## Bloque de la oleada que se está viendo en la pestaña Oleadas (null si no hay oleadas). Lo señala el tutorial.
func get_viewed_wave_block() -> WaveBlock:
	return null if _wave_blocks.is_empty() else _wave_blocks[_viewed_wave]

## Pie de la barra: "OL. X/Y" y el estado de la oleada. Lo calcula LevelUI.
func set_wave_status(status: WaveStatus, wave_number: int, total: int) -> void:
	_footer_status = [status, wave_number, total]
	footer_wave_label.text = tr("HUD_WAVE_SHORT") % [wave_number, total]
	footer_status_label.text = tr(STATUS_TEXTS[status])
	footer_status_label.add_theme_color_override("font_color", STATUS_COLORS[status])

## Activa o atenúa el botón de siguiente oleada; con `inviting`, su borde parpadea.
func set_next_wave_available(available: bool, inviting: bool) -> void:
	next_wave_button.disabled = not available
	var pulse: bool = available and inviting
	if pulse == (_next_pulse != null):
		return
	if pulse:
		_next_pulse = create_tween().set_loops()
		_next_pulse.tween_property(_next_normal_style, "border_color", NEXT_GLOW_COLOR, NEXT_PULSE_TIME)
		_next_pulse.tween_property(_next_normal_style, "border_color", NEXT_BORDER_COLOR, NEXT_PULSE_TIME)
	else:
		_next_pulse.kill()
		_next_pulse = null
		_next_normal_style.border_color = NEXT_BORDER_COLOR

## Refleja el modo AUTO del Spawner sin volver a emitir auto_waves_toggled.
func show_auto_waves(enabled: bool) -> void:
	auto_wave_button.set_pressed_no_signal(enabled)

## Refleja la velocidad de LevelUI (×1 / ×2) sin volver a emitir fast_speed_toggled.
func show_fast_speed(enabled: bool) -> void:
	speed_button.set_pressed_no_signal(enabled)
	speed_button.text = "×2" if enabled else "×1"

func _on_button_selection_changed(data: TurretData, on: bool) -> void:
	turret_selected.emit(data if on else null)

func _on_tab_toggled(turrets_active: bool) -> void:
	var action: TutorialHints.Action = TutorialHints.Action.TAB_TURRETS if turrets_active else TutorialHints.Action.TAB_WAVES
	if tutorial_hints != null and not tutorial_hints.allows(action):
		# El tutorial no deja cambiar de pestaña: las pestañas vuelven a la que sigue abierta.
		turrets_tab.set_pressed_no_signal(turrets_page.visible)
		waves_tab.set_pressed_no_signal(waves_page.visible)
		return
	turrets_page.visible = turrets_active
	waves_page.visible = not turrets_active

# Con el tutorial en marcha el botón solo vale desde la pestaña Oleadas (el pie se ve en las dos).
func _on_next_wave_pressed() -> void:
	if tutorial_hints == null or (tutorial_hints.allows(TutorialHints.Action.NEXT_WAVE) and waves_page.visible):
		next_wave_requested.emit()

## Atajo de teclado de siguiente oleada: vale desde cualquier pestaña.
func press_next_wave() -> void:
	if tutorial_hints == null or tutorial_hints.allows(TutorialHints.Action.NEXT_WAVE):
		next_wave_button.pressed.emit()

# Los interruptores bloqueados por el tutorial se devuelven a su estado sin emitir nada.
func _on_auto_toggled(enabled: bool) -> void:
	if tutorial_hints != null and not tutorial_hints.allows(TutorialHints.Action.TOGGLE_AUTO):
		auto_wave_button.set_pressed_no_signal(not enabled)
		return
	auto_waves_toggled.emit(enabled)

func _on_speed_toggled(enabled: bool) -> void:
	if tutorial_hints != null and not tutorial_hints.allows(TutorialHints.Action.TOGGLE_SPEED):
		speed_button.set_pressed_no_signal(not enabled)
		return
	fast_speed_toggled.emit(enabled)

func _on_wave_arrow_pressed(step: int) -> void:
	if tutorial_hints == null or tutorial_hints.allows(TutorialHints.Action.WAVE_ARROWS):
		view_wave(_viewed_wave + step)

func _style_wave_controls() -> void:
	_next_normal_style = ClippedBoxStyle.create(TAB_BG_COLOR, NEXT_BORDER_COLOR)
	next_wave_button.add_theme_stylebox_override("normal", _next_normal_style)
	next_wave_button.add_theme_stylebox_override("hover", ClippedBoxStyle.create(CONTROL_HOVER_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
	next_wave_button.add_theme_stylebox_override("pressed", ClippedBoxStyle.create(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
	next_wave_button.add_theme_stylebox_override("disabled", ClippedBoxStyle.create(CONTROL_DISABLED_BG_COLOR, TAB_BORDER_COLOR))
	next_wave_button.add_theme_color_override("font_disabled_color", CONTROL_ICON_DIM_COLOR)

	var auto_on: ClippedBoxStyle = ClippedBoxStyle.create(AUTO_ON_BG_COLOR, AUTO_ON_BORDER_COLOR)
	# AUTO y ×2 comparten estilo: apagado gris azulado, encendido ámbar.
	for toggle: Button in [auto_wave_button, speed_button]:
		toggle.add_theme_stylebox_override("normal", ClippedBoxStyle.create(TAB_BG_COLOR, TAB_BORDER_COLOR))
		toggle.add_theme_stylebox_override("hover", ClippedBoxStyle.create(CONTROL_HOVER_BG_COLOR, AUTO_HOVER_BORDER_COLOR))
		toggle.add_theme_stylebox_override("pressed", auto_on)
		toggle.add_theme_stylebox_override("hover_pressed", ClippedBoxStyle.create(AUTO_ON_BG_COLOR, AUTO_ON_HOVER_BORDER_COLOR))
		toggle.add_theme_color_override("font_color", CONTROL_ICON_DIM_COLOR)
		toggle.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.6))
		toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
		toggle.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	for arrow: Button in [prev_wave_arrow, next_wave_arrow]:
		arrow.add_theme_stylebox_override("normal", ClippedBoxStyle.create(TAB_BG_COLOR, NEXT_BORDER_COLOR))
		arrow.add_theme_stylebox_override("hover", ClippedBoxStyle.create(CONTROL_HOVER_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
		arrow.add_theme_stylebox_override("pressed", ClippedBoxStyle.create(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
		arrow.add_theme_stylebox_override("disabled", ClippedBoxStyle.create(CONTROL_DISABLED_BG_COLOR, TAB_BORDER_COLOR))
		arrow.add_theme_color_override("font_disabled_color", CONTROL_ICON_DIM_COLOR)
	for button: Button in [next_wave_button, auto_wave_button, speed_button, prev_wave_arrow, next_wave_arrow]:
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _style_tab(tab: Button) -> void:
	var normal: ClippedBoxStyle = ClippedBoxStyle.create(TAB_BG_COLOR, TAB_BORDER_COLOR)
	var hover: ClippedBoxStyle = ClippedBoxStyle.create(TAB_BG_COLOR, TAB_HOVER_BORDER_COLOR)
	var active: ClippedBoxStyle = ClippedBoxStyle.create(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR)
	tab.add_theme_stylebox_override("normal", normal)
	tab.add_theme_stylebox_override("hover", hover)
	tab.add_theme_stylebox_override("pressed", active)
	tab.add_theme_stylebox_override("hover_pressed", active)
	tab.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tab.add_theme_color_override("icon_normal_color", TAB_ICON_INACTIVE_COLOR)
	tab.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	tab.add_theme_color_override("font_pressed_color", Color.WHITE)
	tab.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
