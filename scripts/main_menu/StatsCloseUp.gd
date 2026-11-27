class_name StatsCloseUp
extends Control

# Monitor de stats de cerca: las estadísticas del menú principal. MainMenu se acerca al monitor de la
# pared izquierda (CombatScoreboard) y, al final del zoom, aparece este encima, en el mismo sitio. El
# marco es el del monitor (el trozo de left_static.png, a escala BODY_SCALE, así que encaja con la
# oficina acercada) y la pantalla se pinta a resolución completa: las ocho cifras de GameState, las
# barras con todas las torretas construidas (con su icono; con el ratón encima, su nombre y cuántas),
# el anillo del reparto por tipo de ataque con su leyenda y números, y las cinco fichas del monitor.
# Al abrirse se vuelven a leer los datos y los gráficos suben desde cero, como en el monitor.
# "Volver", Escape (lo lleva MainMenu) o un clic fuera del monitor emiten back_pressed.

signal back_pressed

const ROOM: Texture2D = preload("res://assets/sprites/office/left_static.png")
const VIEW_SIZE: Vector2i = Vector2i(960, 540)
## Aumento del monitor de la oficina: el zoom de MainMenu acaba con él a este tamaño.
const BODY_SCALE: float = 1.5
const PAD: int = 12
const LINE_HEIGHT: int = 16
const COLUMN_WIDTH: int = 240
# Gráfico de barras (en coordenadas de la pantalla): caja, hueco de cada torreta y alto máximo de barra.
const BARS_RECT: Rect2i = Rect2i(PAD, 110, 320, 170)
const BAR_STEP: int = 31
const BAR_WIDTH: int = 14
const BAR_MAX: int = 96
const ICON_SIZE: int = 32
# Anillo y su leyenda, a la derecha de las barras.
const RING_RECT: Rect2i = Rect2i(344, 110, 148, 170)
const RING_INNER: int = 26
const RING_OUTER: int = 40
# Fichas de abajo y botón "Volver".
const TILES_Y: int = 290
const TILE_SIZE: Vector2i = Vector2i(88, 56)
const TILE_STEP: int = 98
const BACK_SIZE: Vector2i = Vector2i(160, 28)

var _monitor: Rect2i
# Marco (el monitor entero) y pantalla, en coordenadas del nodo.
var _body: Rect2i
var _screen: Rect2i
var _frame: AtlasTexture = AtlasTexture.new()
var _icons: Array[Texture2D] = []
var _turrets: Array[Dictionary] = []
var _types: Array[Dictionary] = []
var _tiles: Array[int] = []
var _lines: Array[String] = []
var _time: float = 0.0
# Torreta de las barras bajo el ratón (-1 ninguna) y si está encima de "Volver".
var _hovered_bar: int = -1
var _back_hovered: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m: Array = OfficeLayout.LEFT.stats.rect
	var s: Array = OfficeLayout.LEFT.stats.screen
	_monitor = Rect2i(m[0], m[1], m[2], m[3])
	_frame.atlas = ROOM
	_frame.region = Rect2(_monitor)
	var body_size: Vector2i = Vector2i((Vector2(_monitor.size) * BODY_SCALE).round())
	@warning_ignore("integer_division")
	_body = Rect2i((VIEW_SIZE - body_size) / 2, body_size)
	_screen = Rect2i(_body.position + Vector2i((Vector2(s[0] - m[0], s[1] - m[1]) * BODY_SCALE).round()),
			Vector2i((Vector2(s[2], s[3]) * BODY_SCALE).round()))
	for id: String in CombatScoreboard.ICONS:
		_icons.append(load(CombatScoreboard.ICON_DIR + id + ".png"))

## Rectángulo del monitor en la vista: el zoom de MainMenu acaba con el de la oficina justo aquí.
func get_body_rect() -> Rect2:
	return Rect2(_body)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_refresh()

func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion:
		var point: Vector2i = Vector2i(motion.position) - _screen.position
		_back_hovered = _back_rect().has_point(point)
		_hovered_bar = -1
		var bars: Rect2i = BARS_RECT.grow(-4)
		if bars.has_point(point):
			@warning_ignore("integer_division")
			_hovered_bar = mini((point.x - bars.position.x) / BAR_STEP, _turrets.size() - 1)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _back_hovered else Control.CURSOR_ARROW
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _back_hovered or not _body.has_point(Vector2i(click.position)):
			back_pressed.emit()

