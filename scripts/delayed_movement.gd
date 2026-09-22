extends "res://scripts/movement.gd"

@export var delay = 1.5

func _ready():
	visible = false

func _process(delta):
	if delay > 0.0:
		delay -= delta
		if delay <= 0.0:
			visible = true
		return
	super(delta)
