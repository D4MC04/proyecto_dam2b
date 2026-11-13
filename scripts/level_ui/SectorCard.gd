extends MarginContainer
class_name SectorCard

# Ficha del sector seleccionado en el radar, estilo HUD con esquinas: "SEC-0N · nombre", estado,
# rumbo, distancia, oleadas, amenaza, mejor marca de estrellas y el botón DESPLEGAR / REPETIR.
# Ancho fijo (custom_minimum_size) y textos recortados, para que no se mueva con textos más largos
# ni al cambiar de idioma.

signal deploy_pressed

const TEXT_SIZE: int = 24
const TITLE_COLOR: Color = Color("#40e0f0")
const NAME_COLOR: Color = Color("#5a7a96")
const VALUE_COLOR: Color = Color("#cce6ff")
const BG_COLOR: Color = Color("#0a0f1a", 0.88)
const BORDER_COLOR: Color = Color("#1c4a60")
const CORNER_COLOR: Color = Color("#40e0f0")
const ROW_LINE_COLOR: Color = Color("#1c4a60")
const CORNER_LENGTH: int = 12
const CORNER_WIDTH: int = 2
# Las esquinas salen un poco fuera del borde.
const CORNER_OUTSET: int = 3
const BUTTON_HEIGHT: int = 36

const SECURED_COLOR: Color = Color("#3cb860")
const ACTIVE_COLOR: Color = Color("#ecb23c")
const THREAT_COLORS: Array[Color] = [Color("#3cb860"), Color("#ecb23c"), Color("#ff8c32"), Color("#ff3c5a")]
const THREAT_KEYS: Array[String] = ["THREAT_LOW", "THREAT_MEDIUM", "THREAT_HIGH", "THREAT_EXTREME"]
const DEPLOY_COLOR: Color = Color("#ecb23c")
const DEPLOY_HOVER_COLOR: Color = Color("#ffe082")
const REPLAY_COLOR: Color = Color("#3cb860")
const REPLAY_HOVER_COLOR: Color = Color("#7ee89a")

const STAR_PIXEL: int = 2
const STAR_GAP: int = 4
const STAR_COLOR: Color = Color("#ecb23c")
const UNKNOWN_COLOR: Color = Color("#e65a4f")

