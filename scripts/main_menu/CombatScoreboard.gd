class_name CombatScoreboard
extends OfficeObject

# Marcador de combate en la pared: abre las estadísticas. Pantalla con contadores de siete
# segmentos en ámbar (bajas, victorias y torretas construidas, de GameState.stats) y una fila de
# barras de actividad. Con el ratón encima los dígitos brillan más y las barras van más rápido.

const FRAME := Rect2i(0, 0, 380, 236)
const SCREEN_RECT := Rect2i(8, 8, 364, 220)
const SCREEN_LIGHT := Color("#0d0b0a")
const SCREEN_DARK := Color("#090807")
const TITLE := "REGISTRO DE COMBATE"
# Filas: [rótulo, clave de GameState.stats].
const ROWS: Array[Array] = [["BAJAS", "kills"], ["VICTORIAS", "wins"], ["TORRETAS", "turrets"]]
const ROW_TOP := 50
const ROW_STEP := 48
const LABEL_X := 24
# Dígitos de siete segmentos: cantidad, tamaño, grosor del segmento y separación.
const DIGITS := 6
const DIGIT_SIZE := Vector2i(18, 32)
const SEGMENT := 3
const DIGIT_GAP := 6
const DIGITS_X := 196
# Segmento apagado (se intuye el 8) y encendidos.
const SEGMENT_OFF := Color("#2a2014")
# Segmentos de cada cifra: a (arriba), b (arriba der.), c (abajo der.), d (abajo), e (abajo izq.), f (arriba izq.), g (centro).
const DIGIT_SEGMENTS: Array[String] = [
	"abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg",
]
const BAR_COUNT := 48
const BARS_BOTTOM := 216

var _values: Array[int] = []

func _ready() -> void:
	super()
	for row in ROWS:
		_values.append(mini(int(GameState.stats.get(row[1], 0)), 999999))

func _draw_object() -> void:
	OfficePaint.metal_box(self, FRAME)
	for corner: Vector2i in [Vector2i(2, 2), Vector2i(375, 2), Vector2i(2, 231), Vector2i(375, 231)]:
		OfficePaint.screw(self, corner)
	OfficePaint.screen(self, SCREEN_RECT, SCREEN_LIGHT, SCREEN_DARK)
	var lit := OfficePaint.AMBER_LIGHT if hovered else OfficePaint.AMBER
	@warning_ignore("integer_division")
	OfficePaint.text_centered(self, FRAME.size.x / 2, 14, TITLE, lit)
	ScreenHeader.draw_ruler(self, Vector2i(20, 30), FRAME.size.x - 40, OfficePaint.AMBER_DARK)
	for i in ROWS.size():
		var top := ROW_TOP + i * ROW_STEP
		OfficePaint.text(self, Vector2i(LABEL_X, top + 10), ROWS[i][0], OfficePaint.AMBER_DARK if not hovered else OfficePaint.AMBER)
		_draw_number(_values[i], Vector2i(DIGITS_X, top), lit)
	_draw_bars()

# Número con ceros delante apagados, de derecha a izquierda.
func _draw_number(value: int, at: Vector2i, lit: Color) -> void:
	var text := str(value)
	for i in DIGITS:
		var from_right := DIGITS - 1 - i
		var digit_at := at + Vector2i(i * (DIGIT_SIZE.x + DIGIT_GAP), 0)
		var segments := ""
		if from_right < text.length():
			segments = DIGIT_SEGMENTS[int(text[text.length() - 1 - from_right])]
		_draw_digit(digit_at, segments, lit)

func _draw_digit(at: Vector2i, segments: String, lit: Color) -> void:
	var w := DIGIT_SIZE.x
	@warning_ignore("integer_division")
	var half := DIGIT_SIZE.y / 2
	var t := SEGMENT
	var shapes := {
		"a": Rect2i(t, 0, w - t * 2, t),
		"b": Rect2i(w - t, t, t, half - t),
		"c": Rect2i(w - t, half + 1, t, half - t - 1),
		"d": Rect2i(t, DIGIT_SIZE.y - t, w - t * 2, t),
		"e": Rect2i(0, half + 1, t, half - t - 1),
		"f": Rect2i(0, t, t, half - t),
		"g": Rect2i(t, half - 1, w - t * 2, t),
	}
	for key: String in shapes:
		var r: Rect2i = shapes[key]
		OfficePaint.rect(self, Rect2i(r.position + at, r.size), lit if key in segments else SEGMENT_OFF)

# Barras de actividad que suben y bajan, en ámbar oscuro con la punta encendida.
func _draw_bars() -> void:
	var speed := 4.0 if hovered else 1.5
	for i in BAR_COUNT:
		var wave := sin(time * speed + i * 0.45) * 0.5 + sin(time * speed * 0.6 + i * 1.3) * 0.5
		var height := 2 + int((wave * 0.5 + 0.5) * 10.0)
		var bar := Rect2i(24 + i * 7, BARS_BOTTOM - height, 5, height)
		OfficePaint.rect(self, bar, OfficePaint.AMBER_DARK)
		OfficePaint.rect(self, Rect2i(bar.position, Vector2i(5, 1)), OfficePaint.AMBER)