# Vuelve a leer GameState y los gráficos suben otra vez desde cero.
@warning_ignore("integer_division")
func _refresh() -> void:
	_time = 0.0
	_turrets = CombatScoreboard.built_turrets()
	_types = CombatScoreboard.built_by_type(_turrets)
	_tiles = CombatScoreboard.tile_values()
	var stats: Dictionary = GameState.stats
	var seconds: int = int(GameState.play_time)
	var favorite: String = GameState.favorite_turret()
	var turret_name: String = "-"
	if favorite != "":
		turret_name = (load(Navedex.TURRET_DIR + favorite + ".tres") as TurretData).get_inspect_name()
	# Dos columnas: primero la de la izquierda, de arriba abajo.
	_lines = [
		tr("STATS_KILLS") % stats.get("kills", 0),
		tr("STATS_WINS") % stats.get("wins", 0),
		tr("STATS_TURRETS") % stats.get("turrets", 0),
		tr("STATS_PERFECT_WAVES") % stats.get("perfect_waves", 0),
		tr("STATS_SPENT") % UiFormat.money(stats.get("spent", 0)),
		tr("STATS_TIME") % [seconds / 3600, seconds % 3600 / 60],
		tr("STATS_FAVORITE") % turret_name,
		tr("STATS_POWERS") % stats.get("powers", 0),
	]

func _back_rect() -> Rect2i:
	@warning_ignore("integer_division")
	return Rect2i((_screen.size.x - BACK_SIZE.x) / 2, _screen.size.y - PAD - BACK_SIZE.y, BACK_SIZE.x, BACK_SIZE.y)

func _draw() -> void:
	draw_texture_rect(_frame, Rect2(_body), false)
	# Pilotos del labio, encendidos (en la oficina los pinta OfficeLights encima del PNG).
	for led: Dictionary in OfficeLayout.LEFT.leds:
		var r: Rect2 = Rect2(led.x, led.y, led.w, led.h)
		if Rect2(_monitor).encloses(r):
			draw_rect(Rect2(Vector2(_body.position) + (r.position - Vector2(_monitor.position)) * BODY_SCALE, r.size * BODY_SCALE),
					OfficeLights._palette(led.c))
	for y: int in range(_screen.position.y, _screen.end.y):
		OfficePaint.rect(self, Rect2i(_screen.position.x, y, _screen.size.x, 1),
				OfficePaint.SCREEN_DARK if y % 2 == 1 else OfficePaint.SCREEN)
	if _tiles.is_empty():
		return
	# Todo lo de dentro en coordenadas de la pantalla.
	draw_set_transform(Vector2(_screen.position))
	var grow: float = CombatScoreboard.grow_amount(_time)
	OfficePaint.text(self, Vector2i(PAD, 8), "// " + tr("HEADER_STATS"), OfficePaint.CYAN)
	var width: int = _screen.size.x - PAD * 2
	OfficePaint.rect(self, Rect2i(PAD, 24, width, 2), OfficePaint.CYAN_DARK)
	for x: int in range(0, width, 8):
		OfficePaint.rect(self, Rect2i(PAD + x, 26, 2, 4 if x % 32 == 0 else 2), OfficePaint.CYAN_DARK)
	for i: int in _lines.size():
		@warning_ignore("integer_division")
		OfficePaint.text(self, Vector2i(PAD + (i / 4) * COLUMN_WIDTH, 38 + (i % 4) * LINE_HEIGHT), _lines[i], OfficePaint.CYAN_LIGHT)
	_draw_bars(grow)
	_draw_ring(grow)
	for i: int in _tiles.size():
		_draw_tile(PAD + i * TILE_STEP, i, grow)
	_draw_back()
	draw_set_transform(Vector2.ZERO)

# Todas las torretas de más a menos construidas, normalizadas a la más alta, con su número encima y su
# icono debajo. Arriba el título, o el nombre y las construidas de la que está bajo el ratón.
func _draw_bars(grow: float) -> void:
	var box: Rect2i = BARS_RECT
	OfficePaint.rect(self, box, CombatScoreboard.CHART_BG)
	var base: int = box.end.y - ICON_SIZE - 6
	OfficePaint.rect(self, Rect2i(box.position.x, base, box.size.x, 2), OfficePaint.CYAN_DARK)
	var title: String = tr("STATS_BUILT")
	if _hovered_bar >= 0:
		var hovered: Dictionary = _turrets[_hovered_bar]
		title = "%s: %d" % [(hovered.data as TurretData).get_inspect_name(), hovered.count]
	OfficePaint.text(self, Vector2i(box.position.x + 6, box.position.y + 4), title, OfficePaint.CYAN)
	var best: int = maxi(_turrets[0].count, 1)
	for i: int in _turrets.size():
		var x: int = box.position.x + 4 + i * BAR_STEP
		@warning_ignore("integer_division")
		var center: int = x + BAR_STEP / 2
		var count: int = _turrets[i].count
		var beat: float = 1.0 + sin(_time * 2.0 + i * 0.8) * 0.03 * grow
		var height: int = roundi(float(count) / best * BAR_MAX * grow * beat)
		var lit: bool = i == _hovered_bar
		if height > 0:
			@warning_ignore("integer_division")
			var bar: Rect2i = Rect2i(center - BAR_WIDTH / 2, base - height, BAR_WIDTH, height)
			OfficePaint.rect(self, bar, OfficePaint.CYAN if lit else OfficePaint.CYAN_DARK)
			OfficePaint.rect(self, Rect2i(bar.position, Vector2i(BAR_WIDTH, 2)), OfficePaint.CYAN_LIGHT if lit else OfficePaint.CYAN)
		OfficePaint.text_centered(self, center, base - height - 14, UiFormat.abbreviate(roundi(count * grow)),
				OfficePaint.CYAN_LIGHT if lit else OfficePaint.CYAN)
		var icon: Texture2D = (_turrets[i].data as TurretData).icon
		@warning_ignore("integer_division")
		draw_texture_rect(icon, Rect2(center - ICON_SIZE / 2, base + 4, ICON_SIZE, ICON_SIZE), false,
				Color.WHITE if count > 0 or lit else Color(1, 1, 1, 0.35))

