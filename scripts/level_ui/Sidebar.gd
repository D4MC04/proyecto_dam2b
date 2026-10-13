extends PanelContainer
class_name Sidebar

signal tower_selected(data: TowerData)

const TOWER_BUTTON: PackedScene = preload("res://scenes/level_ui/TowerButton.tscn")

const WAVE_BLOCK: PackedScene = preload("res://scenes/level_ui/WaveBlock.tscn")

const TAB_BG_COLOR := Color("#0e1626")
const TAB_BORDER_COLOR := Color("#1c4a60")
const TAB_ACTIVE_BG_COLOR := Color("#14304a")
const TAB_ACTIVE_BORDER_COLOR := Color("#40e0f0")
const TAB_HOVER_BORDER_COLOR := Color("#1c7496")
const TAB_ICON_INACTIVE_COLOR := Color(1, 1, 1, 0.45)

@onready var towers_tab: Button = %TowersTab
@onready var waves_tab: Button = %WavesTab
@onready var towers_page: Control = %TowersPage
@onready var waves_page: Control = %WavesPage
@onready var money_label: Label = %MoneyLabel
@onready var tower_buttons: GridContainer = %TowerButtons
@onready var wave_label: Label = %WaveLabel
@onready var wave_scroll: ScrollContainer = %WaveScroll
@onready var wave_blocks: VBoxContainer = %WaveBlocks

var _money := 0
var _buttons: Array[TowerButton] = []
var _wave_blocks: Array[WaveBlock] = []
var _current_wave := -1

func _ready() -> void:
	var tab_group := ButtonGroup.new()
	for tab in [towers_tab, waves_tab]:
		tab.button_group = tab_group
		_style_tab(tab)
	towers_tab.toggled.connect(_on_tab_toggled)

func build_buttons(towers: Array[TowerData]) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for data in towers:
		var button: TowerButton = TOWER_BUTTON.instantiate()
		tower_buttons.add_child(button)
		button.setup(data, _money)
		button.selection_changed.connect(_on_button_selection_changed)
		_buttons.append(button)

func set_money(amount: int) -> void:
	_money = amount
	money_label.text = "%s€" % UiFormat.abbreviate(amount)
	for b in _buttons:
		b.set_money(amount)

## Refleja la selección de LevelState sin volver a emitir tower_selected.
func show_selected(data: TowerData) -> void:
	for b in _buttons:
		b.set_selected(data != null and b.data == data)

## Crea un bloque por oleada y borra los anteriores.
func build_waves(waves: Array[WaveData]) -> void:
	for block in _wave_blocks:
		wave_blocks.remove_child(block)
		block.queue_free()
	_wave_blocks.clear()
	for i in waves.size():
		var block: WaveBlock = WAVE_BLOCK.instantiate()
		wave_blocks.add_child(block)
		block.setup(waves[i], i + 1)
		_wave_blocks.append(block)
	set_current_wave(-1, waves.size())

## Marca la oleada en curso (índice desde 0, -1 si ninguna) y actualiza la cabecera.
func set_current_wave(index: int, total: int) -> void:
	_current_wave = index
	wave_label.text = "OL. %d/%d" % [maxi(index + 1, 1), total]
	for i in _wave_blocks.size():
		if i < index:
			_wave_blocks[i].set_state(WaveBlock.State.PAST)
		elif i == index:
			_wave_blocks[i].set_state(WaveBlock.State.CURRENT)
		else:
			_wave_blocks[i].set_state(WaveBlock.State.FUTURE)
	if index >= 0 and index < _wave_blocks.size():
		_scroll_to_block(_wave_blocks[index])

func _scroll_to_block(block: WaveBlock) -> void:
	# Hay que esperar a que el contenedor calcule las posiciones.
	await get_tree().process_frame
	if is_instance_valid(block) and block.is_inside_tree():
		wave_scroll.ensure_control_visible(block)

func _on_button_selection_changed(data: TowerData, on: bool) -> void:
	tower_selected.emit(data if on else null)

func _on_tab_toggled(towers_active: bool) -> void:
	towers_page.visible = towers_active
	waves_page.visible = not towers_active
	if not towers_active and _current_wave >= 0 and _current_wave < _wave_blocks.size():
		_scroll_to_block(_wave_blocks[_current_wave])

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
	tab.add_theme_color_override("icon_pressed_color", Color.WHITE)
	tab.add_theme_color_override("icon_hover_pressed_color", Color.WHITE)

func _make_tab_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style
