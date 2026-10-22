extends Node2D
class_name Debris
# Restos de una nave al morir: destello blanco, anillo de humo y trozos que salen volando.
# Se libera solo y sigue el time_scale del juego.

const DURATION := 0.5
const MIN_PIECES := 5
const MAX_PIECES := 8
const SPEED_MIN := 50.0
const SPEED_MAX := 130.0
# Cuánto frena por segundo (0 = no frena, 1 = se para del todo).
const DRAG := 0.9
const SMOKE_COLOR := Color("#9aa0b4")
const FLASH_SIZE := 16.0
const SMOKE_RADIUS := 12.0

var _pieces: Array[Dictionary] = []
var _time := 0.0
var _scale := 1.0

## Crea los restos en `pos` con trozos de los colores dados. `size_scale` agranda todo en las naves grandes.
static func spawn(parent: Node, pos: Vector2, colors: Array[Color], size_scale: float = 1.0) -> void:
	var debris := Debris.new()
	debris._scale = maxf(size_scale, 1.0)
	debris.z_index = 9
	parent.add_child(debris)
	debris.global_position = pos
	debris._make_pieces(colors)

func _make_pieces(colors: Array[Color]) -> void:
	if colors.is_empty():
		colors = [Color.WHITE]
	var count := int(round(randi_range(MIN_PIECES, MAX_PIECES) * _scale))
	for i in count:
		_pieces.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(SPEED_MIN, SPEED_MAX) * sqrt(_scale),
			"angle": randf() * TAU,
			"spin": randf_range(-12.0, 12.0),
			"size": float(randi_range(2, 3)) * (1.0 if _scale < 1.5 else 1.5),
			"color": colors.pick_random(),
		})

func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	var drag := pow(1.0 - DRAG, delta)
	for piece in _pieces:
		piece["pos"] += piece["vel"] * delta
		piece["vel"] *= drag
		piece["angle"] += piece["spin"] * delta
	queue_redraw()

func _draw() -> void:
	var t := _time / DURATION
	# Destello blanco: solo el primer frame.
	if _time <= 0.0:
		var half := FLASH_SIZE * _scale / 2.0
		draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), Color.WHITE)
	# Anillo de humo: crece y se desvanece.
	var smoke := SMOKE_COLOR
	smoke.a = 1.0 - t
	draw_arc(Vector2.ZERO, SMOKE_RADIUS * _scale * (0.3 + 0.7 * t), 0.0, TAU, 24, smoke, 2.0, false)
	# Trozos: opacos la primera mitad y se desvanecen en la segunda.
	var alpha := 1.0 if t < 0.5 else (1.0 - t) * 2.0
	for piece in _pieces:
		var color: Color = piece["color"]
		color.a = alpha
		var s: float = piece["size"]
		draw_set_transform(piece["pos"], piece["angle"])
		draw_rect(Rect2(-s / 2.0, -s / 2.0, s, s), color)
