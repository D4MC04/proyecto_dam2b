extends Area2D

@export var hp = 3

func get_hit(damage):
	hp -= damage
	if hp <= 0:
		var n = get_parent()
		while n and not n is PathFollow2D:
			n = n.get_parent()
		(n if n else get_parent()).queue_free()
