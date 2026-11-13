extends Node
class_name Game

const ENTER_FADE_TIME: float = 0.2
const MAIN_MENU_PATH: String = "res://scenes/MainMenu.tscn"

@export var level_data: LevelData
var from_hyperspace: bool = false

@onready var level: Level = $Level
@onready var ui: LevelUI = $LevelUI

var _level_scene: PackedScene
var _transitioning: bool = false
# El nivel es el nivel de emergencia (el nivel de prueba del tutorial), no un sector.
var _is_emergency: bool = false

func _ready() -> void:
	_level_scene = load(level.scene_file_path)
	ui.action_requested.connect(_on_action_requested)
	_setup_level()
	if from_hyperspace:
		_fade_in_from_white()

# Al perder el foco de la ventana (Alt+Tab) se abre la pausa, salvo que la opción esté desactivada.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT:
		return
	if _transitioning or not Settings.get_value(&"pause_on_focus_loss"):
		return
	ui.pause_if_playing()

# Fundido desde blanco al llegar del salto al hiperespacio.
func _fade_in_from_white() -> void:
	await _fade_white(1.0, 0.0)

# Cubre la pantalla de blanco con alfa inicial y la lleva a alfa final; al llegar a 0 se libera.
# El tween sigue corriendo con el árbol en pausa (pantallas de victoria y derrota).
func _fade_white(from_alpha: float, to_alpha: float, layer: CanvasLayer = null) -> CanvasLayer:
	var white: ColorRect
	if layer == null:
		layer = CanvasLayer.new()
		layer.layer = 100
		white = ColorRect.new()
		white.set_anchors_preset(Control.PRESET_FULL_RECT)
		white.mouse_filter = Control.MOUSE_FILTER_STOP
		layer.add_child(white)
		add_child(layer)
	else:
		white = layer.get_child(0)
	white.color = Color(1, 1, 1, from_alpha)
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(white, "color:a", to_alpha, ENTER_FADE_TIME)
	await tween.finished
	if to_alpha == 0.0:
		layer.queue_free()
	return layer

func _setup_level() -> void:
	level.setup(level_data)
	level.lost.connect(_on_level_lost)
	level.won.connect(_on_level_won)
	# Posición del nivel en la lista + 1; 0 si no está (no se muestra número)
	var level_number: int = GameData.levels.find(level_data) + 1
	var has_next_level: bool = level_number > 0 and level_number < GameData.levels.size()
	level.build_manager.tutorial_hints = ui.tutorial_hints
	ui.setup_powers(level.get_node(^"Powers"))
	ui.setup(level.game_state, level.turrets, level_number, level.spawner, has_next_level, level.base)
	_is_emergency = level_data == GameData.emergency_level
	if _is_emergency:
		ui.start_emergency(level)

func _on_level_lost() -> void:
	GameState.flush()
	# La UI recibe el resumen ya hecho; no lee el nivel por su cuenta.
	ui.show_run_stats(level.get_run_stats())
	ui.set_state(LevelUI.UiState.LOST)

func _on_level_won() -> void:
	# Si no está en la lista, find devuelve -1 y el número es 0: no desbloquea nada.
	var number: int = GameData.levels.find(level_data) + 1
	GameState.complete_level(number)
	var stars: int = GameState.stars_for_health(level.base.health, level.base.max_health)
	GameState.record_level_stars(number, stars)
	ui.show_victory_stars(stars)
	# El nivel de emergencia sale con su pantalla de victoria, pero no cuenta como victoria ni da logros.
	if not _is_emergency:
		GameState.register_win(number, level.base.health == level.base.max_health)
	ui.show_run_stats(level.get_run_stats())
	ui.set_state(LevelUI.UiState.WON)

func _on_action_requested(action: LevelUI.Action) -> void:
	match action:
		LevelUI.Action.RESTART:
			_restart_level()
		LevelUI.Action.QUIT:
			_quit_to_menu()
		LevelUI.Action.NEXT_LEVEL:
			_next_level()

# Monta el siguiente nivel de la lista por el mismo camino que el reinicio.
func _next_level() -> void:
	var next_index: int = GameData.levels.find(level_data) + 1
	if next_index <= 0 or next_index >= GameData.levels.size():
		return
	level_data = GameData.levels[next_index]
	_restart_level()

# Barrido a blanco, cambio de nivel con la pantalla tapada y fundido de vuelta.
func _restart_level() -> void:
	if _transitioning:
		return
	_transitioning = true
	var layer: CanvasLayer = await _fade_white(0.0, 1.0)
	var index: int = level.get_index()
	remove_child(level)
	level.queue_free()
	level = _level_scene.instantiate()
	add_child(level)
	move_child(level, index)
	_setup_level()
	_transitioning = false
	await _fade_white(1.0, 0.0, layer)

# Salir del nivel de emergencia (ganado, perdido, desde la pausa o con "Saltar") lo da por hecho: no se repite.
# Del nivel de emergencia se vuelve a la oficina; de un sector, a la selección de nivel.
func _quit_to_menu() -> void:
	if _is_emergency:
		GameState.complete_tutorial()
	var menu: Node = load(MAIN_MENU_PATH).instantiate()
	menu.start_on_level_selection = not _is_emergency
	var tree: SceneTree = get_tree()
	var old_scene: Node = tree.current_scene
	tree.root.add_child(menu)
	tree.current_scene = menu
	old_scene.queue_free()
