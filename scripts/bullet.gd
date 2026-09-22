extends Node2D

const VELOCIDAD = 300.0

var objetivo

func _process(delta):
	if not is_instance_valid(objetivo):
		queue_free()
		return
	var destino = objetivo.global_position
	if global_position.distance_to(destino) <= 4.0:
		objetivo.hit()
		queue_free()
		return
	global_position = global_position.move_toward(destino, VELOCIDAD * delta)

func _draw():
	draw_circle(Vector2.ZERO, 3.0, Color.BLACK)
	draw_circle(Vector2.ZERO, 2.0, Color.CYAN)
