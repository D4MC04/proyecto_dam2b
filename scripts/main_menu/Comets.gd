extends Node2D

const SPEED: float = 220.0
const TAIL_LENGTH: float = 28.0
const COLOR: Color = Color(0.75, 0.95, 1.0)
const DROP: float = 50.0  # caída vertical total del recorrido: diagonal suave

@export var area_size: Vector2 = Vector2.ZERO  # zona por la que cruzan; cero = todo el viewport
@export var wait_min: float = 1.5  # segundos mínimos entre cometas
@export var wait_max: float = 4.0  # segundos máximos entre cometas

var viewport_size: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var comets: Array[Dictionary] = []  # cada uno: {"pos": Vector2, "dir": Vector2}
var wait: float = 0.0

func _ready() -> void:
	viewport_size = area_size if area_size != Vector2.ZERO else get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(wait_min, wait_max)

func _process(delta: float) -> void:
	# El temporizador corre aunque haya cometas cruzando, así pueden coincidir varios
	wait -= delta
	if wait <= 0.0:
		_spawn()
		wait = rng.randf_range(wait_min, wait_max)
	for comet in comets:
		comet["pos"] += comet["dir"] * SPEED * delta
	comets.assign(comets.filter(func(c: Dictionary) -> bool: return c["pos"].x >= -TAIL_LENGTH and c["pos"].x <= viewport_size.x + TAIL_LENGTH))
	queue_redraw()

func _spawn() -> void:
	# Solo franja superior o inferior, para no cruzar por encima de Jugar/Salir
	var y: float = rng.randf_range(0.0, viewport_size.y * 0.2)
	if rng.randf() < 0.5:
		y = rng.randf_range(viewport_size.y * 0.65, viewport_size.y - DROP)
	var from_left: bool = rng.randf() < 0.5
	var start: Vector2 = Vector2(-TAIL_LENGTH if from_left else viewport_size.x + TAIL_LENGTH, y)
	var end: Vector2 = Vector2(viewport_size.x + TAIL_LENGTH if from_left else -TAIL_LENGTH, y + DROP)
	comets.append({"pos": start, "dir": (end - start).normalized()})

func _draw() -> void:
	for comet in comets:
		var pos: Vector2 = comet["pos"]
		var tail: Vector2 = pos - comet["dir"] * TAIL_LENGTH
		draw_polyline_colors(PackedVector2Array([tail, pos]), PackedColorArray([Color(COLOR, 0.0), Color(COLOR, 0.8)]), 1.0)
		draw_rect(Rect2(pos.round() - Vector2.ONE, Vector2(2, 2)), Color.WHITE)
