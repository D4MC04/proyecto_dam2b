extends Sprite2D
## Cometa decorativo del fondo: cruza el área de juego de vez en cuando.

@export var speed := Vector2(150, 22)
@export var wait_min := 6.0
@export var wait_max := 15.0
# Ancho del área que cruza y altura máxima a la que puede aparecer.
@export var width := 704.0
@export var height := 270.0

var _flying := false


func _ready() -> void:
	hide()
	rotation = speed.angle()
	_wait()


func _wait() -> void:
	await get_tree().create_timer(randf_range(wait_min, wait_max), false).timeout
	position = Vector2(-30, randf_range(0, height))
	show()
	_flying = true


func _process(delta: float) -> void:
	if not _flying:
		return
	position += speed * delta
	if position.x > width:
		_flying = false
		hide()
		_wait()
