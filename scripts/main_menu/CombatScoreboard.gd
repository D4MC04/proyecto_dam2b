class_name CombatScoreboard
extends OfficeObject

# Pantalla de stats de la pared izquierda: abre el panel de estadísticas. El monitor es parte de
# left_static.png; aquí se pinta la pantalla, que no enseña datos: "// REGISTRO DE COMBATE", barras
# que suben y bajan, una línea que avanza, un anillo que gira con su leyenda y cinco fichas con el
# icono de lo que se cuenta (naves destruidas, victorias, torretas, oleadas perfectas y naves vistas).
# Líneas de 2 px. Con el ratón encima las barras van más deprisa y el título se enciende.

const ICON_DIR := "res://assets/ui/achievements/"
const ICONS: Array[String] = ["kills_100", "first_win", "turrets_50", "perfect_10", "seen_10"]
const CHART_BG := Color("#0a1828")
const TILE_BG := Color("#0b2132")
const IDLE_TEXT := Color("#1c4a60")
const SEGMENTS: Array[float] = [0.38, 0.24, 0.22, 0.16]

var _icons: Array[Texture2D] = []
var _screen: Rect2i

func _ready() -> void:
	super()
	var s: Array = OfficeLayout.LEFT.stats.screen
	_screen = Rect2i(Vector2i(to_local_point(Vector2(s[0], s[1]))), Vector2i(s[2], s[3]))
	for id in ICONS:
		_icons.append(load(ICON_DIR + id + ".png"))

func _draw_object() -> void:
	var x0 := _screen.position.x
	var y0 := _screen.position.y
	var w := _screen.size.x
	for y in range(y0 + 1, _screen.end.y, 2):
		OfficePaint.rect(self, Rect2i(x0, y, w, 1), OfficePaint.SCREEN_DARK)
	OfficePaint.text(self, Vector2i(x0 + 12, y0 + 8), "// REGISTRO DE COMBATE", OfficePaint.CYAN_LIGHT if hovered else OfficePaint.CYAN)
	OfficePaint.rect(self, Rect2i(x0 + 12, y0 + 26, w - 24, 2), OfficePaint.CYAN_DARK)
	for x in range(0, w - 24, 8):
		OfficePaint.rect(self, Rect2i(x0 + 12 + x, y0 + 28, 2, 4 if x % 32 == 0 else 2), OfficePaint.CYAN_DARK)
	var cx := x0 + 12
	var cy := y0 + 40
	_draw_bars(cx, cy)
	var lx := cx + 188
	var lw := w - 24 - 188
	_draw_wave(lx, cy, lw)
	_draw_ring(lx, cy)
	for i in ICONS.size():
		_draw_tile(cx + i * 68, cy + 122, i)
	if fmod(time, 1.0) < 0.5:
		OfficePaint.rect(self, Rect2i(x0 + 12, y0 + 248, 8, 2), OfficePaint.CYAN)
	OfficePaint.text(self, Vector2i(x0 + 24, y0 + 242), "SISTEMA EN ESPERA", IDLE_TEXT)

func _draw_bars(cx: int, cy: int) -> void:
	OfficePaint.rect(self, Rect2i(cx, cy, 176, 110), CHART_BG)
	OfficePaint.rect(self, Rect2i(cx, cy + 108, 176, 2), OfficePaint.CYAN_DARK)
	OfficePaint.rect(self, Rect2i(cx, cy, 2, 110), OfficePaint.CYAN_DARK)
	var speed := 2.2 if hovered else 0.9
	for i in 8:
		var height := 16 + roundi((sin(time * speed + i * 0.8) * 0.5 + 0.5) * 80.0)
		OfficePaint.rect(self, Rect2i(cx + 10 + i * 20, cy + 108 - height, 12, height), OfficePaint.CYAN_DARK)
		OfficePaint.rect(self, Rect2i(cx + 10 + i * 20, cy + 108 - height, 12, 2), OfficePaint.CYAN)

# Línea de 2 px que avanza por una cuadrícula.
func _draw_wave(lx: int, cy: int, lw: int) -> void:
	OfficePaint.rect(self, Rect2i(lx, cy, lw, 56), CHART_BG)
	for gy in range(0, 56, 14):
		OfficePaint.rect(self, Rect2i(lx, cy + gy, lw, 2), OfficePaint.SCREEN_LINE)
	var prev := -1
	for x in range(0, lw, 2):
		var y := cy + 27 + roundi(sin((x + time * 40.0) * 0.05) * 11.0 + sin((x + time * 25.0) * 0.13) * 5.0)
		if prev >= 0:
			OfficePaint.line(self, Vector2i(lx + x - 2, prev), Vector2i(lx + x, y), OfficePaint.CYAN)
			OfficePaint.line(self, Vector2i(lx + x - 2, prev + 1), Vector2i(lx + x, y + 1), OfficePaint.CYAN)
		prev = y

# Anillo de cuatro colores que gira, con su leyenda.
func _draw_ring(lx: int, cy: int) -> void:
	var colors: Array[Color] = [OfficePaint.CYAN, OfficePaint.AMBER, OfficePaint.RED, OfficePaint.GREEN]
	var center := Vector2i(lx + 34, cy + 86)
	var start := time * 0.5
	for i in SEGMENTS.size():
		var end := start + SEGMENTS[i] * TAU
		var a := start
		while a < end - 0.08:
			for r in range(16, 24):
				OfficePaint.rect(self, Rect2i(center.x + roundi(cos(a) * r), center.y + roundi(sin(a) * r), 1, 1), colors[i])
			a += 0.02
		start = end
		OfficePaint.rect(self, Rect2i(lx + 72, cy + 68 + i * 10, 7, 6), colors[i])
		OfficePaint.rect(self, Rect2i(lx + 84, cy + 70 + i * 10, 30 + ((i * 17) % 30), 2), OfficePaint.SCREEN_LINE)

# Ficha con el icono (a escala 1, como en el juego) en un recuadro hundido y dos líneas debajo.
func _draw_tile(x: int, y: int, i: int) -> void:
	var ci := get_canvas_item()
	var tile := Rect2i(x, y, 62, 50)
	ClippedBoxStyle.fill_inside(ci, tile, 4, OfficePaint.CYAN_DARK)
	ClippedBoxStyle.fill_inside(ci, tile.grow(-2), 3, TILE_BG)
	OfficePaint.rect(self, Rect2i(x + 18, y + 7, 26, 24), OfficePaint.SCREEN_LINE)
	OfficePaint.rect(self, Rect2i(x + 20, y + 9, 22, 20), OfficePaint.SCREEN_DARK)
	var icon := _icons[i]
	@warning_ignore("integer_division")
	draw_texture(icon, Vector2i(x + 31 - icon.get_width() / 2, y + 19 - icon.get_height() / 2))
	for j in 2:
		OfficePaint.rect(self, Rect2i(x + 10, y + 35 + j * 6, 42 - ((i * 13 + j * 17) % 24), 2), OfficePaint.CYAN_DARK if j == 0 else OfficePaint.SCREEN_LINE)
