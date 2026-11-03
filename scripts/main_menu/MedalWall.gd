class_name MedalWall
extends OfficeObject

# Mural de condecoraciones en la pared: abre los logros. Una medalla por logro de
# GameState.ACHIEVEMENTS (cinta y el icono del logro a ×2); los que faltan son un hueco vacío.
# Abajo, cuántos hay conseguidos. Con el ratón encima las medallas destellan.

const ICON_DIR := "res://assets/ui/achievements/"
const FRAME := Rect2i(0, 0, 520, 300)
const BOARD := Rect2i(8, 8, 504, 284)
const BOARD_COLOR := Color("#0b1322")
const BOARD_DARK := Color("#08101c")
const TITLE := "CONDECORACIONES"
const COLUMNS := 6
# Medallas: primera columna, separación, fila de arriba de cada fila y tamaño del icono.
const FIRST_X := 63
const COLUMN_STEP := 79
const ROW_TOPS: Array[int] = [62, 160]
const RIBBON_SIZE := Vector2i(14, 20)
const ICON_SCALE := 2
# Familia de color de cada logro (como el símbolo de su icono): ámbar victorias y mejoras, rojo bajas, cian el resto.
const AMBER_IDS: Array[String] = ["first_win", "flawless", "wins_5", "all_levels", "fuse_first", "fuse_all"]
const RED_IDS: Array[String] = ["kills_100", "kills_1000"]

var _ids: Array[String] = []
var _icons: Dictionary[String, Texture2D] = {}

func _ready() -> void:
	super()
	for id: String in GameState.ACHIEVEMENTS:
		_ids.append(id)
		_icons[id] = load(ICON_DIR + id + ".png")

func _draw_object() -> void:
	OfficePaint.wall_box(self, FRAME)
	OfficePaint.rect(self, BOARD, OfficePaint.OUTLINE)
	OfficePaint.rect(self, BOARD.grow(-1), BOARD_COLOR)
	OfficePaint.rect(self, Rect2i(BOARD.position + Vector2i.ONE, Vector2i(BOARD.size.x - 2, 3)), BOARD_DARK)
	for corner: Vector2i in [Vector2i(3, 3), Vector2i(514, 3), Vector2i(3, 294), Vector2i(514, 294)]:
		OfficePaint.screw(self, corner)
	_draw_title()
	var done := 0
	for i in _ids.size():
		var id := _ids[i]
		@warning_ignore("integer_division")
		var center_x := FIRST_X + (i % COLUMNS) * COLUMN_STEP
		@warning_ignore("integer_division")
		var top := ROW_TOPS[i / COLUMNS]
		if id in GameState.unlocked:
			done += 1
			_draw_medal(id, center_x, top, i)
		else:
			_draw_socket(center_x, top)
	_draw_counter(done)

func _draw_title() -> void:
	var width := OfficePaint.text_width(TITLE) + 16
	@warning_ignore("integer_division")
	var plate := Rect2i(FRAME.size.x / 2 - width / 2, 20, width, 19)
	OfficePaint.bevel_box(self, plate, OfficePaint.PLATE, OfficePaint.AMBER_DARK, OfficePaint.PLATE_DARK)
	@warning_ignore("integer_division")
	OfficePaint.text_centered(self, FRAME.size.x / 2, 23, TITLE, OfficePaint.AMBER_LIGHT if hovered else OfficePaint.AMBER)

func _ramp(id: String) -> Array[Color]:
	if id in AMBER_IDS:
		return [OfficePaint.AMBER_DARK, OfficePaint.AMBER, OfficePaint.AMBER_LIGHT]
	if id in RED_IDS:
		return [OfficePaint.RED_DARK, OfficePaint.RED, OfficePaint.RED_LIGHT]
	return [OfficePaint.CYAN_DARK, OfficePaint.CYAN, OfficePaint.CYAN_LIGHT]

# Cinta de rayas verticales, anilla y el icono del logro a ×2, con una placa debajo.
func _draw_medal(id: String, center_x: int, top: int, index: int) -> void:
	var ramp := _ramp(id)
	@warning_ignore("integer_division")
	var ribbon := Rect2i(center_x - RIBBON_SIZE.x / 2, top, RIBBON_SIZE.x, RIBBON_SIZE.y)
	OfficePaint.rect(self, ribbon.grow(1), OfficePaint.OUTLINE)
	var stripes: Array[Color] = [ramp[0], ramp[1], ramp[2], ramp[1], ramp[0]]
	var widths: Array[int] = [3, 3, 2, 3, 3]
	var x := ribbon.position.x
	for s in stripes.size():
		OfficePaint.rect(self, Rect2i(x, ribbon.position.y, widths[s], ribbon.size.y), stripes[s])
		x += widths[s]
	OfficePaint.rect(self, Rect2i(center_x - 2, ribbon.end.y + 1, 4, 2), OfficePaint.METAL_LIGHT)
	var icon := _icons[_ids[index]]
	var icon_size := Vector2i(icon.get_size()) * ICON_SCALE
	@warning_ignore("integer_division")
	var icon_at := Vector2i(center_x - icon_size.x / 2, ribbon.end.y + 3)
	draw_texture_rect(icon, Rect2(icon_at, icon_size), false)
	if hovered and sin(time * 5.0 + index * 1.3) > 0.4:
		_draw_sparkle(icon_at + Vector2i(9, 9))
	OfficePaint.rect(self, Rect2i(center_x - 10, icon_at.y + icon_size.y + 5, 20, 2), OfficePaint.METAL_DARK)

# Destello de cuatro puntas.
func _draw_sparkle(at: Vector2i) -> void:
	OfficePaint.rect(self, Rect2i(at.x - 2, at.y, 5, 1), OfficePaint.CYAN_LIGHT)
	OfficePaint.rect(self, Rect2i(at.x, at.y - 2, 1, 5), OfficePaint.CYAN_LIGHT)
	OfficePaint.rect(self, Rect2i(at, Vector2i.ONE), Color.WHITE)

# Hueco de una medalla que falta: gancho sin cinta y la marca redonda de donde iría.
func _draw_socket(center_x: int, top: int) -> void:
	OfficePaint.rect(self, Rect2i(center_x - 3, top, 6, 2), OfficePaint.WALL_EDGE)
	var center := Vector2i(center_x, top + RIBBON_SIZE.y + 3 + 16)
	OfficePaint.disc(self, center, 14, BOARD_DARK)
	OfficePaint.ring(self, center, 14, OfficePaint.WALL_EDGE)
	OfficePaint.rect(self, Rect2i(center_x - 10, center.y + 21, 20, 2), OfficePaint.WALL_LIGHT)

func _draw_counter(done: int) -> void:
	var value := "%d/%d" % [done, _ids.size()]
	var width := OfficePaint.text_width(value) + 16
	@warning_ignore("integer_division")
	var plate := Rect2i(FRAME.size.x / 2 - width / 2, 258, width, 19)
	OfficePaint.bevel_box(self, plate, OfficePaint.PLATE, OfficePaint.AMBER_DARK, OfficePaint.PLATE_DARK)
	@warning_ignore("integer_division")
	OfficePaint.text_centered(self, FRAME.size.x / 2, 261, value, OfficePaint.AMBER_LIGHT)
