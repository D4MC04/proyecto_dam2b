extends CanvasLayer

func mostrar():
	visible = true
	get_tree().paused = true

func _unhandled_input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()
