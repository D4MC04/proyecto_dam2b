extends Node2D

# ponytail: capas fijas por simplicidad, ver LAYERS si se necesita más variedad
const LAYERS: Array[Dictionary] = [
	{"count": 40, "size": 1.0, "brightness": 0.35},
	{"count": 25, "size": 1.0, "brightness": 0.65},
	{"count": 12, "size": 1.0, "brightness": 1.0},
	{"count": 6, "size": 5.0, "brightness": 1.0, "sparkle": true},  # destellos de 4 puntas, el detalle especial
]
const SMALL_COLORS: Array[Color] = [Color(1, 1, 1), Color(0.8, 0.92, 1.0)]  # blanco, celeste tenue
const SPARKLE_COLORS: Array[Color] = [
	Color(1, 1, 1),         # blanco
	Color(0.55, 0.95, 1.0), # cian
	Color(0.75, 0.55, 1.0), # morado
	Color(1.0, 0.6, 0.35),  # naranja cálido
]

var stars: Array[Dictionary] = []
var viewport_size: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var time: float = 0.0
var warp_progress: float = 0.0  # 0 = quietas, 1 = líneas al máximo
var warping: bool = false

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	rng.randomize()
	for layer in LAYERS:
		var sparkle: bool = layer.get("sparkle", false)
		var colors: Array[Color] = SPARKLE_COLORS if sparkle else SMALL_COLORS
		for i in layer["count"]:
			stars.append({
				"pos": Vector2(rng.randf_range(0, viewport_size.x), rng.randf_range(0, viewport_size.y)),
				"size": layer["size"],
				"brightness": layer["brightness"],
				"phase": rng.randf_range(0, TAU),
				"twinkle": sparkle or rng.randf() < 0.3,  # destellos siempre, puntos solo ~30%
				"rate": rng.randf_range(0.8, 2.5),  # ritmo propio de cada estrella
				"sparkle": sparkle,
				"color": colors[rng.randi() % colors.size()],
			})

# Salto al hiperespacio: las estrellas se estiran en líneas desde el centro hacia fuera.
func warp(duration: float) -> void:
	warping = true
	var tween := create_tween()
	tween.tween_property(self, "warp_progress", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = viewport_size / 2.0
	for star in stars:
		var alpha: float = star["brightness"]
		var size: float = star["size"]
		var wave: float = 1.0
		if star["twinkle"]:
			wave = 0.5 + 0.5 * sin(time * star["rate"] + star["phase"])  # 0..1
			alpha *= lerp(0.15, 1.0, wave)
		var color: Color = Color(star["color"], alpha)
		if warping:
			var tail: Vector2 = star["pos"].floor()
			var head: Vector2 = center + (tail - center) * (1.0 + 6.0 * warp_progress)
			draw_line(tail, head, Color(color, maxf(alpha, warp_progress)), 1.0, false)
			continue
		if star["sparkle"]:
			_draw_sparkle(star["pos"].round() + Vector2(0.5, 0.5), size * lerp(0.6, 1.0, wave), color)
			continue
		draw_rect(Rect2(star["pos"].floor(), Vector2.ONE), color)  # punto de 1 píxel exacto

# Destello de 4 puntas: glow suave + dos rombos finos cruzados + núcleo blanco
func _draw_sparkle(c: Vector2, arm: float, color: Color) -> void:
	draw_circle(c, arm * 0.5, Color(color, color.a * 0.2))
	var w: float = 0.9  # medio grosor de las puntas en el centro
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -arm), c + Vector2(w, 0), c + Vector2(0, arm), c + Vector2(-w, 0)]), color)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-arm, 0), c + Vector2(0, -w), c + Vector2(arm, 0), c + Vector2(0, w)]), color)
	draw_circle(c, 1.0, Color(1, 1, 1, color.a))
