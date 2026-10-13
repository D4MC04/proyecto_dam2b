extends Control

signal closed

# Opción de Settings -> control que la edita.
@onready var _sliders: Dictionary[StringName, Slider] = {
	&"master_volume": %MasterSlider,
	&"music_volume": %MusicSlider,
	&"sfx_volume": %SfxSlider,
}
@onready var _toggles: Dictionary[StringName, Button] = {
	&"muted": %MuteButton,
	&"fullscreen": %FullscreenButton,
	&"vsync": %VsyncButton,
	&"show_fps": %FpsButton,
	&"show_tower_range": %TowerRangeButton,
}

func _ready() -> void:
	for key in _sliders:
		var slider := _sliders[key]
		slider.set_value_no_signal(Settings.get_value(key))
		slider.value_changed.connect(func(value: float) -> void: Settings.set_value(key, value))
	for key in _toggles:
		var button := _toggles[key]
		button.set_pressed_no_signal(Settings.get_value(key))
		_update_toggle_text(button)
		button.toggled.connect(func(on: bool) -> void:
			Settings.set_value(key, on)
			_update_toggle_text(button))

func _update_toggle_text(button: Button) -> void:
	button.text = "ON" if button.button_pressed else "OFF"

func _on_back_button_pressed() -> void:
	closed.emit()
