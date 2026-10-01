extends Node2D

@onready var spawner: Node = $Spawner
@onready var game_over_screen: CanvasLayer = $UI/GameOverScreen

func _ready():
	spawner.enemy_reached_end.connect(game_over_screen.mostrar)
