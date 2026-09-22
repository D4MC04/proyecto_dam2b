extends AnimatedSprite2D

var last_position: Vector2

func _ready():
	last_position = global_position
	play("walk_down")

func _process(_delta):
	var movement = global_position - last_position
	last_position = global_position

	if movement.length() < 0.5:
		return

	if abs(movement.x) > abs(movement.y):
		play("walk_east" if movement.x > 0 else "walk_west")
	else:
		play("walk_down" if movement.y > 0 else "walk_up")
