extends PathFollow2D

@export var speed = 100.0

func _process(delta):
	progress += speed * delta
	print("PathFollow global: ", global_position)
