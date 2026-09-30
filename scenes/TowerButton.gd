extends Button
class_name TowerButton

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel

func _ready() -> void:
	resized.connect(_keep_square)

func setup(data: TowerData) -> void:
	icon_rect.texture = data.icon
	name_label.text = "%s (%d)" % [data.name, data.cost]

func _keep_square() -> void:
	custom_minimum_size.y = size.x
