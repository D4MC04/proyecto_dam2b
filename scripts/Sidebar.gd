extends PanelContainer
class_name Sidebar

signal tower_selected(data: TowerData)

const TOWER_BUTTON: PackedScene = preload("res://Scenes/TowerButton.tscn")

@onready var tower_buttons: GridContainer = %TowerButtons

func _ready() -> void:
	for data in GameState.available_towers:
		var button: TowerButton = TOWER_BUTTON.instantiate()
		tower_buttons.add_child(button)
		button.setup(data)
		button.pressed.connect(tower_selected.emit.bind(data))