# Fila "NOMBRE ........ valor" con una línea de puntos debajo.
class CardRow extends HBoxContainer:
	var name_label: Label = Label.new()
	var value_label: Label = Label.new()

	func _init(key: String) -> void:
		name_label.text = key
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_color_override("font_color", SectorCard.NAME_COLOR)
		name_label.add_theme_font_size_override("font_size", SectorCard.TEXT_SIZE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# Los valores ya llegan traducidos.
		value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		value_label.add_theme_color_override("font_color", SectorCard.VALUE_COLOR)
		value_label.add_theme_font_size_override("font_size", SectorCard.TEXT_SIZE)
		add_child(name_label)
		add_child(value_label)

	func _draw() -> void:
		var y: float = size.y - 1.0
		for x: int in range(0, int(size.x), 3):
			draw_rect(Rect2(x, y, 1, 1), SectorCard.ROW_LINE_COLOR)

# Estrellas de la mejor marca en pixel art (la forma de VictoryScreen.STAR_SHAPE).
class StarsDisplay extends Control:
	var stars: int = 0:
		set(value):
			stars = value
			queue_redraw()

	func _init() -> void:
		var shape: Array[String] = VictoryScreen.STAR_SHAPE
		var star_width: int = shape[0].length() * SectorCard.STAR_PIXEL
		custom_minimum_size = Vector2(
				GameState.MAX_STARS * star_width + (GameState.MAX_STARS - 1) * SectorCard.STAR_GAP,
				shape.size() * SectorCard.STAR_PIXEL)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var shape: Array[String] = VictoryScreen.STAR_SHAPE
		var star_width: int = shape[0].length() * SectorCard.STAR_PIXEL
		for index: int in GameState.MAX_STARS:
			var filled: bool = index < stars
			var origin: Vector2 = Vector2(index * (star_width + SectorCard.STAR_GAP), 0)
			for row: int in shape.size():
				for column: int in shape[row].length():
					# Las que faltan, solo el contorno (como ☆).
					if shape[row][column] == "#" and (filled or _is_edge(shape, row, column)):
						draw_rect(Rect2(origin + Vector2(column, row) * SectorCard.STAR_PIXEL, Vector2.ONE * SectorCard.STAR_PIXEL), SectorCard.STAR_COLOR)

	# Un píxel de la forma es borde si alguno de sus cuatro vecinos está vacío o fuera.
	static func _is_edge(shape: Array[String], row: int, column: int) -> bool:
		for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var r: int = row + offset.y
			var c: int = column + offset.x
			if r < 0 or r >= shape.size() or c < 0 or c >= shape[r].length() or shape[r][c] != "#":
				return true
		return false

var _title_label: Label = Label.new()
var _status_row: CardRow = CardRow.new("CARD_STATUS")
var _bearing_row: CardRow = CardRow.new("CARD_BEARING")
var _distance_row: CardRow = CardRow.new("CARD_DISTANCE")
var _waves_row: CardRow = CardRow.new("CARD_WAVES")
var _threat_row: CardRow = CardRow.new("CARD_THREAT")
var _best_row: CardRow = CardRow.new("CARD_BEST")
var _stars_display: StarsDisplay = StarsDisplay.new()
var _deploy_button: Button = Button.new()
# Nivel que enseña la ficha (desde 0) y su estado; -1 = ninguno.
var _index: int = -1
var _state: SectorRadar.ContactState = SectorRadar.ContactState.LOCKED

func _ready() -> void:
	add_theme_constant_override("margin_left", 16)
	add_theme_constant_override("margin_right", 16)
	add_theme_constant_override("margin_top", 14)
	add_theme_constant_override("margin_bottom", 14)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	_title_label.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	box.add_child(_title_label)
	for row: CardRow in [_status_row, _bearing_row, _distance_row, _waves_row, _threat_row, _best_row]:
		box.add_child(row)
	# En la fila MEJOR, las estrellas van en lugar del texto.
	_best_row.value_label.hide()
	_best_row.add_child(_stars_display)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 10
	box.add_child(gap)
	_deploy_button.custom_minimum_size.y = BUTTON_HEIGHT
	_deploy_button.clip_text = true
	# Botón dibujado en la pantalla (solo el contorno), como la ficha.
	_deploy_button.theme_type_variation = &"ScreenButton"
	_deploy_button.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_deploy_button.add_theme_font_size_override("font_size", TEXT_SIZE)
	_deploy_button.pressed.connect(deploy_pressed.emit)
	box.add_child(_deploy_button)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()

## Enseña el nivel `index` (desde 0) de GameData.levels con su estado en el radar.
func show_level(index: int, state: SectorRadar.ContactState) -> void:
	_index = index
	_state = state
	_refresh()

func _refresh() -> void:
	if _state == SectorRadar.ContactState.UNKNOWN:
		_show_unknown()
		return
	var has_level: bool = _index >= 0 and _index < GameData.levels.size()
	_deploy_button.disabled = not has_level
	if not has_level:
		_title_label.text = ""
		for row: CardRow in [_status_row, _bearing_row, _distance_row, _waves_row, _threat_row]:
			row.value_label.text = "-"
		_stars_display.stars = 0
		_deploy_button.text = ""
		return
	var data: LevelData = GameData.levels[_index]
	var completed: bool = _state == SectorRadar.ContactState.COMPLETED
	_title_label.text = "%s - %s" % [SectorRadar.get_sector_code(_index), tr(data.sector_name).to_upper()]
	_set_value(_status_row, tr("CARD_SECURED") if completed else tr("CARD_ACTIVE"), SECURED_COLOR if completed else ACTIVE_COLOR)
	_set_value(_bearing_row, "%03d°" % (roundi(data.radar_bearing) % 360), VALUE_COLOR)
	_set_value(_distance_row, tr("CARD_KM") % SectorRadar.format_thousands(SectorRadar.get_distance_km(data)), VALUE_COLOR)
	_set_value(_waves_row, str(data.waves.size()), VALUE_COLOR)
	_set_value(_threat_row, tr(THREAT_KEYS[data.threat]), THREAT_COLORS[data.threat])
	# Sin completar, las estrellas salen vacías.
	_stars_display.stars = GameState.get_level_stars(_index + 1) if completed else 0
	_deploy_button.text = tr("BTN_REPLAY") if completed else tr("BTN_DEPLOY")
	var color: Color = REPLAY_COLOR if completed else DEPLOY_COLOR
	var hover_color: Color = REPLAY_HOVER_COLOR if completed else DEPLOY_HOVER_COLOR
	_deploy_button.add_theme_color_override("font_color", color)
	_deploy_button.add_theme_color_override("font_focus_color", color)
	_deploy_button.add_theme_color_override("font_hover_color", hover_color)
	_deploy_button.add_theme_color_override("font_pressed_color", hover_color)

# Sector del jefe que aún no tiene nivel: todo desconocido y el botón apagado.
func _show_unknown() -> void:
	_title_label.text = "%s - ???" % SectorRadar.get_sector_code(_index)
	_set_value(_status_row, tr("CARD_NO_DATA"), UNKNOWN_COLOR)
	for row: CardRow in [_bearing_row, _distance_row, _waves_row]:
		_set_value(row, "???", VALUE_COLOR)
	_set_value(_threat_row, "???", UNKNOWN_COLOR)
	_stars_display.stars = 0
	_deploy_button.disabled = true
	_deploy_button.text = tr("BTN_UNAVAILABLE")

func _set_value(row: CardRow, text: String, color: Color) -> void:
	row.value_label.text = text
	row.value_label.add_theme_color_override("font_color", color)

# Fondo, borde fino y esquinas en L.
func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG_COLOR)
	draw_rect(Rect2(0.5, 0.5, size.x - 1.0, size.y - 1.0), BORDER_COLOR, false, 1.0)
	var outer: Rect2 = rect.grow(CORNER_OUTSET)
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var point: Vector2 = outer.position + outer.size * corner
		var x_direction: float = 1.0 if corner.x == 0 else -1.0
		var y_direction: float = 1.0 if corner.y == 0 else -1.0
		var x: float = point.x if corner.x == 0 else point.x - CORNER_WIDTH
		var y: float = point.y if corner.y == 0 else point.y - CORNER_WIDTH
		# Brazo horizontal y vertical de la L
		var horizontal_x: float = x if x_direction > 0 else point.x - CORNER_LENGTH
		var vertical_y: float = y if y_direction > 0 else point.y - CORNER_LENGTH
		draw_rect(Rect2(horizontal_x, y, CORNER_LENGTH, CORNER_WIDTH), CORNER_COLOR)
		draw_rect(Rect2(x, vertical_y, CORNER_WIDTH, CORNER_LENGTH), CORNER_COLOR)
