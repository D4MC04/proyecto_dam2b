extends Control

signal resume_requested
signal restart_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var options_button: Button = %OptionsButton
@onready var box: VBoxContainer = $Box
@onready var options_menu: OptionsMenu = $OptionsMenu

func _ready() -> void:

	resume_button.pressed.connect(resume_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	options_button.pressed.connect(func() -> void: options_menu.open_from(box))
	# Al cerrar la pausa con las opciones abiertas, la próxima vez se abre por los botones.
	visibility_changed.connect(func() -> void:
		if not visible:
			options_menu.close())
