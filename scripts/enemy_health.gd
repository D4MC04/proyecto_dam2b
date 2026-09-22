extends Area2D

@export var vida = 3

func hit():
	vida -= 1
	if vida <= 0:
		var n = get_parent()
		while n and not n is PathFollow2D:
			n = n.get_parent()
		(n if n else get_parent()).queue_free()
