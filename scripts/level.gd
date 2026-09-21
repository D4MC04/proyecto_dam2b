extends Node2D

@export var vida = 10

func _ready():
	$UI/VidaLabel.text = "Vida: %d" % vida

func _process(_delta):
	for f in $Path2D.get_children():
		if f is PathFollow2D and f.progress_ratio >= 1.0:
			f.queue_free()
			vida = max(vida - 1, 0)
			$UI/VidaLabel.text = "Vida: %d" % vida
			if vida == 0:
				$GameOver.mostrar()
