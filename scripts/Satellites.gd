extends Node2D

# Satélite decorativo que cruza el menú de borde a borde, como los asteroides pero más lento
# y de uno en uno: el siguiente no se programa hasta que el anterior ha salido y se ha borrado.

const FRAMES = preload("res://resources/sprite_frames/satelite.tres")
const SCALE = 0.5           # frame de 66x34 -> ~33x17 en pantalla
const MARGIN = 20.0         # aparece/desaparece fuera de pantalla

var viewport_size: Vector2
var rng = RandomNumberGenerator.new()
var satellite: AnimatedSprite2D  # null mientras no hay ninguno cruzando
var dir: Vector2
var speed = 0.0
var wait = 0.0

func _ready():
	viewport_size = get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(3.0, 6.0)

func _process(delta):
	if satellite == null:
		wait -= delta
		if wait <= 0.0:
			_spawn()
		return
	satellite.position += dir * speed * delta
	if _is_outside():
		satellite.queue_free()
		satellite = null
		wait = rng.randf_range(8.0, 15.0)

func _is_outside() -> bool:
	var p = satellite.position
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
	dir = (end - start).normalized()
	speed = rng.randf_range(20.0, 30.0)

	satellite = AnimatedSprite2D.new()
	satellite.sprite_frames = FRAMES
	satellite.scale = Vector2(SCALE, SCALE)
	satellite.position = start + dir  # un paso dentro para no borrarlo en el primer frame
	add_child(satellite)
	satellite.play()
