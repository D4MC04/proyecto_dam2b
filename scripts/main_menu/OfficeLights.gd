class_name OfficeLights
extends Control

# Pilotos de una vista de la oficina: los huecos están pintados en el PNG de la habitación y aquí se
# encienden, algunos parpadeando. En la vista central, además, un destello recorre la línea de luz
# entre el ventanal y la consola. Ocupa la vista entera y no recibe el ratón.

enum View { LEFT, CENTER, RIGHT }

@export var view := View.CENTER

# Parte de pilotos que parpadean sin periodo fijo y rango de su periodo (s).
const RANDOM_BLINK_CHANCE := 0.35
const RANDOM_BLINK_PERIOD := Vector2(0.6, 3.0)
const ON_FRACTION := 0.55
const OFF_DARKEN := 0.72
const GLINT_SPEED := 140.0
const GLINT_LENGTH := 40

# Cada piloto: rectángulo, color, periodo (0 = fijo) y fase.
var _leds: Array[Dictionary] = []
var _glint_y := -1
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout: Dictionary = [OfficeLayout.LEFT, OfficeLayout.CENTER, OfficeLayout.RIGHT][view]
	if view == View.CENTER:
		_glint_y = layout.strip
	# Semilla fija: los mismos pilotos parpadean cada vez que se abre el menú.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + view
	for led: Dictionary in layout.get("leds", []):
		var period: float = led.p
		if period == 0.0 and rng.randf() < RANDOM_BLINK_CHANCE:
			period = rng.randf_range(RANDOM_BLINK_PERIOD.x, RANDOM_BLINK_PERIOD.y)
		_leds.append({
			"rect": Rect2i(led.x, led.y, led.w, led.h),
			"color": _palette(led.c),
			"period": period,
			"phase": rng.randf() * 10.0,
		})

func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	for led in _leds:
		var period: float = led.period
		var on := period == 0.0 or fmod(_time + led.phase, period) < period * ON_FRACTION
		var color: Color = led.color
		OfficePaint.rect(self, led.rect, color if on else color.darkened(OFF_DARKEN))
	if _glint_y >= 0:
		var x := roundi(fmod(_time * GLINT_SPEED, size.x + 60.0)) - 60
		OfficePaint.rect(self, Rect2i(x, _glint_y - 1, GLINT_LENGTH, 2), OfficePaint.CYAN_LIGHT)
		OfficePaint.rect(self, Rect2i(x + 14, _glint_y - 1, 12, 2), Color.WHITE)

# Nombre de color de los generadores (C2, G2, A2, R2...) en la paleta.
static func _palette(name: String) -> Color:
	match name:
		"C1":
			return OfficePaint.CYAN_DARK
		"G2":
			return OfficePaint.GREEN
		"A2":
			return OfficePaint.AMBER
		"R2":
			return OfficePaint.RED
		_:
			return OfficePaint.CYAN
