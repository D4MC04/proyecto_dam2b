extends Node2D

# Satélite decorativo que cruza el nivel de borde a borde, como los asteroides del menú
# pero más lento y menos frecuente. Sin colisión: ni se le dispara ni estorba.

const FRAMES = preload("res://resources/sprite_frames/satelite.tres")
const MAX_ACTIVE = 1
const SPEED = 25.0
const MARGIN = 40.0         # aparece/desaparece fuera de pantalla (el sprite mide 66 px)

var viewport_size: Vector2
var rng = RandomNumberGenerator.new()
var satellites = []  # cada uno: {"node": AnimatedSprite2D, "dir": Vector2}
var wait = 0.0
var layer: Node2D

func _ready():
	viewport_size = get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(10.0, 20.0)
	# Capa dentro del mapa, justo antes de los caminos: por encima del suelo y por detrás
	# de enemigos, base y torres.
	var paths = get_node("../Map/Paths")
	layer = Node2D.new()
	layer.name = "Satellites"
	paths.get_parent().add_child(layer)
	paths.get_parent().move_child(layer, paths.get_index())

func _process(delta):
	wait -= delta
	if wait <= 0.0:
		wait = rng.randf_range(25.0, 50.0)
		if satellites.size() < MAX_ACTIVE:
			_spawn()
	for s in satellites:
		s["node"].position += s["dir"] * SPEED * delta
	for s in satellites.filter(_is_outside):
		s["node"].queue_free()
	satellites = satellites.filter(func(s): return not _is_outside(s))

func _is_outside(s) -> bool:
	var p = s["node"].position
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

	var body = AnimatedSprite2D.new()
	body.sprite_frames = FRAMES
	body.position = start + dir  # un paso dentro para no borrarlo en el primer frame
	layer.add_child(body)
	body.play()
	satellites.append({"node": body, "dir": dir})
