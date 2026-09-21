extends Node2D

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	var cercano = null
	var mejor = INF
	for a in $Range.get_overlapping_areas():
		var d = global_position.distance_to(a.global_position)
		if d < mejor:
			mejor = d
			cercano = a
	if cercano:
		cercano.hit()
