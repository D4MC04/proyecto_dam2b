class_name OfficeLights
extends Control

# Pilotos de una vista de la oficina: los huecos están pintados en el PNG de la habitación y aquí se
# encienden, algunos parpadeando. En la vista central, además, un destello recorre el tubo de la
# barra de luz entre el ventanal y la consola, con una estela, y pasa por debajo de las abrazaderas.
# Ocupa la vista entera y no recibe el ratón.

enum View { LEFT, CENTER, RIGHT }

@export var view: View = View.CENTER

# Parte de pilotos que parpadean sin periodo fijo y rango de su periodo (s).
const RANDOM_BLINK_CHANCE: float = 0.35
const RANDOM_BLINK_PERIOD: Vector2 = Vector2(0.6, 3.0)
const ON_FRACTION: float = 0.55
const OFF_DARKEN: float = 0.72
const GLINT_SPEED: float = 140.0
const GLINT_LENGTH: int = 36
const GLINT_TAIL: int = 30
const GLINT_CORE: int = 12

# Cada piloto: rectángulo, color, periodo (0 = fijo) y fase.
var _leds: Array[Dictionary] = []
# Tubo de la barra de luz (y, h y los tramos [x, ancho] de las abrazaderas); vacío fuera del centro.
var _strip: Dictionary = {}
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout: Dictionary = [OfficeLayout.LEFT, OfficeLayout.CENTER, OfficeLayout.RIGHT][view]
	if view == View.CENTER:
		_strip = layout.strip
	# Semilla fija: los mismos pilotos parpadean cada vez que se abre el menú.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
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
	for led: Dictionary in _leds:
		var period: float = led.period
		var on: bool = period == 0.0 or fmod(_time + led.phase, period) < period * ON_FRACTION
		var color: Color = led.color
		OfficePaint.rect(self, led.rect, color if on else color.darkened(OFF_DARKEN))
	if not _strip.is_empty():
		_draw_glint()

# Destello del tubo: estela tenue, cuerpo claro en todo el tubo y núcleo blanco delante.
func _draw_glint() -> void:
	var head: int = roundi(fmod(_time * GLINT_SPEED, size.x + GLINT_LENGTH + GLINT_TAIL)) - 1
	var body: int = head - GLINT_LENGTH
	var y: int = _strip.y
	var height: int = _strip.h
	_on_tube(body - GLINT_TAIL, body, y + 1, height - 2, Color(OfficePaint.CYAN_LIGHT, 0.4))
	_on_tube(body, head, y, height, OfficePaint.CYAN)
	_on_tube(body, head, y + 1, height - 2, OfficePaint.CYAN_LIGHT)
	_on_tube(head - GLINT_CORE - 4, head - 4, y + 2, 1, Color.WHITE)

# Franja [from, to) de `rows` filas del tubo, sin pintar encima de las abrazaderas.
func _on_tube(from: int, to: int, y: int, rows: int, color: Color) -> void:
	var x: int = from
	for clamp_span: Array in _strip.clamps:
		var clamp_start: int = clamp_span[0]
		var clamp_end: int = clamp_start + int(clamp_span[1])
		if clamp_end <= x:
			continue
		if clamp_start >= to:
			break
		OfficePaint.rect(self, Rect2i(x, y, clamp_start - x, rows), color)
		x = clamp_end
	OfficePaint.rect(self, Rect2i(x, y, to - x, rows), color)

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
