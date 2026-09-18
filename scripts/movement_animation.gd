extends AnimatedSprite2D

var last_position: Vector2
var directions = [
	"walk_side",
	"walk_down_side",
	"walk_down",
	"walk_down_side",
	"walk_side",
	"walk_up_side",
	"walk_up",
	"walk_up_side"
]

func _ready():

	last_position = global_position

func _process(_delta):

	var movement = global_position - last_position
	last_position = global_position

	if movement.length() < 0.5:
		return

	flip_h = movement.x < 0
	var angle = movement.angle()
	var index = wrapi(round(angle / (PI / 4)), 0, 8)

	play(directions[index])
