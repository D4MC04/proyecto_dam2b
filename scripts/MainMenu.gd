extends Control

@onready var main_panel: Control = $TitleScreen
@onready var levels_panel: Control = $Levels
@onready var volume_slider: Slider = $VolumePanel/Volume/Slider
@onready var mute_button: Button = $VolumePanel/Volume/MuteButton

const FADE_TIME := 0.25

func _ready():
	volume_slider.set_value_no_signal(MusicManager.volumen)
	_update_mute_button()

func _on_mute_button_pressed():
	MusicManager.toggle_mute()
	_update_mute_button()

func _on_slider_value_changed(value: float):
	MusicManager.set_volume(value)

func _on_play_button_pressed():
	_transition(main_panel, levels_panel)

func _on_volver_pressed():
	_transition(levels_panel, main_panel)

func _on_nivel_pressed(n: int):
	Map.selected ="res://scenes/maps/Map%d.tscn" % n
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _update_mute_button():
	mute_button.text = "OFF" if MusicManager.muteado else "ON"

func _transition(from: Control, to: Control):
	var tween := create_tween()
	tween.tween_property(from, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func():
		from.hide()
		to.modulate.a = 0.0
		to.show())
	tween.tween_property(to, "modulate:a", 1.0, FADE_TIME)
