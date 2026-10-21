class_name BossAlert
extends Control

# Duración total (en tiempo real) y número de latidos del tinte rojo.
const TOTAL_TIME := 2.0
const PULSES := 4
const BAND_HEIGHT := 120
const STRIPE_HEIGHT := 14
const STRIPE_WIDTH := 16
const BORDER_WIDTH := 12
const MAX_TINT := 0.35
const ALERT_COLOR := Color("#f0323c")
const BAND_COLOR := Color("#7a0f18")
const STRIPE_DARK := Color("#14060a")
# Sirena: tono que sube y baja entre SIREN_LOW y SIREN_HIGH, SIREN_CYCLES veces.
const SIREN_LOW := 600.0
const SIREN_HIGH := 900.0
const SIREN_CYCLES := 2
const SIREN_RATE := 22050
const SIREN_VOLUME := 0.35

var _title: Label = Label.new()
var _subtitle: Label = Label.new()
var _siren: AudioStreamPlayer = AudioStreamPlayer.new()
# Intensidad del tinte y del borde, de 0 a 1.
var _pulse: float = 0.0
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
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
	_title.text = "ALERTA"
	_title.add_theme_font_size_override(&"font_size", 48)
	_subtitle.add_theme_font_size_override(&"font_size", 32)
	_siren.stream = _make_siren()
	_siren.bus = &"SFX"
	add_child(_siren)

## Enseña la alerta: tinte rojo que late, borde grueso, franja con aviso y sirena.
func show_alert(boss_name: String) -> void:
	if _tween != null:
		_tween.kill()
	_subtitle.text = "%s ACERCÁNDOSE" % boss_name.to_upper()
	visible = true
	_siren.play()
	_tween = create_tween().set_ignore_time_scale()
	_tween.tween_method(_set_pulse, 0.0, 1.0, TOTAL_TIME)
	_tween.tween_callback(func() -> void: visible = false)

# Seno al cuadrado: empieza y acaba a 0 y late PULSES veces.
func _set_pulse(t: float) -> void:
	_pulse = sin(t * PI * PULSES) ** 2
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(ALERT_COLOR, _pulse * MAX_TINT))
	var border := Color(ALERT_COLOR, 0.5 + 0.5 * _pulse)
	draw_rect(Rect2(0, 0, size.x, BORDER_WIDTH), border)
	draw_rect(Rect2(0, size.y - BORDER_WIDTH, size.x, BORDER_WIDTH), border)
	draw_rect(Rect2(0, 0, BORDER_WIDTH, size.y), border)
	draw_rect(Rect2(size.x - BORDER_WIDTH, 0, BORDER_WIDTH, size.y), border)
	var top := roundi(size.y / 2.0) - BAND_HEIGHT / 2
	draw_rect(Rect2(0, top, size.x, BAND_HEIGHT), BAND_COLOR)
	_draw_stripes(top)
	_draw_stripes(top + BAND_HEIGHT - STRIPE_HEIGHT)

# Rayas de aviso diagonales rojas y negras, de lado a lado de la franja.
func _draw_stripes(y: int) -> void:
	draw_rect(Rect2(0, y, size.x, STRIPE_HEIGHT), STRIPE_DARK)
	var x := -STRIPE_HEIGHT
	while x < size.x:
		var x1 := x + STRIPE_WIDTH / 2
		draw_colored_polygon(PackedVector2Array([
			Vector2(clampf(x, 0, size.x), y), Vector2(clampf(x1, 0, size.x), y),
			Vector2(clampf(x1 + STRIPE_HEIGHT, 0, size.x), y + STRIPE_HEIGHT),
			Vector2(clampf(x + STRIPE_HEIGHT, 0, size.x), y + STRIPE_HEIGHT)]), ALERT_COLOR)
		x += STRIPE_WIDTH

# Sirena generada por código: onda cuadrada suave (seno) de tono variable, PCM 16 bits mono.
func _make_siren() -> AudioStreamWAV:
	var count := int(TOTAL_TIME * SIREN_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		var freq := lerpf(SIREN_LOW, SIREN_HIGH, 0.5 - 0.5 * cos(t * TAU * SIREN_CYCLES))
		phase += freq / SIREN_RATE
		# Entra y sale con un fundido corto para evitar chasquidos.
		var fade := minf(minf(t, 1.0 - t) * 20.0, 1.0)
		data.encode_s16(i * 2, int(sin(phase * TAU) * SIREN_VOLUME * fade * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SIREN_RATE
	stream.data = data
	return stream
