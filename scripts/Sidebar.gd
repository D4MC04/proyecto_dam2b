extends PanelContainer
class_name Sidebar

const TOWER_BUTTON: PackedScene = preload("res://scenes/TowerButton.tscn")

@onready var money_label: Label = %MoneyLabel
@onready var tower_buttons: GridContainer = %TowerButtons

var button_group := ButtonGroup.new()

func _ready() -> void:
	_update_money(GameState.money)
	GameState.money_changed.connect(_update_money)
	button_group.allow_unpress = true
	for data in GameState.available_towers:
		var button: TowerButton = TOWER_BUTTON.instantiate()
		tower_buttons.add_child(button)
		button.button_group = button_group
		button.setup(data)

func _update_money(amount: int) -> void:
	money_label.text = "%s€" % amount
