extends PanelContainer
class_name Sidebar

signal tower_selected(data: TowerData)
## Petición de enseñar algo en la ficha; no guarda qué está inspeccionado.
signal inspect_requested(data: Resource)
## Petición de lanzar la siguiente oleada.
signal next_wave_requested
## Petición de cambiar el modo AUTO; no guarda el estado.
signal auto_waves_toggled(enabled: bool)

## Estado de la oleada que enseña el pie; lo decide LevelUI.
enum WaveStatus { READY, IN_PROGRESS, COMPLETE }

const TOWER_BUTTON: PackedScene = preload("res://scenes/level_ui/TowerButton.tscn")

const WAVE_BLOCK: PackedScene = preload("res://scenes/level_ui/WaveBlock.tscn")

const TAB_BG_COLOR := Color("#0e1626")
const TAB_BORDER_COLOR := Color("#1c4a60")
const TAB_ACTIVE_BG_COLOR := Color("#14304a")
const TAB_ACTIVE_BORDER_COLOR := Color("#40e0f0")
const TAB_HOVER_BORDER_COLOR := Color("#1c7496")
const TAB_ICON_INACTIVE_COLOR := Color(1, 1, 1, 0.45)

const CONTROL_HOVER_BG_COLOR := Color("#16243c")
const CONTROL_DISABLED_BG_COLOR := Color("#0a0f1a")
const NEXT_BORDER_COLOR := Color("#1c7496")
const NEXT_GLOW_COLOR := Color("#befaff")
const AUTO_HOVER_BORDER_COLOR := Color("#96641e")
const AUTO_ON_BORDER_COLOR := Color("#ecb23c")
const AUTO_ON_HOVER_BORDER_COLOR := Color("#ffe082")
# Fondo de pestaña mezclado al 25 % con el ámbar, como la torre seleccionada.
const AUTO_ON_BG_COLOR := Color("#453d2b")
const CONTROL_ICON_DIM_COLOR := Color(1, 1, 1, 0.3)
# Rejilla de torres con la selección bloqueada.
const LOCKED_GRID_COLOR := Color(1, 1, 1, 0.5)
# Duración de medio ciclo del parpadeo del botón de siguiente oleada.
const NEXT_PULSE_TIME := 0.5
const STATUS_TEXTS: Dictionary[WaveStatus, String] = {
	WaveStatus.READY: "LISTA",
	WaveStatus.IN_PROGRESS: "EN CURSO",
	WaveStatus.COMPLETE: "COMPLETA",
}
const STATUS_COLORS: Dictionary[WaveStatus, Color] = {
	WaveStatus.READY: Color("#ecb23c"),
	WaveStatus.IN_PROGRESS: Color("#40e0f0"),
	WaveStatus.COMPLETE: Color("#7fa6b8"),
}

@onready var towers_tab: Button = %TowersTab
@onready var waves_tab: Button = %WavesTab
@onready var towers_page: Control = %TowersPage
@onready var waves_page: Control = %WavesPage
@onready var money_label: Label = %MoneyLabel
@onready var tower_buttons: GridContainer = %TowerButtons
@onready var wave_blocks: Control = %WaveBlocks
@onready var prev_wave_arrow: Button = %PrevWaveArrow
@onready var next_wave_arrow: Button = %NextWaveArrow
@onready var wave_title_panel: PanelContainer = %WaveTitlePanel
@onready var wave_title_label: Label = %WaveTitleLabel
@onready var footer_wave_label: Label = %FooterWaveLabel
@onready var footer_status_label: Label = %FooterStatusLabel
@onready var next_wave_button: Button = %NextWaveButton
@onready var auto_wave_button: Button = %AutoWaveButton

var _money := 0
var _buttons: Array[TowerButton] = []
var _wave_blocks: Array[WaveBlock] = []
var _current_wave := -1
var _viewed_wave := 0
var _selection_locked := false
# Estilo normal del botón de siguiente oleada; su borde parpadea para invitar a pulsarlo.
var _next_normal_style: StyleBoxFlat
var _next_pulse: Tween

func _ready() -> void:
	var tab_group := ButtonGroup.new()
	for tab in [towers_tab, waves_tab]:
		tab.button_group = tab_group
		_style_tab(tab)
	towers_tab.toggled.connect(_on_tab_toggled)
	_style_wave_controls()
	next_wave_button.pressed.connect(next_wave_requested.emit)
	auto_wave_button.toggled.connect(auto_waves_toggled.emit)
	prev_wave_arrow.pressed.connect(func() -> void: view_wave(_viewed_wave - 1))
	next_wave_arrow.pressed.connect(func() -> void: view_wave(_viewed_wave + 1))

func build_buttons(towers: Array[TowerData]) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for data in towers:
		var button: TowerButton = TOWER_BUTTON.instantiate()
		tower_buttons.add_child(button)
		button.setup(data, _money)
		button.set_selection_locked(_selection_locked)
		button.selection_changed.connect(_on_button_selection_changed)
		button.inspect_requested.connect(inspect_requested.emit)
		_buttons.append(button)

func set_money(amount: int) -> void:
	_money = amount
	money_label.text = UiFormat.money(amount)
	for b in _buttons:
		b.set_money(amount)

## Refleja la selección de LevelState sin volver a emitir tower_selected.
func show_selected(data: TowerData) -> void:
	for b in _buttons:
		b.set_selected(data != null and b.data == data)

