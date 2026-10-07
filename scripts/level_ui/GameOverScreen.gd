extends Control

signal restart_requested
signal quit_requested

@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:

	restart_button.pressed.connect(restart_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
