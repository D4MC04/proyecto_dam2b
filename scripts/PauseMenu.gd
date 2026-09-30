extends CanvasLayer

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not $"../GameOverScreen".visible:
		_pausar(not visible)

func _pausar(activar: bool):
	visible = activar
	get_tree().paused = activar

func _on_continuar_pressed():
	_pausar(false)

func _on_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_salir_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
