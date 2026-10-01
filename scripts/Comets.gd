extends Node2D

const SPEED = 220.0
const TAIL_LENGTH = 28.0
const COLOR = preload("res://scripts/Asteroids.gd").TAIL_COLOR  # misma estela que los asteroides
const DROP = 50.0  # caída vertical total del recorrido: diagonal suave

var viewport_size: Vector2
var comets = []  # cada uno: {"pos": Vector2, "dir": Vector2}
var wait = 0.0

func _ready():
	viewport_size = get_viewport_rect().size
	wait = randf_range(1.5, 4.0)

func _process(delta):
	# El temporizador corre aunque haya cometas cruzando, así pueden coincidir varios
	wait -= delta
	if wait <= 0.0:
		_spawn()
		wait = randf_range(1.5, 4.0)
	for comet in comets:
		comet["pos"] += comet["dir"] * SPEED * delta
	comets = comets.filter(func(c): return c["pos"].x >= -TAIL_LENGTH and c["pos"].x <= viewport_size.x + TAIL_LENGTH)
	queue_redraw()

func _spawn():
	# Solo franja superior o inferior, para no cruzar por encima de Jugar/Salir
	var y = randf_range(0.0, viewport_size.y * 0.2)
	if randf() < 0.5:
		y = randf_range(viewport_size.y * 0.65, viewport_size.y - DROP)
	var from_left = randf() < 0.5
	var start = Vector2(-TAIL_LENGTH if from_left else viewport_size.x + TAIL_LENGTH, y)
	var end = Vector2(viewport_size.x + TAIL_LENGTH if from_left else -TAIL_LENGTH, y + DROP)
	comets.append({"pos": start, "dir": (end - start).normalized()})

func _draw():
	for comet in comets:
		var pos = comet["pos"]
		var tail = pos - comet["dir"] * TAIL_LENGTH
		draw_polyline_colors(PackedVector2Array([tail, pos]), PackedColorArray([Color(COLOR, 0.0), Color(COLOR, 0.8)]), 1.0)
		draw_rect(Rect2(pos.round() - Vector2.ONE, Vector2(2, 2)), Color.WHITE)
