class_name WaveAnnouncer
extends Control

# Tiempos en segundos de tiempo real: entra, se queda y se desvanece.
const FADE_IN_TIME := 0.25
const HOLD_TIME := 1.5
const FADE_OUT_TIME := 0.4
const TITLE_COLOR := Color("#40e0f0")
const SUBTITLE_COLOR := Color("#cce6ff")

var _title: Label = Label.new()
var _subtitle: Label = Label.new()
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	center.add_child(box)
	for label: Label in [_title, _subtitle]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override(&"font_outline_color", Color.BLACK)
		label.add_theme_constant_override(&"outline_size", 4)
		box.add_child(label)
	_title.add_theme_font_size_override(&"font_size", 48)
	_title.add_theme_color_override(&"font_color", TITLE_COLOR)
	_subtitle.add_theme_font_size_override(&"font_size", 16)
	_subtitle.add_theme_color_override(&"font_color", SUBTITLE_COLOR)

## Enseña el aviso de la oleada number (de 1 a total).
func show_wave(number: int, total: int) -> void:
	_title.text = "ÚLTIMA OLEADA" if number == total else "OLEADA %d" % number
	_subtitle.text = "%d / %d" % [number, total]
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME)
