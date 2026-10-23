extends Node2D
class_name EmpSparks
# Lo que se ve sobre una torre apagada por un pulso EMP, todo en píxeles sin antialiasing:
# chispas azules en zigzag que saltan sin parar y, encima, un rayo tachado que parpadea.

const SPARK_COLORS: Array[Color] = [Color("#2a6ae6"), Color("#78bcff"), Color("#e6f6ff")]
const SPARK_COUNT := 4
# Las chispas caen dentro de la torre (32x32) y asoman un poco por los bordes.
const HALF_SIZE := 14
const BLINK_TIME := 0.25
# En los últimos FAST_BLINK_LEFT segundos el parpadeo se acelera hasta FAST_BLINK_TIME, como aviso de que vuelve.
const FAST_BLINK_TIME := 0.06
const FAST_BLINK_LEFT := 2.0

# Icono "sin energía": rayo ámbar con contorno, tachado en rojo (ver docs/design/art.md).
const ICON: Array[String] = [
	"....OOOO.",
	"...OyyYO.",
	"..OyYYO..",
	".OyYYOOO.",
	"OyYYYYYO.",
	"OOOOYYO..",
	"...OYO...",
	"..OYO....",
	".OYO.....",
	".OO......",
]
const ICON_COLORS: Dictionary[String, Color] = {
	"O": Color("#0c0e16"),
	"Y": Color("#ecb23c"),
	"y": Color("#ffe082"),
}
const SLASH_COLOR := Color("#f0323c")
# Esquina de arriba a la izquierda del icono, por encima de la torre.
const ICON_ORIGIN := Vector2(-4, -28)

var _blink := 0.0
var _icon_visible := true
# Segundos que quedan de apagada (la torre los fija con start).
var _left := 0.0

func _ready() -> void:
	z_index = 1

## Empieza (o renueva) la cuenta atrás de `seconds` segundos.
func start(seconds: float) -> void:
	_left = seconds

func _process(delta: float) -> void:
	_blink += delta
	_left = maxf(_left - delta, 0.0)
	var blink_time := lerpf(FAST_BLINK_TIME, BLINK_TIME, clampf(_left / FAST_BLINK_LEFT, 0.0, 1.0))
	if _blink >= blink_time:
		_blink = 0.0
		_icon_visible = not _icon_visible
	# Cada frame las chispas cambian de sitio.
	queue_redraw()

func _draw() -> void:
	for i: int in SPARK_COUNT:
		var point := Vector2(randi_range(-HALF_SIZE, HALF_SIZE), randi_range(-HALF_SIZE, HALF_SIZE))
		var side := 1 if randi() % 2 else -1
		var color: Color = SPARK_COLORS.pick_random()
		for step: int in randi_range(4, 7):
			draw_rect(Rect2(point, Vector2.ONE), color)
			point += Vector2(side if step % 2 else -side, 1)
	if _icon_visible:
		_draw_icon()

func _draw_icon() -> void:
	for y: int in ICON.size():
		for x: int in ICON[y].length():
			var key: String = ICON[y][x]
			if ICON_COLORS.has(key):
				draw_rect(Rect2(ICON_ORIGIN + Vector2(x, y), Vector2.ONE), ICON_COLORS[key])
	# Tachón de 2 px en diagonal, de arriba a la izquierda a abajo a la derecha.
	for x: int in ICON[0].length():
		var y := roundi(x * (ICON.size() - 1) / float(ICON[0].length() - 1))
		draw_rect(Rect2(ICON_ORIGIN + Vector2(x, y), Vector2(2, 1)), SLASH_COLOR)
