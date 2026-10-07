extends Control

signal resume_requested
signal restart_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:

	resume_button.pressed.connect(resume_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
