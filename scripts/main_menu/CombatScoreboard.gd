class_name CombatScoreboard
extends OfficeObject

# Pantalla de stats de la pared izquierda: al pulsarla, MainMenu se acerca a ella y aparece de cerca
# (StatsCloseUp). El monitor es parte de left_static.png; aquí se pinta la pantalla con los datos reales
# de GameState, todo centrado en vertical: una regla arriba, barras con las torretas más construidas
# (normalizadas a la más alta), una línea que avanza, un anillo con el reparto de lo construido por tipo
# de ataque y cinco fichas con el icono y el número de lo que se cuenta (naves destruidas, victorias,
# torretas, oleadas perfectas y naves vistas). Cada vez que la pantalla entra en la vista los datos se
# vuelven a leer y los gráficos suben desde cero; después laten. Con el ratón encima la línea va más
# deprisa y la regla se enciende. Las funciones estáticas leen los datos (las usa también StatsCloseUp).

const ICON_DIR: String = "res://assets/ui/achievements/"
const ICONS: Array[String] = ["kills", "first_win", "turrets", "perfect_waves", "seen"]
const CHART_BG: Color = Color("#0a1828")
const TILE_BG: Color = Color("#0b2132")
## Colores del anillo y su leyenda, en orden.
const RING_COLORS: Array[Color] = [OfficePaint.CYAN, OfficePaint.AMBER, OfficePaint.RED, OfficePaint.GREEN]
## Tipos de ataque con su porción en el anillo; el resto se junta en "otros".
const RING_TYPES: int = 3
## Segundos que tardan los gráficos en subir hasta su valor.
const GROW_TIME: float = 1.2
## Alto de lo que se pinta: regla (6), hueco (12), gráficas (110), hueco (12) y fichas (50).
const CONTENT_HEIGHT: int = 190
const BARS: int = 8
const BARS_WIDTH: int = 168
const TILE_WIDTH: int = 56
const TILE_STEP: int = 64

var _icons: Array[Texture2D] = []
var _screen: Rect2i
var _turrets: Array[Dictionary] = []
var _types: Array[Dictionary] = []
var _tiles: Array[int] = []
var _grow_start: float = 0.0

## Torretas base con las veces que se han construido (stats.built_<torreta>), de más a menos:
## [{data: TurretData, count: int}].
static func built_turrets() -> Array[Dictionary]:
	var turrets: Array[Dictionary] = []
	for i: int in Navedex.TURRET_FILES.size():
		var file: String = Navedex.TURRET_FILES[i]
		turrets.append({"data": load(Navedex.TURRET_DIR + file + ".tres"), "count": GameState.stats.get("built_" + file, 0), "order": i})
	turrets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.count > b.count or (a.count == b.count and a.order < b.order))
	return turrets

## Reparto de lo construido por tipo de ataque, de más a menos: los RING_TYPES primeros y el resto en
## "otros" (STATS_OTHER). [{label: clave de traducción, count: int}], sin los tipos que no tienen ninguna.
static func built_by_type(turrets: Array[Dictionary]) -> Array[Dictionary]:
	var counts: Dictionary[String, int] = {}
	for turret: Dictionary in turrets:
		var label: String = (turret.data as TurretData).get_attack_label()
		counts[label] = counts.get(label, 0) + turret.count
	var types: Array[Dictionary] = []
	for label: String in counts:
		if counts[label] > 0:
			types.append({"label": label, "count": counts[label]})
	types.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.count > b.count)
	if types.size() > RING_TYPES + 1:
		var rest: int = 0
		for type: Dictionary in types.slice(RING_TYPES):
			rest += type.count
		types = types.slice(0, RING_TYPES)
		types.append({"label": "STATS_OTHER", "count": rest})
	return types

## Números de las cinco fichas, en el orden de ICONS.
static func tile_values() -> Array[int]:
	return [GameState.stats.get("kills", 0), GameState.stats.get("wins", 0), GameState.stats.get("turrets", 0),
			GameState.stats.get("perfect_waves", 0), GameState.get_progress("seen")]

