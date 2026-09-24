extends Control

@export var fondo: Texture2D = preload("res://assets/sprites/backgrounds/fondo_1.png")

func _ready():
	$Background.texture = fondo

func _on_play_button_pressed():
	_fundido($Caja, $Niveles)

func _on_volver_pressed():
	_fundido($Niveles, $Caja)

func _on_nivel_1_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _fundido(de: Control, a: Control):
	var t = create_tween()
	t.tween_property(de, "modulate:a", 0.0, 0.25)
	t.tween_callback(func():
		de.hide()
		a.modulate.a = 0.0
		a.show())
	t.tween_property(a, "modulate:a", 1.0, 0.25)
