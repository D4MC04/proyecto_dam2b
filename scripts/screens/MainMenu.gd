extends Control

var start_on_level_selection: bool = false

@onready var main_panel: VBoxContainer = $TitleScreen
@onready var level_selection_panel: VBoxContainer = $LevelSelectionScreen
@onready var level_buttons_container: GridContainer = %LevelButtonsContainer
@onready var stats_panel: VBoxContainer = $StatsScreen
@onready var stats_label: Label = %StatsLabel
@onready var navedex: Navedex = $Navedex
@onready var options_menu: OptionsMenu = $OptionsMenu

const FADE_TIME := 0.25
const WARP_TIME := 0.5
const FLASH_TIME := 0.1

var _jumping: bool = false

func _ready() -> void:
	if start_on_level_selection:
		main_panel.hide()
		level_selection_panel.show()
	_build_level_buttons()
	GameState.progress_reset.connect(_build_level_buttons)

func _build_level_buttons() -> void:
	for child in level_buttons_container.get_children():
		child.queue_free()
	for i in GameData.levels.size():
		var button := LevelButton.new()
		button.level = GameData.levels[i]
		button.text = str(i + 1)
		button.custom_minimum_size = Vector2(60, 60)
		button.add_theme_font_size_override("font_size", 24)
		button.disabled = not GameState.is_unlocked(i)
		button.level_selected.connect(_open_level)
		level_buttons_container.add_child(button)

func _open_level(data: LevelData) -> void:
	if _jumping:
		return
	_jumping = true
	await _hyperspace_jump()
	var game = preload("res://scenes/Game.tscn").instantiate()
	game.level_data = data
	game.from_hyperspace = true
	var tree = get_tree()
	tree.root.add_child(game)
	tree.current_scene.queue_free()
	tree.current_scene = game

# Estrellas en líneas y destello blanco que cubre el menú antes de cargar el nivel.
func _hyperspace_jump() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(flash)
	await $StarField.warp(WARP_TIME)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 1.0, FLASH_TIME)
	await tween.finished

func _on_settings_button_pressed() -> void:
	options_menu.open_from(main_panel)

func _on_play_button_pressed() -> void:
	_transition(main_panel, level_selection_panel)

func _on_volver_pressed() -> void:
	_transition(level_selection_panel, main_panel)

func _on_navedex_button_pressed() -> void:
	_transition(main_panel, navedex)

func _on_navedex_back_pressed() -> void:
	_transition(navedex, main_panel)

@warning_ignore("integer_division")
func _on_stats_button_pressed() -> void:
	var seconds := int(GameState.play_time)
	var favorite: String = GameState.favorite_tower()
	var tower_name := "-"
	if favorite != "":
		tower_name = (load(Navedex.TOWER_DIR + favorite + ".tres") as TowerData).name
	stats_label.text = "
".join([
		"Naves destruidas: %d" % GameState.stats.get("kills", 0),
		"Dinero gastado: %s" % UiFormat.money(GameState.stats.get("spent", 0)),
		"Tiempo jugado: %dh %02dm" % [seconds / 3600, seconds % 3600 / 60],
		"Torre favorita: %s" % tower_name,
		"Niveles ganados: %d" % GameState.stats.get("wins", 0),
	])
	_transition(main_panel, stats_panel)

func _on_stats_back_pressed() -> void:
	_transition(stats_panel, main_panel)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _transition(from: Control, to: Control) -> void:
	var tween := create_tween()
	tween.tween_property(from, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func():
		from.hide()
		to.modulate.a = 0.0
		to.show())
	tween.tween_property(to, "modulate:a", 1.0, FADE_TIME)
