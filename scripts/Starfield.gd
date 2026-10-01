extends Node2D

# ponytail: capas fijas por simplicidad, ver LAYERS si se necesita más variedad
const LAYERS = [
	{"count": 40, "size": 1.0, "brightness": 0.35},
	{"count": 25, "size": 1.0, "brightness": 0.65},
	{"count": 12, "size": 1.0, "brightness": 1.0},
	{"count": 6, "size": 5.0, "brightness": 1.0, "sparkle": true},  # destellos de 4 puntas, el detalle especial
]
const SMALL_COLORS = [Color(1, 1, 1), Color(0.8, 0.92, 1.0)]  # blanco, celeste tenue
const SPARKLE_COLORS = [
	Color(1, 1, 1),         # blanco
	Color(0.55, 0.95, 1.0), # cian
	Color(0.75, 0.55, 1.0), # morado
	Color(1.0, 0.6, 0.35),  # naranja cálido
]

var stars = []
var viewport_size: Vector2
var time = 0.0

func _ready():
	viewport_size = get_viewport_rect().size
	for layer in LAYERS:
		var sparkle = layer.get("sparkle", false)
		var colors = SPARKLE_COLORS if sparkle else SMALL_COLORS
		for i in layer["count"]:
			stars.append({
				"pos": Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y)),
				"size": layer["size"],
				"brightness": layer["brightness"],
				"phase": randf_range(0, TAU),
				"twinkle": sparkle or randf() < 0.3,  # destellos siempre, puntos solo ~30%
				"rate": randf_range(0.8, 2.5),  # ritmo propio de cada estrella
				"sparkle": sparkle,
				"color": colors[randi() % colors.size()],
			})

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	for star in stars:
		var alpha = star["brightness"]
		var size = star["size"]
		var wave = 1.0
		if star["twinkle"]:
			wave = 0.5 + 0.5 * sin(time * star["rate"] + star["phase"])  # 0..1
			alpha *= lerp(0.15, 1.0, wave)
		var color = Color(star["color"], alpha)
		if star["sparkle"]:
			_draw_sparkle(star["pos"].round() + Vector2(0.5, 0.5), size * lerp(0.6, 1.0, wave), color)
			continue
		draw_rect(Rect2(star["pos"].floor(), Vector2.ONE), color)  # punto de 1 píxel exacto

# Destello de 4 puntas: glow suave + dos rombos finos cruzados + núcleo blanco
func _draw_sparkle(c: Vector2, arm: float, color: Color):
	draw_circle(c, arm * 0.5, Color(color, color.a * 0.2))
	var w = 0.9  # medio grosor de las puntas en el centro
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -arm), c + Vector2(w, 0), c + Vector2(0, arm), c + Vector2(-w, 0)]), color)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-arm, 0), c + Vector2(0, -w), c + Vector2(arm, 0), c + Vector2(0, w)]), color)
	draw_circle(c, 1.0, Color(1, 1, 1, color.a))
