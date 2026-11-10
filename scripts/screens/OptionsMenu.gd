class_name OptionsMenu
extends Control

## "Volver" sin panel de origen (abierto desde la oficina del menú, que hace el fundido).
signal back_pressed

const FADE_TIME: float = 0.25

# Panel desde el que se abrió y al que vuelve "Volver" (menú de pausa); null si lo abre la oficina.
var _opener: Control
var _tween: Tween

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
	&"show_turret_range": %TurretRangeButton,
	&"show_damage_numbers": %DamageNumbersButton,
	&"pause_on_focus_loss": %FocusPauseButton,
}
@onready var _language_button: Button = %LanguageButton

func _ready() -> void:
	for key: StringName in _sliders:
		var slider: Slider = _sliders[key]
		slider.set_value_no_signal(Settings.get_value(key))
		slider.value_changed.connect(func(value: float) -> void: Settings.set_value(key, value))
	for key: StringName in _toggles:
		var button: Button = _toggles[key]
		button.set_pressed_no_signal(Settings.get_value(key))
		_update_toggle_text(button)
		button.toggled.connect(func(on: bool) -> void:
			Settings.set_value(key, on)
			_update_toggle_text(button))
	_update_language_text()
	_language_button.pressed.connect(_on_language_button_pressed)

func _update_toggle_text(button: Button) -> void:
	button.text = "ON" if button.button_pressed else "OFF"

# Pasa al siguiente idioma de Settings.LANGUAGES; los textos con clave se traducen solos.
func _on_language_button_pressed() -> void:
	var languages: PackedStringArray = Settings.LANGUAGES
	var index: int = languages.find(Settings.get_value(&"language"))
	Settings.set_value(&"language", languages[(index + 1) % languages.size()])
	_update_language_text()

func _update_language_text() -> void:
	_language_button.text = String(Settings.get_value(&"language")).to_upper()

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
	if _opener:
		_fade(self, _opener)
	else:
		back_pressed.emit()

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
