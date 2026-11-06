extends Control

# Menú principal: la oficina del comandante. Tres vistas (izquierda, centro y derecha) que se
# cambian girando la silla con las flechas de los bordes o las teclas; cada objeto de la oficina
# abre su panel holograma encima, con la oficina oscurecida detrás. Escape cierra el panel abierto
# o, en la oficina, pregunta si salir del juego.

enum View { LEFT, CENTER, RIGHT }

const FADE_TIME := 0.25
const WARP_TIME := 0.5
const FLASH_TIME := 0.1
# Giro de la silla: duración del paso a la vista de al lado y ancho de cada vista.
const TURN_TIME := 0.45
const VIEW_WIDTH := 960.0

var start_on_level_selection: bool = false

@onready var views: Control = $Office/Views
@onready var space: Node2D = $Space
@onready var turn_left_arrow: TurnArrow = $Office/TurnLeftArrow
@onready var turn_right_arrow: TurnArrow = $Office/TurnRightArrow
@onready var exit_door: OfficeDoor = $Office/Views/LeftView/ExitDoor
@onready var panel_dim: ColorRect = $PanelDim
@onready var level_selection_panel: VBoxContainer = $LevelSelectionScreen
@onready var level_buttons_container: GridContainer = %LevelButtonsContainer
@onready var stats_panel: VBoxContainer = $StatsScreen
@onready var stats_label: Label = %StatsLabel
@onready var navedex: Navedex = $Navedex
@onready var achievements_screen: AchievementsScreen = $AchievementsScreen
@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var quit_confirm: Control = $QuitConfirm

var _view := View.CENTER
var _turn_tween: Tween
# Panel abierto encima de la oficina; null si se ve la oficina.
var _panel: Control
var _panel_tween: Tween
var _jumping: bool = false
var _leaving: bool = false

func _ready() -> void:
	_set_pan(0.0)
	_update_arrows()
	var quit_button: Button = %QuitButton
	quit_button.add_theme_stylebox_override(&"hover_pressed", quit_button.get_theme_stylebox(&"hover"))
	quit_button.add_theme_color_override(&"font_hover_pressed_color", quit_button.get_theme_color(&"font_hover_color"))
	if start_on_level_selection:
		_panel = level_selection_panel
		panel_dim.show()
		level_selection_panel.show()
	_build_level_buttons()
	GameState.progress_reset.connect(_build_level_buttons)

func _unhandled_input(event: InputEvent) -> void:
	if _jumping or _leaving:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if quit_confirm.visible:
			_close_quit_confirm()
		elif _panel:
			_close_panel()
		else:
			quit_confirm.show()
		return
	if _panel or quit_confirm.visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode in [KEY_LEFT, KEY_A]:
		get_viewport().set_input_as_handled()
		_turn(-1)
	elif key.physical_keycode in [KEY_RIGHT, KEY_D]:
		get_viewport().set_input_as_handled()
		_turn(1)

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

# --- Giro de la silla ----------------------------------------------------------------------

# Gira a la vista de al lado (-1 izquierda, 1 derecha), si la hay.
func _turn(step: int) -> void:
	var target := clampi(_view + step, View.LEFT, View.RIGHT) as View
	if target == _view:
		return
	_view = target
	_update_arrows()
	if _turn_tween:
		_turn_tween.kill()
	_turn_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn_tween.tween_method(_set_pan, views.position.x, (View.CENTER - _view) * VIEW_WIDTH, TURN_TIME)

# Desplaza las vistas y el espacio de detrás del ventanal, en píxeles enteros.
func _set_pan(offset: float) -> void:
	views.position.x = roundf(offset)
	space.position.x = roundf(offset)

func _update_arrows() -> void:
	turn_left_arrow.visible = _view != View.LEFT
	turn_right_arrow.visible = _view != View.RIGHT

# --- Paneles -------------------------------------------------------------------------------

# Abre un panel encima de la oficina, con la oficina oscurecida detrás.
func _open_panel(panel: Control) -> void:
	if _panel or _jumping or _leaving:
		return
	_panel = panel
	_fade_panel(panel, true)

func _close_panel() -> void:
	if _panel == null:
		return
	var panel := _panel
	_panel = null
	_fade_panel(panel, false)

func _fade_panel(panel: Control, show_it: bool) -> void:
	if _panel_tween:
		_panel_tween.kill()
	var target := 1.0 if show_it else 0.0
	if show_it:
		for item: Control in [panel_dim, panel]:
			item.modulate.a = 0.0
			item.show()
	_panel_tween = create_tween().set_parallel()
	_panel_tween.tween_property(panel_dim, "modulate:a", target, FADE_TIME)
	_panel_tween.tween_property(panel, "modulate:a", target, FADE_TIME)
	if not show_it:
		_panel_tween.chain().tween_callback(func() -> void:
			panel_dim.hide()
			panel.hide())

func _on_radar_console_pressed() -> void:
	_open_panel(level_selection_panel)

func _on_archive_tablet_pressed() -> void:
	_open_panel(navedex)

func _on_medal_case_pressed() -> void:
	_open_panel(achievements_screen)

func _on_options_console_pressed() -> void:
	_open_panel(options_menu)

@warning_ignore("integer_division")
func _on_combat_scoreboard_pressed() -> void:
	var seconds := int(GameState.play_time)
	var favorite: String = GameState.favorite_turret()
	var turret_name := "-"
	if favorite != "":
		turret_name = (load(Navedex.TURRET_DIR + favorite + ".tres") as TurretData).name
	stats_label.text = "\n".join([
		"Naves destruidas: %d" % GameState.stats.get("kills", 0),
		"Dinero gastado: %s" % UiFormat.money(GameState.stats.get("spent", 0)),
		"Tiempo jugado: %dh %02dm" % [seconds / 3600, seconds % 3600 / 60],
		"Torreta favorita: %s" % turret_name,
		"Niveles ganados: %d" % GameState.stats.get("wins", 0),
	])
	_open_panel(stats_panel)

# --- Salir ---------------------------------------------------------------------------------

func _close_quit_confirm() -> void:
	quit_confirm.hide()

# La puerta se entreabre y después se cierra el juego.
func _on_exit_door_pressed() -> void:
	if _leaving or _panel:
		return
	_leaving = true
	exit_door.open_fully()
	await exit_door.opened
	_quit()

func _quit() -> void:
	get_tree().quit()

# --- Salto al hiperespacio -----------------------------------------------------------------

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
	await $Space/StarField.warp(WARP_TIME)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 1.0, FLASH_TIME)
	await tween.finished