## Con una pantalla abierta la rejilla se atenúa y el clic izquierdo en una torre solo enseña su ficha.
func set_selection_locked(locked: bool) -> void:
	_selection_locked = locked
	tower_buttons.modulate = LOCKED_GRID_COLOR if locked else Color.WHITE
	for b in _buttons:
		b.set_selection_locked(locked)

## Crea un bloque por oleada (todos ocultos salvo el que se ve) y borra los anteriores.
func build_waves(waves: Array[WaveData]) -> void:
	for block in _wave_blocks:
		wave_blocks.remove_child(block)
		block.queue_free()
	_wave_blocks.clear()
	for wave in waves:
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
	for i in _wave_blocks.size():
		_wave_blocks[i].visible = i == _viewed_wave
	var state := WaveBlock.State.FUTURE
	if _viewed_wave < _current_wave:
		state = WaveBlock.State.PAST
	elif _viewed_wave == _current_wave:
		state = WaveBlock.State.CURRENT
	elif _viewed_wave == _current_wave + 1:
		state = WaveBlock.State.NEXT
	_wave_blocks[_viewed_wave].set_state(state)
	wave_title_label.text = "OLEADA %d" % (_viewed_wave + 1)
	WaveBlock.apply_title_style(wave_title_panel, wave_title_label, state)
	prev_wave_arrow.disabled = _viewed_wave == 0
	next_wave_arrow.disabled = _viewed_wave == _wave_blocks.size() - 1

## Pie de la barra: "OL. X/Y" y el estado de la oleada. Lo calcula LevelUI.
func set_wave_status(status: WaveStatus, wave_number: int, total: int) -> void:
	footer_wave_label.text = "OL. %d/%d" % [wave_number, total]
	footer_status_label.text = STATUS_TEXTS[status]
	footer_status_label.add_theme_color_override("font_color", STATUS_COLORS[status])

## Activa o atenúa el botón de siguiente oleada; con `inviting`, su borde parpadea.
func set_next_wave_available(available: bool, inviting: bool) -> void:
	next_wave_button.disabled = not available
	var pulse := available and inviting
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

func _on_button_selection_changed(data: TowerData, on: bool) -> void:
	tower_selected.emit(data if on else null)

func _on_tab_toggled(towers_active: bool) -> void:
	towers_page.visible = towers_active
	waves_page.visible = not towers_active

func _style_wave_controls() -> void:
	_next_normal_style = _make_tab_style(TAB_BG_COLOR, NEXT_BORDER_COLOR)
	next_wave_button.add_theme_stylebox_override("normal", _next_normal_style)
	next_wave_button.add_theme_stylebox_override("hover", _make_tab_style(CONTROL_HOVER_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
	next_wave_button.add_theme_stylebox_override("pressed", _make_tab_style(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
	next_wave_button.add_theme_stylebox_override("disabled", _make_tab_style(CONTROL_DISABLED_BG_COLOR, TAB_BORDER_COLOR))
	next_wave_button.add_theme_color_override("font_disabled_color", CONTROL_ICON_DIM_COLOR)

	var auto_on := _make_tab_style(AUTO_ON_BG_COLOR, AUTO_ON_BORDER_COLOR)
	auto_wave_button.add_theme_stylebox_override("normal", _make_tab_style(TAB_BG_COLOR, TAB_BORDER_COLOR))
	auto_wave_button.add_theme_stylebox_override("hover", _make_tab_style(CONTROL_HOVER_BG_COLOR, AUTO_HOVER_BORDER_COLOR))
	auto_wave_button.add_theme_stylebox_override("pressed", auto_on)
	auto_wave_button.add_theme_stylebox_override("hover_pressed", _make_tab_style(AUTO_ON_BG_COLOR, AUTO_ON_HOVER_BORDER_COLOR))
	auto_wave_button.add_theme_color_override("font_color", CONTROL_ICON_DIM_COLOR)
	auto_wave_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.6))
	auto_wave_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	auto_wave_button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	for arrow in [prev_wave_arrow, next_wave_arrow]:
		arrow.add_theme_stylebox_override("normal", _make_tab_style(TAB_BG_COLOR, NEXT_BORDER_COLOR))
		arrow.add_theme_stylebox_override("hover", _make_tab_style(CONTROL_HOVER_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
		arrow.add_theme_stylebox_override("pressed", _make_tab_style(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR))
		arrow.add_theme_stylebox_override("disabled", _make_tab_style(CONTROL_DISABLED_BG_COLOR, TAB_BORDER_COLOR))
		arrow.add_theme_color_override("font_disabled_color", CONTROL_ICON_DIM_COLOR)
	for button: Button in [next_wave_button, auto_wave_button, prev_wave_arrow, next_wave_arrow]:
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _style_tab(tab: Button) -> void:
	var normal := _make_tab_style(TAB_BG_COLOR, TAB_BORDER_COLOR)
	var hover := _make_tab_style(TAB_BG_COLOR, TAB_HOVER_BORDER_COLOR)
	var active := _make_tab_style(TAB_ACTIVE_BG_COLOR, TAB_ACTIVE_BORDER_COLOR)
	tab.add_theme_stylebox_override("normal", normal)
	tab.add_theme_stylebox_override("hover", hover)
	tab.add_theme_stylebox_override("pressed", active)
	tab.add_theme_stylebox_override("hover_pressed", active)
	tab.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tab.add_theme_color_override("icon_normal_color", TAB_ICON_INACTIVE_COLOR)
	tab.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	tab.add_theme_color_override("font_pressed_color", Color.WHITE)
	tab.add_theme_color_override("font_hover_pressed_color", Color.WHITE)

func _make_tab_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style
