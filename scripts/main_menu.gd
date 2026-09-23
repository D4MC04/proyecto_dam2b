extends Control

@export var fondo: Texture2D = preload("res://assets/sprites/backgrounds/fondo_1.png")

func _ready():
	$Background.texture = fondo

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
