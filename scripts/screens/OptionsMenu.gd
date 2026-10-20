class_name OptionsMenu
extends Control

const FADE_TIME := 0.25
# Segundos que dura el aviso "¿Seguro?" antes de cancelarse solo.
const CONFIRM_TIME := 3.0

# Panel desde el que se abrió y al que vuelve "Volver" (título o menú de pausa).
var _opener: Control
var _tween: Tween
var _confirming_reset: bool = false

@onready var _reset_button: Button = %ResetProgressButton

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

func _on_reset_progress_button_pressed() -> void:
	if not _confirming_reset:
		_confirming_reset = true
		_reset_button.text = "¿Seguro? Pulsa otra vez"
		get_tree().create_timer(CONFIRM_TIME).timeout.connect(_cancel_reset_confirmation)
		return
	GameState.reset_progress()
	_cancel_reset_confirmation()

func _cancel_reset_confirmation() -> void:
	_confirming_reset = false
	_reset_button.text = "Borrar"

func _update_toggle_text(button: Button) -> void:
	button.text = "ON" if button.button_pressed else "OFF"

func open_from(opener: Control) -> void:
	_opener = opener
	_fade(opener, self)

# Vuelve al panel de origen sin fundido, por ejemplo al cerrar la pausa con Escape.
func close() -> void:
	if _tween:
		_tween.kill()
	hide()
	if _opener:
		_opener.modulate.a = 1.0
		_opener.show()

func _on_back_button_pressed() -> void:
	_fade(self, _opener)

func _fade(from: Control, to: Control) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(from, "modulate:a", 0.0, FADE_TIME)
	_tween.tween_callback(func() -> void:
		from.hide()
		to.modulate.a = 0.0
		to.show())
	_tween.tween_property(to, "modulate:a", 1.0, FADE_TIME)
