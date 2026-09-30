extends Node2D

@onready var spawner: Node = $Spawner
@onready var game_over_screen: CanvasLayer = $UI/GameOverScreen

var finished := false

func _ready():
	spawner.enemy_reached_end.connect(_lose)

func _lose():
	if finished:
		return
	finished = true
	game_over_screen.mostrar()
