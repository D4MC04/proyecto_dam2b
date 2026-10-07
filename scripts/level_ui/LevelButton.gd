extends Button
class_name LevelButton

signal level_selected(data: LevelData)

@export var level: LevelData

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	level_selected.emit(level)
