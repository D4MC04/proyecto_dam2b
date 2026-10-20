extends Node2D

# Asteroides que cruzan el menú de borde a borde, girando con su spritesheet (space_body)
# y con una estela corta dibujada detrás.

const SHEETS: Array[Texture2D] = [
	preload("res://assets/sprites/planets/asteroide_1.png"),
	preload("res://assets/sprites/planets/asteroide_2.png"),
	preload("res://assets/sprites/planets/asteroide_3.png"),
	preload("res://assets/sprites/planets/asteroide_4.png"),
]
const BODY: PackedScene = preload("res://scenes/SpaceBody.tscn")
const MAX_ACTIVE: int = 2
const SPEED: float = 60.0
const SCALE: float = 0.22          # frame de 100px -> ~22px en pantalla
const MARGIN: float = 20.0         # aparecen/desaparecen fuera de pantalla
const TAIL_LENGTH: float = 22.0
const TAIL_WIDTH: float = 4.0
const TAIL_COLOR: Color = Color(0.75, 0.95, 1.0)

var viewport_size: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var asteroids: Array[Dictionary] = []  # cada uno: {"node": AnimatedSprite2D, "dir": Vector2}
var wait: float = 0.0

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(2.0, 6.0)

func _process(delta: float) -> void:
	wait -= delta
	if wait <= 0.0:
		wait = rng.randf_range(3.0, 7.0)
		if asteroids.size() < MAX_ACTIVE:
			_spawn()
	for a in asteroids:
		a["node"].position += a["dir"] * SPEED * delta
	for a in asteroids.filter(_is_outside):
		a["node"].queue_free()
	asteroids.assign(asteroids.filter(func(a: Dictionary) -> bool: return not _is_outside(a)))
	queue_redraw()

func _is_outside(a: Dictionary) -> bool:
	var p: Vector2 = a["node"].position
	return p.x < -MARGIN or p.x > viewport_size.x + MARGIN or p.y < -MARGIN or p.y > viewport_size.y + MARGIN

func _spawn() -> void:
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
		var tmp: Vector2 = start
		start = end
		end = tmp
	var dir: Vector2 = (end - start).normalized()

	var body: SpaceBody = BODY.instantiate()
	body.fps = rng.randf_range(8.0, 14.0)
	body.sheet = SHEETS[rng.randi() % SHEETS.size()]
	body.scale = Vector2(SCALE, SCALE)
	body.position = start + dir  # un paso dentro para no borrarlo en el primer frame
	add_child(body)
	asteroids.append({"node": body, "dir": dir})

func _draw() -> void:
	# El padre se dibuja antes que sus hijos, así la estela queda detrás del asteroide
	for a in asteroids:
		var head: Vector2 = a["node"].position
		var tail: Vector2 = head - a["dir"] * TAIL_LENGTH
		draw_polyline_colors(PackedVector2Array([tail, head]), PackedColorArray([Color(TAIL_COLOR, 0.0), Color(TAIL_COLOR, 0.5)]), TAIL_WIDTH)
