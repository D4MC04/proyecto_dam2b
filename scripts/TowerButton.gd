extends Button
class_name TowerButton

@onready var icon_rect: TextureRect = %IconRect
@onready var cost_label: Label = %CostLabel

var data: TowerData

func _ready() -> void:
	resized.connect(_keep_square)
	toggled.connect(_on_toggled)
	GameState.money_changed.connect(_update_affordable)

func setup(tower_data: TowerData) -> void:
	data = tower_data
	icon_rect.texture = data.icon
	cost_label.text = "%s€" % data.cost
	_update_affordable()

func _update_affordable(_amount: int = 0) -> void:
	if data == null:
		return
	disabled = GameState.money < data.cost
	if disabled and button_pressed:
		button_pressed = false

func _on_toggled(on: bool) -> void:
	if on:
		GameState.selected_tower = data
	elif GameState.selected_tower == data:
		GameState.selected_tower = null

func _keep_square() -> void:
	custom_minimum_size.y = size.x
