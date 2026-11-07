extends Control

# Menú principal: la oficina del comandante. Tres vistas (izquierda, centro y derecha) que se
# cambian girando la silla con las flechas de los bordes o las teclas; cada objeto de la oficina
# abre su panel holograma encima, con la oficina oscurecida detrás. Escape cierra el panel abierto
# o, en la oficina, pregunta si salir del juego. La pantalla de la mesa del radar enseña la pantalla
# de Sectores (que, mientras está cerrada, se pinta en RadarViewport); al pulsarla, la vista se
# acerca hasta que esa pantalla queda encima de la de Sectores, con su borde a la vista.

enum View { LEFT, CENTER, RIGHT }

const FADE_TIME: float = 0.25
const WARP_TIME: float = 0.5
const FLASH_TIME: float = 0.1
# Giro de la silla: duración del paso a la vista de al lado y ancho de cada vista.
const TURN_TIME: float = 0.45
const VIEW_WIDTH: float = 960.0
const VIEW_SIZE: Vector2 = Vector2(960.0, 540.0)
# Margen alrededor del contenido de Sectores en la pantalla de la mesa (lo que se ve del borde).
const SCREEN_MARGIN: float = 20.0
# Acercamiento a la mesa del radar al abrir Sectores (y alejamiento al cerrar).
const ZOOM_TIME: float = 0.7

var start_on_level_selection: bool = false

@onready var office: Control = $Office
@onready var views: Control = $Office/Views
@onready var radar_console: RadarConsole = $Office/Views/CenterView/RadarConsole
@onready var radar_viewport: SubViewport = $RadarViewport
@onready var space: Node2D = $Space
@onready var turn_left_arrow: TurnArrow = $Office/TurnLeftArrow
@onready var turn_right_arrow: TurnArrow = $Office/TurnRightArrow
@onready var exit_door: OfficeDoor = $Office/Views/LeftView/ExitDoor
@onready var panel_dim: ColorRect = $PanelDim
@onready var level_selection_panel: VBoxContainer = $LevelSelectionScreen
@onready var levels_panel: Control = $LevelSelectionScreen/LevelsPanel
@onready var sector_radar: SectorRadar = %SectorRadar
@onready var sector_card: SectorCard = %SectorCard
@onready var sectors_subtitle: Label = %SectorsSubtitle
@onready var stats_panel: VBoxContainer = $StatsScreen
@onready var stats_label: Label = %StatsLabel
@onready var navedex: Navedex = $Navedex
@onready var achievements_screen: AchievementsScreen = $AchievementsScreen
@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var quit_confirm: Control = $QuitConfirm

var _view: View = View.CENTER
var _turn_tween: Tween
# Panel abierto encima de la oficina; null si se ve la oficina.
var _panel: Control
var _panel_tween: Tween
var _jumping: bool = false
var _leaving: bool = false
# Zoom a la mesa del radar: mientras dura no se gira ni se pulsa nada.
var _zooming: bool = false
var _zoom_tween: Tween
# Sitio de la pantalla de Sectores entre los hijos del menú (para volver a ponerla en su capa).
var _sectors_index: int
# Parte de la pantalla de Sectores que enseña la mesa: su contenido más SCREEN_MARGIN (en píxeles
# del menú). Al final del zoom la pantalla de la mesa ocupa justo este rectángulo.
var _screen_rect: Rect2 = Rect2(Vector2.ZERO, VIEW_SIZE)

func _ready() -> void:
	_set_pan(0.0)
	_update_arrows()
	var quit_button: Button = %QuitButton
	quit_button.add_theme_stylebox_override(&"hover_pressed", quit_button.get_theme_stylebox(&"hover"))
	quit_button.add_theme_color_override(&"font_hover_pressed_color", quit_button.get_theme_color(&"font_hover_color"))
	_sectors_index = level_selection_panel.get_index()
	_fit_radar_viewport()
	levels_panel.resized.connect(_update_screen_rect)
	_update_screen_rect()
	get_viewport().size_changed.connect(_fit_radar_viewport)
	level_selection_panel.show()
	if start_on_level_selection:
		# Sin animación: la oficina queda ya acercada detrás.
		_panel = level_selection_panel
		panel_dim.modulate.a = 0.0
		panel_dim.show()
		_set_radar_zoom(1.0)
	else:
		_move_sectors(true)
	sector_radar.sector_selected.connect(_on_sector_selected)
	sector_radar.sector_launched.connect(_on_sector_launched)
	sector_card.deploy_pressed.connect(_on_deploy_pressed)
	GameState.progress_reset.connect(_refresh_sectors)
	_refresh_sectors()

func _unhandled_input(event: InputEvent) -> void:
	if _jumping or _leaving or _zooming:
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
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode in [KEY_LEFT, KEY_A]:
		get_viewport().set_input_as_handled()
		_turn(-1)
	elif key.physical_keycode in [KEY_RIGHT, KEY_D]:
		get_viewport().set_input_as_handled()
		_turn(1)

# --- Giro de la silla ----------------------------------------------------------------------

# Gira a la vista de al lado (-1 izquierda, 1 derecha), si la hay.
func _turn(step: int) -> void:
	var target: View = clampi(_view + step, View.LEFT, View.RIGHT) as View
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
	if _panel == null or _zooming:
		return
	if _panel == level_selection_panel:
		_close_sectors()
		return
	var panel: Control = _panel
	_panel = null
	_fade_panel(panel, false)

func _fade_panel(panel: Control, show_it: bool) -> void:
	if _panel_tween:
		_panel_tween.kill()
	var target: float = 1.0 if show_it else 0.0
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
	_open_sectors()

