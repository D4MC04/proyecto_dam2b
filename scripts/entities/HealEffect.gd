class_name HealEffect
extends Node2D

# Efectos de curación de la Reparadora, en pixel art (rectángulos de 1 px, sin antialiasing):
# el anillo que se expande desde ella y las chispas que suben de cada nave curada.

const DARK := Color("#1c7440")
const MID := Color("#3cb860")
const LIGHT := Color("#7ee89a")
const BRIGHT := Color("#c4f5d0")
const RING_TIME := 0.5
const SPARK_TIME := 0.4
const SPARK_COUNT := 6
const SPARK_RISE := 10.0

# Radio final del anillo; 0 si son chispas.
var _radius := 0.0
# Punto de salida de cada chispa y cuánto sube.
var _sparks: Array[Vector3] = []
var _progress := 0.0

## Anillo verde que se expande hasta `radius` y se desvanece. Cuelga de `parent` y se libera solo.
static func spawn_ring(parent: Node, position: Vector2, radius: float) -> void:
	var effect := HealEffect.new()
	effect._radius = radius
	parent.add_child(effect)
	# En global porque el padre (el camino) se mueve con el mapa centrado.
	effect.global_position = position
	effect._play(RING_TIME)

## Chispas de 1 px que suben desde una nave de `size` px y se desvanecen. Cuelga de la nave para seguirla.
static func spawn_sparks(target: Node2D, size: float) -> void:
	var effect := HealEffect.new()
	effect.z_index = 5
	for i: int in SPARK_COUNT:
		var start := Vector2(randf_range(-0.35, 0.35), randf_range(-0.2, 0.3)) * size
		effect._sparks.append(Vector3(start.x, start.y, SPARK_RISE * randf_range(0.6, 1.2)))
	target.add_child(effect)
	effect._play(SPARK_TIME)

func _play(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	tween.tween_callback(queue_free)

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _draw() -> void:
	# Opaco en la primera mitad y se desvanece en la segunda.
	var alpha := clampf(2.0 - 2.0 * _progress, 0.0, 1.0)
	if _radius > 0.0:
		_draw_ring(roundf(_radius * (0.25 + 0.75 * _progress)), alpha)
	else:
		_draw_sparks(alpha)

# Anillo de 1 px claro con otro de 1 px más oscuro por dentro.
func _draw_ring(radius: float, alpha: float) -> void:
	_draw_circle_pixels(radius, Color(LIGHT, alpha))
	if radius > 2.0:
		_draw_circle_pixels(radius - 1.0, Color(DARK, alpha))

func _draw_circle_pixels(radius: float, color: Color) -> void:
	var pixels: Dictionary[Vector2i, bool] = {}
	var steps := maxi(8, int(radius * 8.0))
	for i: int in steps:
		var angle := TAU * i / steps
		pixels[Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius))] = true
	for pixel: Vector2i in pixels:
		draw_rect(Rect2(pixel, Vector2.ONE), color)

# Cada chispa: cabeza clara y estela de 1 px más oscura debajo.
func _draw_sparks(alpha: float) -> void:
	var head := BRIGHT if _progress < 0.5 else LIGHT
	for spark: Vector3 in _sparks:
		var pixel := Vector2(roundf(spark.x), roundf(spark.y - spark.z * _progress))
		draw_rect(Rect2(pixel, Vector2.ONE), Color(head, alpha))
		draw_rect(Rect2(pixel + Vector2.DOWN, Vector2.ONE), Color(MID, alpha))
