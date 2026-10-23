extends Button
class_name TurretButton

## Petición de cambio de selección: on = seleccionar esta torreta, !on = soltarla.
signal selection_changed(data: TurretData, on: bool)
## Petición de enseñar esta torreta en la ficha (clic derecho o izquierdo, se pueda pagar o no).
signal inspect_requested(data: TurretData)

const BORDER_COLOR := Color("#1c7496")
const HOVER_BORDER_COLOR := Color("#40e0f0")
const BG_COLOR := Color("#0e1626")
const HOVER_BG_COLOR := Color("#16243c")
const SELECTED_COLOR := Color("#ecb23c")
const SELECTED_HOVER_BORDER_COLOR := Color("#ffe082")
const UNAFFORDABLE_COST_COLOR := Color("#ff3c5a")
const AFFORDABLE_COST_COLOR := Color("#ecb23c")
const UNAFFORDABLE_ICON_COLOR := Color(1, 1, 1, 0.35)
# Largo de cada brazo de los corchetes que rodean la torreta seleccionada por fuera.
const BRACKET_LENGTH := 4

@onready var icon_rect: TextureRect = %IconRect
@onready var cost_label: Label = %CostLabel

var data: TurretData
var _money := 0
var _selected := false
var _affordable := true
# Con una pantalla abierta el clic izquierdo solo enseña la ficha: no selecciona ni suelta.
var _selection_locked := false

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(turret_data: TurretData, money: int) -> void:
	data = turret_data
	icon_rect.texture = data.icon
	cost_label.text = UiFormat.money(data.cost)
	set_money(money)

func set_money(amount: int) -> void:
	_money = amount
	if data == null:
		return
	_affordable = _money >= data.cost
	if not _affordable and _selected and not _selection_locked:
		# Ya no te llega: se pide soltarla. LevelState confirma con show_selected.
		selection_changed.emit(data, false)
	_refresh()

## Bloquea o desbloquea la selección con el clic izquierdo; la ficha sigue funcionando.
func set_selection_locked(locked: bool) -> void:
	_selection_locked = locked
	if not locked and _selected and not _affordable:
		# Se quedó sin dinero mientras estaba bloqueada: se pide soltarla.
		selection_changed.emit(data, false)

## Refleja la selección de LevelState; no emite nada.
func set_selected(on: bool) -> void:
	_selected = on
	_refresh()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(data)
		accept_event()

func _on_pressed() -> void:
	# Solo el clic izquierdo llega aquí; el derecho se recoge en _gui_input.
	inspect_requested.emit(data)
	if _selection_locked or not _affordable:
		return
	selection_changed.emit(data, not _selected)

# Corchetes en L en ámbar justo por fuera de las cuatro esquinas de la torreta seleccionada.
func _draw() -> void:
	if not _selected:
		return
	var left := -1
	var top := -1
	var right := int(size.x)
	var bottom := int(size.y)
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		# Los brazos salen de la esquina hacia el centro del botón.
		var x_start := corner.x if corner.x == left else corner.x - BRACKET_LENGTH + 1
		var y_start := corner.y if corner.y == top else corner.y - BRACKET_LENGTH + 1
		draw_rect(Rect2(x_start, corner.y, BRACKET_LENGTH, 1), SELECTED_COLOR)
		draw_rect(Rect2(corner.x, y_start, 1, BRACKET_LENGTH), SELECTED_COLOR)

func _refresh() -> void:
	if data == null:
		return
	var normal := ClippedBoxStyle.create(BG_COLOR, BORDER_COLOR)
	var hover := ClippedBoxStyle.create(HOVER_BG_COLOR, HOVER_BORDER_COLOR)
	var selected := ClippedBoxStyle.create(BG_COLOR.lerp(SELECTED_COLOR, 0.25), SELECTED_COLOR)
	var selected_hover := ClippedBoxStyle.create(BG_COLOR.lerp(SELECTED_COLOR, 0.4), SELECTED_HOVER_BORDER_COLOR)
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
