class_name CombatScoreboard
extends OfficeObject

# Pantalla de stats de la pared izquierda: abre el panel de estadísticas. El monitor es parte de
# left_static.png; aquí se pinta la pantalla, que no enseña datos ni textos: una regla arriba, barras
# que suben y bajan, una línea que avanza, un anillo que gira con su leyenda y cinco fichas con el
# icono de lo que se cuenta (naves destruidas, victorias, torretas, oleadas perfectas y naves vistas),
# todo centrado en vertical. Líneas de 2 px. Con el ratón encima las barras van más deprisa y la regla
# se enciende.

const ICON_DIR: String = "res://assets/ui/achievements/"
const ICONS: Array[String] = ["kills", "first_win", "turrets", "perfect_waves", "seen"]
const CHART_BG: Color = Color("#0a1828")
const TILE_BG: Color = Color("#0b2132")
const SEGMENTS: Array[float] = [0.38, 0.24, 0.22, 0.16]
## Alto de lo que se pinta: regla (6), hueco (12), gráficas (110), hueco (12) y fichas (50).
const CONTENT_HEIGHT: int = 190
const BARS_WIDTH: int = 168
const TILE_WIDTH: int = 56
const TILE_STEP: int = 64

var _icons: Array[Texture2D] = []
var _screen: Rect2i

func _ready() -> void:
	super()
	var s: Array = OfficeLayout.LEFT.stats.screen
	_screen = Rect2i(Vector2i(to_local_point(Vector2(s[0], s[1]))), Vector2i(s[2], s[3]))
	for id: String in ICONS:
		_icons.append(load(ICON_DIR + id + ".png"))

func _draw_object() -> void:
	var x0: int = _screen.position.x
	var w: int = _screen.size.x
	for y: int in range(_screen.position.y + 1, _screen.end.y, 2):
		OfficePaint.rect(self, Rect2i(x0, y, w, 1), OfficePaint.SCREEN_DARK)
	@warning_ignore("integer_division")
	var top: int = _screen.position.y + (_screen.size.y - CONTENT_HEIGHT) / 2
	var cx: int = x0 + 12
	var cw: int = w - 24
	var ruler: Color = OfficePaint.CYAN if hovered else OfficePaint.CYAN_DARK
	OfficePaint.rect(self, Rect2i(cx, top, cw, 2), ruler)
	for x: int in range(0, cw, 8):
		OfficePaint.rect(self, Rect2i(cx + x, top + 2, 2, 4 if x % 32 == 0 else 2), ruler)
	var cy: int = top + 18
	_draw_bars(cx, cy)
	var lx: int = cx + BARS_WIDTH + 12
	_draw_wave(lx, cy, cw - BARS_WIDTH - 12)
	_draw_ring(lx, cy)
	for i: int in ICONS.size():
		_draw_tile(cx + i * TILE_STEP, cy + 122, i)

func _draw_bars(cx: int, cy: int) -> void:
	OfficePaint.rect(self, Rect2i(cx, cy, BARS_WIDTH, 110), CHART_BG)
	OfficePaint.rect(self, Rect2i(cx, cy + 108, BARS_WIDTH, 2), OfficePaint.CYAN_DARK)
	OfficePaint.rect(self, Rect2i(cx, cy, 2, 110), OfficePaint.CYAN_DARK)
	var speed: float = 2.2 if hovered else 0.9
	for i: int in 8:
		var height: int = 16 + roundi((sin(time * speed + i * 0.8) * 0.5 + 0.5) * 80.0)
		OfficePaint.rect(self, Rect2i(cx + 8 + i * 20, cy + 108 - height, 12, height), OfficePaint.CYAN_DARK)
		OfficePaint.rect(self, Rect2i(cx + 8 + i * 20, cy + 108 - height, 12, 2), OfficePaint.CYAN)

# Línea de 2 px que avanza por una cuadrícula.
func _draw_wave(lx: int, cy: int, lw: int) -> void:
	OfficePaint.rect(self, Rect2i(lx, cy, lw, 56), CHART_BG)
	for gy: int in range(0, 56, 14):
		OfficePaint.rect(self, Rect2i(lx, cy + gy, lw, 2), OfficePaint.SCREEN_LINE)
	var prev: int = -1
	for x: int in range(0, lw, 2):
		var y: int = cy + 27 + roundi(sin((x + time * 40.0) * 0.05) * 11.0 + sin((x + time * 25.0) * 0.13) * 5.0)
		if prev >= 0:
			OfficePaint.line(self, Vector2i(lx + x - 2, prev), Vector2i(lx + x, y), OfficePaint.CYAN)
			OfficePaint.line(self, Vector2i(lx + x - 2, prev + 1), Vector2i(lx + x, y + 1), OfficePaint.CYAN)
		prev = y

# Anillo de cuatro colores que gira, con su leyenda.
func _draw_ring(lx: int, cy: int) -> void:
	var colors: Array[Color] = [OfficePaint.CYAN, OfficePaint.AMBER, OfficePaint.RED, OfficePaint.GREEN]
	var center: Vector2i = Vector2i(lx + 34, cy + 86)
	var start: float = time * 0.5
	for i: int in SEGMENTS.size():
		var end: float = start + SEGMENTS[i] * TAU
		var a: float = start
		while a < end - 0.08:
			for r: int in range(16, 24):
				OfficePaint.rect(self, Rect2i(center.x + roundi(cos(a) * r), center.y + roundi(sin(a) * r), 1, 1), colors[i])
			a += 0.02
		start = end
		OfficePaint.rect(self, Rect2i(lx + 72, cy + 68 + i * 10, 7, 6), colors[i])
		OfficePaint.rect(self, Rect2i(lx + 84, cy + 70 + i * 10, 20 + ((i * 17) % 20), 2), OfficePaint.SCREEN_LINE)

# Ficha con el icono (a escala 1, como en el juego) en un recuadro hundido y dos líneas debajo.
func _draw_tile(x: int, y: int, i: int) -> void:
	var ci: RID = get_canvas_item()
	var tile: Rect2i = Rect2i(x, y, TILE_WIDTH, 50)
	ClippedBoxStyle.fill_inside(ci, tile, 4, OfficePaint.CYAN_DARK)
	ClippedBoxStyle.fill_inside(ci, tile.grow(-2), 3, TILE_BG)
	OfficePaint.rect(self, Rect2i(x + 15, y + 7, 26, 24), OfficePaint.SCREEN_LINE)
	OfficePaint.rect(self, Rect2i(x + 17, y + 9, 22, 20), OfficePaint.SCREEN_DARK)
	var icon: Texture2D = _icons[i]
	@warning_ignore("integer_division")
	draw_texture(icon, Vector2i(x + 28 - icon.get_width() / 2, y + 19 - icon.get_height() / 2))
	for j: int in 2:
		OfficePaint.rect(self, Rect2i(x + 8, y + 35 + j * 6, 40 - ((i * 13 + j * 17) % 24), 2), OfficePaint.CYAN_DARK if j == 0 else OfficePaint.SCREEN_LINE)
