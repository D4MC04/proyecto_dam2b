extends Control
class_name ScannerDisplay
## Radar de reposo de la ficha. Los frames del barrido se pintan píxel a píxel en una Image
## (sin antialiasing) una sola vez y se reparten entre todas las instancias.

const SIZE := 57
const RADIUS := 27
const CENTER := 28
const FRAME_COUNT := 32
const FRAME_TIME := 0.06
# Radios de los anillos interiores, punteados.
const INNER_RINGS: Array[int] = [9, 18]
# Estela detrás de la línea de barrido, por tramos: hasta cuántos grados y de qué color.
const TRAIL_BANDS: Array[float] = [25.0, 70.0]
const TRAIL_COLORS: Array[Color] = [Color("#1c7496"), Color("#14304a")]
# Ecos sueltos (radio, grados) que se encienden al pasar el barrido y se apagan.
const ECHOES: Array[Vector2] = [Vector2(20, 35), Vector2(12, 160), Vector2(23, 250), Vector2(6, 300)]
const ECHO_BRIGHT_ANGLE := 40.0
const ECHO_DIM_ANGLE := 110.0

const DISC_COLOR := Color("#0e1626")
const GRID_COLOR := Color("#1c4a60")
const RING_COLOR := Color("#1c7496")
const TICK_COLOR := Color("#40e0f0")
const SWEEP_COLOR := Color("#befaff")
const ECHO_BRIGHT_COLOR := Color("#befaff")
const ECHO_DIM_COLOR := Color("#40e0f0")

static var _frames: Array[ImageTexture] = []

var _time := 0.0
var _frame := 0

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	if _frames.is_empty():
		for i in FRAME_COUNT:
			_frames.append(ImageTexture.create_from_image(_paint_frame(360.0 * i / FRAME_COUNT)))

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var frame := int(_time / FRAME_TIME) % FRAME_COUNT
	if frame != _frame:
		_frame = frame
		queue_redraw()

func _draw() -> void:
	# Posición entera para que cada píxel caiga en un píxel de pantalla.
	draw_texture(_frames[_frame], ((size - Vector2(SIZE, SIZE)) / 2.0).floor())

## Pinta un frame con la línea de barrido en `sweep` grados (0 = derecha, en sentido horario).
static func _paint_frame(sweep: float) -> Image:
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var offset := Vector2(x - CENTER, y - CENTER)
			var distance := roundi(offset.length())
			if distance > RADIUS:
				continue
			var color := DISC_COLOR
			var behind := _degrees_behind(sweep, offset)
			for band in TRAIL_BANDS.size():
				if behind <= TRAIL_BANDS[band]:
					color = TRAIL_COLORS[band]
					break
			# Anillos y cruz punteados.
			var dotted := (x + y) % 2 == 0
			if dotted and (INNER_RINGS.has(distance) or offset.x == 0 or offset.y == 0):
				color = GRID_COLOR
			if distance == RADIUS:
				color = RING_COLOR
			image.set_pixelv(Vector2i(x, y), color)
	# Marcas en los cuatro puntos cardinales, por fuera del anillo.
	for direction: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		image.set_pixelv(Vector2i(CENTER, CENTER) + direction * (RADIUS + 1), TICK_COLOR)
	# Ecos: brillantes justo después de que pase el barrido, luego tenues y al final apagados.
	for echo in ECHOES:
		var point := Vector2.RIGHT.rotated(deg_to_rad(echo.y)) * echo.x
		var behind := _degrees_behind(sweep, point)
		var pixel := Vector2i(CENTER, CENTER) + Vector2i(point.round())
		if behind <= ECHO_BRIGHT_ANGLE:
			image.set_pixelv(pixel, ECHO_BRIGHT_COLOR)
		elif behind <= ECHO_DIM_ANGLE:
			image.set_pixelv(pixel, ECHO_DIM_COLOR)
	# Línea de barrido del centro al anillo.
	var tip := Vector2.RIGHT.rotated(deg_to_rad(sweep)) * (RADIUS - 1)
	for step in RADIUS * 2:
		var point := tip * step / float(RADIUS * 2 - 1)
		image.set_pixelv(Vector2i(CENTER, CENTER) + Vector2i(point.round()), SWEEP_COLOR)
	return image

## Grados que lleva por detrás de la línea de barrido el punto `offset` (0 = encima, 359 = a punto de llegar).
static func _degrees_behind(sweep: float, offset: Vector2) -> float:
	return fposmod(sweep - rad_to_deg(offset.angle()), 360.0)