# El anillo del monitor en grande, con el total en medio y la leyenda con el nombre y el número de cada tipo.
func _draw_ring(grow: float) -> void:
	var box: Rect2i = RING_RECT
	OfficePaint.rect(self, box, CombatScoreboard.CHART_BG)
	var cx: int = box.get_center().x
	OfficePaint.text_centered(self, cx, box.position.y + 4, tr("STATS_BY_TYPE"), OfficePaint.CYAN)
	var center: Vector2i = Vector2i(cx, box.position.y + 64)
	CombatScoreboard.draw_ring(self, center, RING_INNER, RING_OUTER, _types, _time * 0.3, grow)
	var total: int = 0
	for type: Dictionary in _types:
		total += type.count
	OfficePaint.text_centered(self, cx, center.y - 7, UiFormat.abbreviate(roundi(total * grow)), OfficePaint.CYAN_LIGHT)
	var right: int = box.end.x - 8
	for i: int in _types.size():
		var y: int = box.position.y + 112 + i * 14
		OfficePaint.rect(self, Rect2i(box.position.x + 8, y + 3, 7, 7), CombatScoreboard.RING_COLORS[i])
		OfficePaint.text(self, Vector2i(box.position.x + 20, y), tr(_types[i].label), OfficePaint.CYAN_LIGHT)
		var count: String = UiFormat.abbreviate(roundi(_types[i].count * grow))
		OfficePaint.text(self, Vector2i(right - OfficePaint.text_width(count), y), count, CombatScoreboard.RING_COLORS[i])

# Las fichas del monitor en grande: el icono a escala 2 y su número debajo, que cuenta desde cero.
func _draw_tile(x: int, i: int, grow: float) -> void:
	var ci: RID = get_canvas_item()
	var tile: Rect2i = Rect2i(Vector2i(x, TILES_Y), TILE_SIZE)
	ClippedBoxStyle.fill_inside(ci, tile, 4, OfficePaint.CYAN_DARK)
	ClippedBoxStyle.fill_inside(ci, tile.grow(-2), 3, CombatScoreboard.TILE_BG)
	@warning_ignore("integer_division")
	var cx: int = x + TILE_SIZE.x / 2
	var icon: Texture2D = _icons[i]
	var icon_size: Vector2i = icon.get_size() * 2
	@warning_ignore("integer_division")
	draw_texture_rect(icon, Rect2(Vector2i(cx - icon_size.x / 2, TILES_Y + 4), icon_size), false)
	OfficePaint.text_centered(self, cx, TILES_Y + 38, UiFormat.abbreviate(roundi(_tiles[i] * grow)), OfficePaint.CYAN_LIGHT)

# "Volver" dibujado en la pantalla, como ScreenButton: solo el contorno, con un relleno tenue al pasar el ratón.
func _draw_back() -> void:
	var r: Rect2i = _back_rect()
	if _back_hovered:
		OfficePaint.rect(self, r, Color(OfficePaint.CYAN, 0.15))
	var edge: Color = OfficePaint.CYAN if _back_hovered else OfficePaint.CYAN_DARK
	draw_rect(Rect2(r).grow(-0.5), edge, false, 1.0)
	@warning_ignore("integer_division")
	OfficePaint.text_centered(self, r.get_center().x, r.position.y + (r.size.y - OfficePaint.TEXT_HEIGHT) / 2,
			tr("BTN_BACK"), OfficePaint.CYAN_LIGHT if _back_hovered else OfficePaint.CYAN)
