extends Node2D

# Satélite decorativo que cruza el menú de borde a borde, como los asteroides pero más lento
# y de uno en uno: el siguiente no se programa hasta que el anterior ha salido y se ha borrado.

const FRAMES: SpriteFrames = preload("res://resources/sprite_frames/satelite.tres")
const SCALE: float = 0.5           # frame de 66x34 -> ~33x17 en pantalla
const MARGIN: float = 20.0         # aparece/desaparece fuera de pantalla

@export var area_size: Vector2 = Vector2.ZERO  # zona por la que cruza; cero = todo el viewport
@export var gap_min: float = 8.0   # segundos mínimos entre que sale uno y entra el siguiente
@export var gap_max: float = 15.0  # segundos máximos entre que sale uno y entra el siguiente

var viewport_size: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var satellite: AnimatedSprite2D  # null mientras no hay ninguno cruzando
var dir: Vector2
var speed: float = 0.0
var spin: float = 0.0  # giro sobre sí mismo, en rad/s
var wait: float = 0.0

func _ready() -> void:
	viewport_size = area_size if area_size != Vector2.ZERO else get_viewport_rect().size
	rng.randomize()
	wait = rng.randf_range(3.0, 6.0)

func _process(delta: float) -> void:
	if satellite == null:
		wait -= delta
		if wait <= 0.0:
			_spawn()
		return
	satellite.position += dir * speed * delta
	satellite.rotation += spin * delta
	if _is_outside():
		satellite.queue_free()
		satellite = null
		wait = rng.randf_range(gap_min, gap_max)

func _is_outside() -> bool:
	var p: Vector2 = satellite.position
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
	dir = (end - start).normalized()
	speed = rng.randf_range(20.0, 30.0)
	# Giro muy lento, horario o antihorario
	spin = deg_to_rad(rng.randf_range(4.0, 8.0)) * (1 if rng.randf() < 0.5 else -1)

	satellite = AnimatedSprite2D.new()
	satellite.sprite_frames = FRAMES
	satellite.scale = Vector2(SCALE, SCALE)
	satellite.position = start + dir  # un paso dentro para no borrarlo en el primer frame
	add_child(satellite)
	satellite.play()
