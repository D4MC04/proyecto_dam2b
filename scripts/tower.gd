extends Node2D

const BALA = preload("res://scripts/bullet.gd")

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func _process(_delta):
	var objetivo = _mas_cercano()
	if objetivo:
		# el sprite mira arriba a la derecha (-45 grados) por defecto
		$Sprite2D.rotation = (objetivo.global_position - global_position).angle() + PI / 4

func _on_timer_timeout():
	var objetivo = _mas_cercano()
	if objetivo:
		var bala = BALA.new()
		bala.objetivo = objetivo
		get_parent().add_child(bala)
		bala.global_position = global_position

func _mas_cercano():
	var cercano = null
	var mejor = INF
	for a in $Range.get_overlapping_areas():
		var d = global_position.distance_to(a.global_position)
		if d < mejor:
			mejor = d
			cercano = a
	return cercano

func ajustar_a_casilla(tamano: Vector2):
	$Sprite2D.scale = tamano / $Sprite2D.texture.get_size()
