extends Button
class_name TowerButton

signal selection_changed(data: TowerData, on: bool)

@onready var icon_rect: TextureRect = %IconRect
@onready var cost_label: Label = %CostLabel

var data: TowerData
var _money := 0

func _ready() -> void:
	resized.connect(_keep_square)
	toggled.connect(_on_toggled)

func setup(tower_data: TowerData, money: int) -> void:
	data = tower_data
	icon_rect.texture = data.icon
	cost_label.text = "%s€" % data.cost
	set_money(money)

func set_money(amount: int) -> void:
	_money = amount
	if data == null:
		return
	disabled = _money < data.cost
	if disabled and button_pressed:
		button_pressed = false   # dispara toggled(false)

func _on_toggled(on: bool) -> void:
	selection_changed.emit(data, on)

func _keep_square() -> void:
	custom_minimum_size.y = size.x
