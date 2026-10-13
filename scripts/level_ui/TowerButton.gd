extends Button
class_name TowerButton

## Petición de cambio de selección: on = seleccionar esta torre, !on = soltarla.
signal selection_changed(data: TowerData, on: bool)

const BORDER_COLOR := Color("#1c7496")
const HOVER_BORDER_COLOR := Color("#40e0f0")
const BG_COLOR := Color("#0e1626")
const HOVER_BG_COLOR := Color("#16243c")
const UNAFFORDABLE_COST_COLOR := Color("#ff3c5a")
const AFFORDABLE_COST_COLOR := Color("#ecb23c")
const UNAFFORDABLE_ICON_COLOR := Color(1, 1, 1, 0.35)
# Fuente a 8 px: 8 px por carácter. El botón mide 34 px, así que solo caben 4.
const MAX_COST_CHARS_WITH_SYMBOL := 4

@onready var icon_rect: TextureRect = %IconRect
@onready var cost_label: Label = %CostLabel

var data: TowerData
var _money := 0
var _selected := false
var _affordable := true

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(tower_data: TowerData, money: int) -> void:
	data = tower_data
	icon_rect.texture = data.icon
	tooltip_text = data.name
	var cost_text := UiFormat.abbreviate(data.cost)
	if cost_text.length() < MAX_COST_CHARS_WITH_SYMBOL:
		cost_text += "€"
	cost_label.text = cost_text
	set_money(money)

func set_money(amount: int) -> void:
	_money = amount
	if data == null:
		return
	_affordable = _money >= data.cost
	if not _affordable and _selected:
		# Ya no te llega: se pide soltarla. LevelState confirma con show_selected.
		selection_changed.emit(data, false)
	_refresh()

## Refleja la selección de LevelState; no emite nada.
func set_selected(on: bool) -> void:
	_selected = on
	_refresh()

func _on_pressed() -> void:
	# Solo el clic izquierdo llega aquí; el derecho sigue disponible por gui_input.
	if not _affordable:
		return
	selection_changed.emit(data, not _selected)

func _refresh() -> void:
	if data == null:
		return
	var accent: Color = data.accent_color
	var normal := _make_style(BG_COLOR, BORDER_COLOR)
	var hover := _make_style(HOVER_BG_COLOR, HOVER_BORDER_COLOR)
	var selected := _make_style(BG_COLOR.lerp(accent, 0.25), accent)
	var selected_hover := _make_style(BG_COLOR.lerp(accent, 0.4), accent.lightened(0.3))
	var empty := StyleBoxEmpty.new()
	if _selected:
		normal = selected
		hover = selected_hover
	elif not _affordable:
		hover = normal   # sin resalte: no se puede comprar
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("disabled", normal)
	add_theme_stylebox_override("focus", empty)
	icon_rect.modulate = Color.WHITE if _affordable else UNAFFORDABLE_ICON_COLOR
	var cost_color := AFFORDABLE_COST_COLOR if _affordable else UNAFFORDABLE_COST_COLOR
	cost_label.add_theme_color_override("font_color", cost_color)

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style