func _on_archive_tablet_pressed() -> void:
	_open_panel(navedex)

func _on_medal_case_pressed() -> void:
	_open_panel(achievements_screen)

func _on_options_console_pressed() -> void:
	_open_panel(options_menu)

@warning_ignore("integer_division")
func _on_combat_scoreboard_pressed() -> void:
	var seconds: int = int(GameState.play_time)
	var favorite: String = GameState.favorite_turret()
	var turret_name: String = "-"
	if favorite != "":
		turret_name = (load(Navedex.TURRET_DIR + favorite + ".tres") as TurretData).get_inspect_name()
	stats_label.text = "\n".join([
		tr("STATS_KILLS") % GameState.stats.get("kills", 0),
		tr("STATS_SPENT") % UiFormat.money(GameState.stats.get("spent", 0)),
		tr("STATS_TIME") % [seconds / 3600, seconds % 3600 / 60],
		tr("STATS_FAVORITE") % turret_name,
		tr("STATS_WINS") % GameState.stats.get("wins", 0),
	])
	_open_panel(stats_panel)

# --- Zoom a la mesa del radar ---------------------------------------------------------------

# La vista se acerca a la mesa y su pantalla se endereza hasta llenar la vista; entonces la pantalla
# de Sectores sale de RadarViewport y queda encima, igual.
func _open_sectors() -> void:
	if _panel or _jumping or _leaving:
		return
	_panel = level_selection_panel
	_zooming = true
	_refresh_sectors()
	# PanelDim, transparente, solo tapa la oficina para que no se pulse nada.
	panel_dim.modulate.a = 0.0
	panel_dim.show()
	await _tween_zoom(1.0)
	_move_sectors(false)
	_zooming = false

# Lo inverso: la pantalla vuelve a la mesa y la vista se aleja.
func _close_sectors() -> void:
	_zooming = true
	_move_sectors(true)
	await _tween_zoom(0.0)
	panel_dim.hide()
	_panel = null
	_zooming = false

func _tween_zoom(target: float) -> void:
	_zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_method(_set_radar_zoom, 1.0 - target, target, ZOOM_TIME)
	await _zoom_tween.finished

# Zoom de 0 (la oficina normal) a 1 (la pantalla de la mesa ocupa _screen_rect, centrada).
func _set_radar_zoom(amount: float) -> void:
	var center: Vector2 = radar_console.get_screen_center()
	var final_scale: float = _screen_rect.size.x / radar_console.get_screen_width()
	var zoom: float = lerpf(1.0, final_scale, amount)
	var offset: Vector2 = (_screen_rect.get_center() - center * final_scale) * amount
	office.scale = Vector2(zoom, zoom)
	office.position = offset
	space.scale = Vector2(zoom, zoom)
	space.position = offset
	radar_console.set_zoom(amount, Rect2(center - _screen_rect.size / final_scale / 2.0, _screen_rect.size / final_scale))

# La mesa enseña solo el contenido de Sectores (con un margen), para que se lea mejor.
func _update_screen_rect() -> void:
	_screen_rect = levels_panel.get_rect().grow(SCREEN_MARGIN)
	radar_console.set_screen_texture(radar_viewport.get_texture(), Rect2(_screen_rect.position / VIEW_SIZE, _screen_rect.size / VIEW_SIZE))
	if _panel == level_selection_panel and not _zooming:
		_set_radar_zoom(1.0)

# La pantalla de Sectores se pinta en RadarViewport (la enseña la mesa) o encima de la oficina.
func _move_sectors(into_viewport: bool) -> void:
	level_selection_panel.reparent(radar_viewport if into_viewport else self, false)
	if not into_viewport:
		move_child(level_selection_panel, _sectors_index)

# RadarViewport a la resolución real de la pantalla, para que su textura se vea igual que el menú.
func _fit_radar_viewport() -> void:
	var stretch: float = maxf(get_viewport().get_final_transform().x.x, 1.0)
	radar_viewport.size = Vector2i((VIEW_SIZE * stretch).ceil())
	radar_viewport.size_2d_override = Vector2i(VIEW_SIZE)

# --- Selección de sector (radar) -----------------------------------------------------------

# Vuelve a leer el progreso en el radar y la ficha (el radar ya lo lee al crearse).
func _refresh_sectors() -> void:
	sector_radar.refresh()
	_on_sector_selected(sector_radar.selected_index)
	sectors_subtitle.text = tr("RADAR_SUBTITLE") % [sector_radar.get_secured_count(), SectorRadar.TOTAL_SECTORS,
			SectorRadar.format_thousands(sector_radar.get_range_km())]

func _on_sector_selected(index: int) -> void:
	sector_card.show_level(index, sector_radar.get_level_state(index) if index >= 0 else SectorRadar.ContactState.LOCKED)

func _on_sector_launched(index: int) -> void:
	# El sector del jefe aún no tiene nivel.
	if index >= GameData.levels.size():
		return
	_open_level(GameData.levels[index])

func _on_deploy_pressed() -> void:
	if sector_radar.selected_index >= 0:
		_on_sector_launched(sector_radar.selected_index)

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
	var game: Game = preload("res://scenes/Game.tscn").instantiate()
	game.level_data = data
	game.from_hyperspace = true
	var tree: SceneTree = get_tree()
	tree.root.add_child(game)
	tree.current_scene.queue_free()
	tree.current_scene = game

# Estrellas en líneas y destello blanco que cubre el menú antes de cargar el nivel.
func _hyperspace_jump() -> void:
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(flash)
	await $Space/StarField.warp(WARP_TIME)
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", 1.0, FLASH_TIME)
	await tween.finished