## Subida de los gráficos (de 0 a 1, frenando al final) `elapsed` segundos después de empezar.
static func grow_amount(elapsed: float) -> float:
	return 1.0 - pow(1.0 - clampf(elapsed / GROW_TIME, 0.0, 1.0), 3.0)

## Anillo con una porción por cada uno de `types` entre los radios `inner` y `outer`, girado `start` y
## dibujado hasta la parte `grow` de la vuelta. Sin datos, un anillo apagado entero.
static func draw_ring(item: CanvasItem, center: Vector2i, inner: int, outer: int, types: Array[Dictionary],
		start: float, grow: float) -> void:
	var total: int = 0
	for type: Dictionary in types:
		total += type.count
	var parts: Array[float] = []
	var colors: Array[Color] = []
	if total == 0:
		parts = [1.0]
		colors = [OfficePaint.SCREEN_LINE]
	else:
		for i: int in types.size():
			parts.append(float(types[i].count) / total * grow)
			colors.append(RING_COLORS[i])
	var gap: float = 0.08 if parts.size() > 1 else 0.0
	var step: float = 0.5 / outer
	for i: int in parts.size():
		var end: float = start + parts[i] * TAU
		var a: float = start
		while a < end - gap:
			for r: int in range(inner, outer):
				OfficePaint.rect(item, Rect2i(center.x + roundi(cos(a) * r), center.y + roundi(sin(a) * r), 1, 1), colors[i])
			a += step
		start = end

func _ready() -> void:
	super()
	var s: Array = OfficeLayout.LEFT.stats.screen
	_screen = Rect2i(Vector2i(to_local_point(Vector2(s[0], s[1]))), Vector2i(s[2], s[3]))
	for id: String in ICONS:
		_icons.append(load(ICON_DIR + id + ".png"))

func _process(delta: float) -> void:
	super(delta)
	# Mientras no se ve, se van releyendo los datos y la subida vuelve a empezar.
	if _tiles.is_empty() or not get_viewport_rect().intersects(get_global_rect()):
		_grow_start = time
		_turrets = built_turrets()
		_types = built_by_type(_turrets)
		_tiles = tile_values()

func _draw_object() -> void:
	var x0: int = _screen.position.x
	var w: int = _screen.size.x
	for y: int in range(_screen.position.y + 1, _screen.end.y, 2):
		OfficePaint.rect(self, Rect2i(x0, y, w, 1), OfficePaint.SCREEN_DARK)
	if _tiles.is_empty():
		return
	var grow: float = grow_amount(time - _grow_start)
	@warning_ignore("integer_division")
	var top: int = _screen.position.y + (_screen.size.y - CONTENT_HEIGHT) / 2
	var cx: int = x0 + 12
	var cw: int = w - 24
	var ruler: Color = OfficePaint.CYAN if hovered else OfficePaint.CYAN_DARK
	OfficePaint.rect(self, Rect2i(cx, top, cw, 2), ruler)
	for x: int in range(0, cw, 8):
		OfficePaint.rect(self, Rect2i(cx + x, top + 2, 2, 4 if x % 32 == 0 else 2), ruler)
	var cy: int = top + 18
	_draw_bars(cx, cy, grow)
	var lx: int = cx + BARS_WIDTH + 12
	_draw_wave(lx, cy, cw - BARS_WIDTH - 12)
	_draw_ring(lx, cy, grow)
	for i: int in ICONS.size():
		_draw_tile(cx + i * TILE_STEP, cy + 122, i, grow)

