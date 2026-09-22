extends PathFollow2D

@export var speed = 0.0

func _ready():
	assert(speed > 0, name + ": enemy speed is not configured")

func _process(delta):
	progress += speed * delta
