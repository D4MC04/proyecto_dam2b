class_name HealEffect
extends Node2D

# Chispas de curación en pixel art (rectángulos de 1 px, sin antialiasing) que suben de la nave que
# cura la Mender. Su rampa verde la usan también el rayo (HealBeam) y el sprite de la Mender.

const DARK: Color = Color("#1c7440")
const MID: Color = Color("#3cb860")
const LIGHT: Color = Color("#7ee89a")
const BRIGHT: Color = Color("#c4f5d0")
const SPARK_TIME: float = 0.4
const SPARK_COUNT: int = 6
const SPARK_RISE: float = 10.0

# Punto de salida de cada chispa y cuánto sube.
var _sparks: Array[Vector3] = []
var _progress: float = 0.0

## Chispas de 1 px que suben desde una nave de `size` px y se desvanecen. Cuelga de la nave para seguirla.
static func spawn_sparks(target: Node2D, size: float) -> void:
	if not Effect.has_room(target.get_tree()):
		return
	var effect: HealEffect = HealEffect.new()
	effect.add_to_group(Effect.GROUP)
	effect.z_index = 5
	for i: int in SPARK_COUNT:
		var start: Vector2 = Vector2(randf_range(-0.35, 0.35), randf_range(-0.2, 0.3)) * size
		effect._sparks.append(Vector3(start.x, start.y, SPARK_RISE * randf_range(0.6, 1.2)))
	target.add_child(effect)
	effect._play(SPARK_TIME)

func _play(duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	tween.tween_callback(queue_free)

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

# Cada chispa: cabeza clara y estela de 1 px más oscura debajo. Opacas la primera mitad y se
# desvanecen en la segunda.
func _draw() -> void:
	var alpha: float = clampf(2.0 - 2.0 * _progress, 0.0, 1.0)
	var head: Color = BRIGHT if _progress < 0.5 else LIGHT
	for spark: Vector3 in _sparks:
		var pixel: Vector2 = Vector2(roundf(spark.x), roundf(spark.y - spark.z * _progress))
		draw_rect(Rect2(pixel, Vector2.ONE), Color(head, alpha))
		draw_rect(Rect2(pixel + Vector2.DOWN, Vector2.ONE), Color(MID, alpha))
