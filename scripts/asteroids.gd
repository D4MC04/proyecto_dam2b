extends Node2D

# Asteroides que cruzan el menú de borde a borde, girando con su spritesheet (space_body)
# y con una estela corta dibujada detrás.

const SHEETS = [
	preload("res://assets/sprites/planets/asteroide_1.png"),
	preload("res://assets/sprites/planets/asteroide_2.png"),
	preload("res://assets/sprites/planets/asteroide_3.png"),
	preload("res://assets/sprites/planets/asteroide_4.png"),
]
const BODY = preload("res://scenes/space_body.tscn")
const MAX_ACTIVE = 2
const SPEED = 60.0
const SCALE = 0.22          # frame de 100px -> ~22px en pantalla
const MARGIN = 20.0         # aparecen/desaparecen fuera de pantalla
const TAIL_LENGTH = 22.0
const TAIL_WIDTH = 4.0
const TAIL_COLOR = Color(0.75, 0.95, 1.0)

var viewport_size: Vector2
var rng = RandomNumberGenerator.new()
var asteroids = []  # cada uno: {"node": AnimatedSprite2D, "dir": Vector2}
var wait = 0.0

func _ready():
	viewport_size = get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(2.0, 6.0)

func _process(delta):
	wait -= delta
	if wait <= 0.0:
		wait = rng.randf_range(3.0, 7.0)
		if asteroids.size() < MAX_ACTIVE:
			_spawn()
	for a in asteroids:
		a["node"].position += a["dir"] * SPEED * delta
	for a in asteroids.filter(_is_outside):
		a["node"].queue_free()
	asteroids = asteroids.filter(func(a): return not _is_outside(a))
	queue_redraw()

func _is_outside(a) -> bool:
	var p = a["node"].position
	return p.x < -MARGIN or p.x > viewport_size.x + MARGIN or p.y < -MARGIN or p.y > viewport_size.y + MARGIN

func _spawn():
	# De un borde al opuesto, en horizontal o vertical, con punto de entrada/salida al azar
	var start: Vector2
	var end: Vector2
	if rng.randf() < 0.5:
		start = Vector2(-MARGIN, rng.randf_range(0, viewport_size.y))
		end = Vector2(viewport_size.x + MARGIN, rng.randf_range(0, viewport_size.y))
	else:
		start = Vector2(rng.randf_range(0, viewport_size.x), -MARGIN)
		end = Vector2(rng.randf_range(0, viewport_size.x), viewport_size.y + MARGIN)
	if rng.randf() < 0.5:
		var tmp = start
		start = end
		end = tmp
	var dir = (end - start).normalized()

	var body = BODY.instantiate()
	body.fps = rng.randf_range(8.0, 14.0)
	body.sheet = SHEETS[rng.randi() % SHEETS.size()]
	body.scale = Vector2(SCALE, SCALE)
	body.position = start + dir  # un paso dentro para no borrarlo en el primer frame
	add_child(body)
	asteroids.append({"node": body, "dir": dir})

func _draw():
	# El padre se dibuja antes que sus hijos, así la estela queda detrás del asteroide
	for a in asteroids:
		var head = a["node"].position
		var tail = head - a["dir"] * TAIL_LENGTH
		draw_polyline_colors(PackedVector2Array([tail, head]), PackedColorArray([Color(TAIL_COLOR, 0.0), Color(TAIL_COLOR, 0.5)]), TAIL_WIDTH)
