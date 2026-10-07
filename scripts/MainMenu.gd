extends Control

@onready var main_panel: VBoxContainer = $TitleScreen
@onready var level_selection_panel: VBoxContainer = $LevelSelectionScreen
@onready var level_buttons_container: GridContainer = %LevelButtonsContainer
@onready var volume_slider: Slider = $VolumePanel/Volume/Slider
@onready var mute_button: Button = $VolumePanel/Volume/MuteButton

const FADE_TIME := 0.25

func _ready():
	_build_level_buttons()
	volume_slider.set_value_no_signal(MusicManager.volumen)
	_update_mute_button()

func _build_level_buttons():
	for i in GameData.levels.size():
		var button := LevelButton.new()
		button.level = GameData.levels[i]
		button.text = str(i + 1)
		button.custom_minimum_size = Vector2(40, 40)
		button.disabled = not GameState.is_unlocked(i)
		button.level_selected.connect(_open_level)
		level_buttons_container.add_child(button)

func _open_level(data: LevelData):
	var game = preload("res://scenes/Game.tscn").instantiate()
	game.level_data = data
	var tree = get_tree()
	tree.root.add_child(game)
	tree.current_scene.queue_free()
	tree.current_scene = game

func _on_mute_button_pressed():
	MusicManager.toggle_mute()
	_update_mute_button()

func _on_slider_value_changed(value: float):
	MusicManager.set_volume(value)

func _on_play_button_pressed():
	_transition(main_panel, level_selection_panel)

func _on_volver_pressed():
	_transition(level_selection_panel, main_panel)

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