# Las BARS torretas más construidas, normalizadas a la más alta; una vez arriba laten un poco.
func _draw_bars(cx: int, cy: int, grow: float) -> void:
	OfficePaint.rect(self, Rect2i(cx, cy, BARS_WIDTH, 110), CHART_BG)
	OfficePaint.rect(self, Rect2i(cx, cy + 108, BARS_WIDTH, 2), OfficePaint.CYAN_DARK)
	OfficePaint.rect(self, Rect2i(cx, cy, 2, 110), OfficePaint.CYAN_DARK)
	var best: int = maxi(_turrets[0].count, 1)
	for i: int in BARS:
		var beat: float = 1.0 + sin(time * 2.0 + i * 0.8) * 0.03 * grow
		var height: int = roundi(float(_turrets[i].count) / best * 96.0 * grow * beat)
		if height <= 0:
			continue
		OfficePaint.rect(self, Rect2i(cx + 8 + i * 20, cy + 108 - height, 12, height), OfficePaint.CYAN_DARK)
		OfficePaint.rect(self, Rect2i(cx + 8 + i * 20, cy + 108 - height, 12, 2), OfficePaint.CYAN)

# Línea de 2 px que avanza por una cuadrícula (adorno: no hay datos a lo largo del tiempo).
func _draw_wave(lx: int, cy: int, lw: int) -> void:
	OfficePaint.rect(self, Rect2i(lx, cy, lw, 56), CHART_BG)
	for gy: int in range(0, 56, 14):
		OfficePaint.rect(self, Rect2i(lx, cy + gy, lw, 2), OfficePaint.SCREEN_LINE)
	var speed: float = 2.0 if hovered else 1.0
	var prev: int = -1
	for x: int in range(0, lw, 2):
		var y: int = cy + 27 + roundi(sin((x + time * 40.0 * speed) * 0.05) * 11.0 + sin((x + time * 25.0 * speed) * 0.13) * 5.0)
		if prev >= 0:
			OfficePaint.line(self, Vector2i(lx + x - 2, prev), Vector2i(lx + x, y), OfficePaint.CYAN)
			OfficePaint.line(self, Vector2i(lx + x - 2, prev + 1), Vector2i(lx + x, y + 1), OfficePaint.CYAN)
		prev = y

# Anillo con el reparto por tipo de ataque, que gira despacio, y su leyenda: una línea por tipo, tan
# larga como su parte.
func _draw_ring(lx: int, cy: int, grow: float) -> void:
	draw_ring(self, Vector2i(lx + 34, cy + 86), 16, 24, _types, time * 0.5, grow)
	var total: int = 0
	for type: Dictionary in _types:
		total += type.count
	for i: int in _types.size():
		OfficePaint.rect(self, Rect2i(lx + 72, cy + 68 + i * 10, 7, 6), RING_COLORS[i])
		OfficePaint.rect(self, Rect2i(lx + 84, cy + 70 + i * 10, maxi(2, roundi(40.0 * _types[i].count / total * grow)), 2), RING_COLORS[i])

# Ficha con el icono (a escala 1, como en el juego) en un recuadro hundido y debajo su número, que
# cuenta desde cero.
func _draw_tile(x: int, y: int, i: int, grow: float) -> void:
	var ci: RID = get_canvas_item()
	var tile: Rect2i = Rect2i(x, y, TILE_WIDTH, 50)
	ClippedBoxStyle.fill_inside(ci, tile, 4, OfficePaint.CYAN_DARK)
	ClippedBoxStyle.fill_inside(ci, tile.grow(-2), 3, TILE_BG)
	OfficePaint.rect(self, Rect2i(x + 15, y + 5, 26, 24), OfficePaint.SCREEN_LINE)
	OfficePaint.rect(self, Rect2i(x + 17, y + 7, 22, 20), OfficePaint.SCREEN_DARK)
	var icon: Texture2D = _icons[i]
	@warning_ignore("integer_division")
	draw_texture(icon, Vector2i(x + 28 - icon.get_width() / 2, y + 17 - icon.get_height() / 2))
	OfficePaint.text_centered(self, x + 28, y + 33, UiFormat.abbreviate(roundi(_tiles[i] * grow)), OfficePaint.CYAN)
