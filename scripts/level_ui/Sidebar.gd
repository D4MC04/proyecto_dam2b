extends PanelContainer
class_name Sidebar

signal tower_selected(data: TowerData)

const TOWER_BUTTON: PackedScene = preload("res://scenes/level_ui/TowerButton.tscn")

@onready var money_label: Label = %MoneyLabel
@onready var tower_buttons: GridContainer = %TowerButtons

var button_group := ButtonGroup.new()
var _money := 0
var _buttons: Array[TowerButton] = []

func _ready() -> void:
	button_group.allow_unpress = true

func build_buttons(towers: Array[TowerData]) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for data in towers:
		var button: TowerButton = TOWER_BUTTON.instantiate()
		tower_buttons.add_child(button)
		button.button_group = button_group
		button.setup(data, _money)
		button.selection_changed.connect(_on_button_selection_changed)
		_buttons.append(button)

func set_money(amount: int) -> void:
	_money = amount
	money_label.text = "%s€" % amount
	for b in _buttons:
		b.set_money(amount)

## Refleja la selección de LevelState sin volver a disparar toggled.
func show_selected(data: TowerData) -> void:
	for b in _buttons:
		b.set_pressed_no_signal(data != null and b.data == data)

func _on_button_selection_changed(data: TowerData, on: bool) -> void:
	if on:
		tower_selected.emit(data)
	# Al cambiar de A a B, A se suelta pero B ya está pulsado: no es una deselección.
	elif button_group.get_pressed_button() == null:
		tower_selected.emit(null)
