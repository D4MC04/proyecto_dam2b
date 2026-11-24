extends OverlayScreen
class_name VictoryScreen

# Pantalla de victoria ("sector asegurado"): el marco entra deslizando desde arriba mientras se
# funde el oscurecido. Un clic en el área de juego (fuera de los botones) salta la entrada. Bajo el
# título van las estrellas, que se encienden una a una al llegar el marco.
# Corre con el árbol en pausa (hereda process_mode ALWAYS de LevelUI), así que va en tiempo real.

# Duración del fundido del oscurecido, a la vez que la entrada.
const DIM_FADE_TIME: float = 0.2
# Duración total de la entrada: el marco baja hasta pasarse SLIDE_OVERSHOOT_PX px de su sitio
# y en los últimos SLIDE_SETTLE_TIME s vuelve a él.
const SLIDE_TIME: float = 0.35
const SLIDE_SETTLE_TIME: float = 0.08
const SLIDE_OVERSHOOT_PX: float = 2.0

# Estrellas bajo el título: pixel art de STAR_SHAPE ('#' es la silueta). El contorno, las luces y
# las sombras se sacan de la silueta en _build_star(). La del centro es mayor y va más arriba.
const STAR_SHAPE: Array[String] = [
	"......###......",
	".....#####.....",
	".....#####.....",
	"###############",
	"###############",
	".#############.",
	"..###########..",
	"...#########...",
	"...#########...",
	"..####...####..",
	"..###.....###..",
	".###.......###.",
	".##.........##.",
]
const STAR_PIXEL: int = 4
const STAR_CENTER_PIXEL: int = 5
const STAR_GAP: int = 12
# Cuánto más abajo van las estrellas de los lados que la del centro, y hueco arriba para el salto.
const STAR_SIDE_DROP: int = 8
const STAR_TOP_MARGIN: int = 8
# Salto de una estrella al encenderse, en píxeles, y duración total del encendido.
const STAR_JUMP_PX: float = 8.0
const STAR_LIGHT_TIME: float = 0.4
# Tramo inicial del encendido en que la estrella se ve toda blanca.
const STAR_FLASH_PORTION: float = 0.25
# Pausa antes de la primera estrella (tras llegar el marco) y entre una y la siguiente.
const STAR_FIRST_DELAY: float = 0.2
const STAR_STEP_DELAY: float = 0.25

# Colores de cada tipo de píxel: encendida, apagada y destello.
const STAR_LIT_COLORS: Dictionary = {
	"o": Color("#6e440c"),
	"h": Color("#ffe082"),
	"f": Color("#ecb23c"),
	"s": Color("#b87a1c"),
	"w": Color("#fff4c8"),
}
const STAR_EMPTY_COLORS: Dictionary = {
	"o": Color("#4a3410"),
	"h": Color("#2e2108"),
	"f": Color("#241907"),
	"s": Color("#1c1405"),
	"w": Color("#2e2108"),
}
const STAR_FLASH_COLOR: Color = Color("#fff4c8")

@onready var stars_row: Control = %StarsRow
@onready var center: CenterContainer = $Center

# Entrada en curso (deslizamiento y fundido); null si no hay.
var _intro: Tween
# Estrellas ganadas en esta victoria (0..GameState.MAX_STARS).
var _stars: int = 0
# Progreso del encendido de cada estrella (0 apagada, 1 encendida del todo).
var _star_light: Array[float] = []
# Tipo de cada píxel de la silueta ('.', 'o', 'h', 'f', 's' o 'w'), por filas.
var _star_cells: Array[String] = []

func _ready() -> void:
	super()
	title_label.add_theme_color_override("font_color", accent_color)
	_star_cells = _build_star()
	_star_light.resize(GameState.MAX_STARS)
	_star_light.fill(0.0)
	stars_row.draw.connect(_draw_stars)
	# El oscurecido cubre el área de juego; el marco para los clics que caen encima.
	for area: Control in [background, frame]:
		area.gui_input.connect(_on_area_gui_input)
	visibility_changed.connect(_on_visibility_changed)

## Estrellas ganadas en esta victoria. Se llama antes de mostrar la pantalla.
func set_stars(stars: int) -> void:
	_stars = stars
	_set_all_lit()

# Saca de la silueta el tipo de cada píxel: contorno donde toca el vacío, luz arriba a la izquierda,
# sombra abajo a la derecha y un par de brillos.
func _build_star() -> Array[String]:
	var height: int = STAR_SHAPE.size()
	var width: int = STAR_SHAPE[0].length()
	var cells: Array[String] = []
	for y: int in height:
		var line: String = ""
		for x: int in width:
			line += _star_cell(x, y, width, height)
		cells.append(line)
	return cells

func _star_cell(x: int, y: int, width: int, height: int) -> String:
	if not _is_star_pixel(x, y):
		return "."
	for neighbour: Vector2i in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
		if not _is_star_pixel(neighbour.x, neighbour.y):
			return "o"
	# Brillos fijos en la zona de luz.
	if (x == 6 and y == 2) or (x == 3 and y == 4):
		return "w"
	var light: int = (x - int(width / 2.0)) + (y - int(height / 2.0))
	if light <= -3:
		return "h"
	if light >= 4:
		return "s"
	return "f"

func _is_star_pixel(x: int, y: int) -> bool:
	return y >= 0 and y < STAR_SHAPE.size() and x >= 0 and x < STAR_SHAPE[y].length() and STAR_SHAPE[y][x] == "#"

# Pinta las tres estrellas centradas: la del centro, mayor y más arriba.
func _draw_stars() -> void:
	var side_width: int = STAR_SHAPE[0].length() * STAR_PIXEL
	var center_width: int = STAR_SHAPE[0].length() * STAR_CENTER_PIXEL
	var total_width: int = side_width * 2 + center_width + STAR_GAP * 2
	var left: float = roundf((stars_row.size.x - total_width) / 2.0)
	var center_height: int = STAR_SHAPE.size() * STAR_CENTER_PIXEL
	# La fila mide lo justo para la estrella central y su salto; se centra en vertical.
	var top: float = roundf((stars_row.size.y - center_height - STAR_TOP_MARGIN) / 2.0) + STAR_TOP_MARGIN
	var x_offsets: Array[float] = [left, left + side_width + STAR_GAP, left + side_width + STAR_GAP * 2 + center_width]
	_draw_star(0, Vector2(x_offsets[0], top + STAR_SIDE_DROP), STAR_PIXEL)
	_draw_star(1, Vector2(x_offsets[1], top), STAR_CENTER_PIXEL)
	_draw_star(2, Vector2(x_offsets[2], top + STAR_SIDE_DROP), STAR_PIXEL)

# Una estrella: apagada si no se ha ganado, blanca al empezar a encenderse y después ámbar con salto.
func _draw_star(index: int, origin: Vector2, pixel: int) -> void:
	var earned: bool = index < _stars
	var progress: float = _star_light[index] if earned else 0.0
	var flash: bool = earned and progress > 0.0 and progress < STAR_FLASH_PORTION
	var palette: Dictionary = STAR_LIT_COLORS if earned and progress >= STAR_FLASH_PORTION else STAR_EMPTY_COLORS
	var jump: float = 0.0
	if earned and progress > 0.0 and progress < 1.0:
		jump = roundf(sin(progress * PI) * STAR_JUMP_PX)
	origin.y -= jump
	for row: int in _star_cells.size():
		for column: int in _star_cells[row].length():
			var kind: String = _star_cells[row][column]
			if kind == ".":
				continue
			var color: Color = STAR_FLASH_COLOR if flash else (palette[kind] as Color)
			stars_row.draw_rect(Rect2(origin + Vector2(column, row) * pixel, Vector2.ONE * pixel), color)

func _on_visibility_changed() -> void:
	# Cada vez que se abre, la entrada empieza de cero; al cerrarse se deja en su sitio.
	if is_visible_in_tree():
		_start_intro()
	else:
		_finish_intro()

func _start_intro() -> void:
	if _intro != null:
		_intro.kill()
	# Desde donde el marco (centrado), con sus corchetes, queda justo encima del área de juego.
	var area_height: float = size.y if size.y > 0.0 else get_viewport_rect().size.y
	var start_y: float = -roundf((area_height + frame.get_combined_minimum_size().y) / 2.0) - OverlayFrame.OUTSIDE_MARGIN
	_set_slide(start_y)
	background.modulate.a = 0.0
	_star_light.fill(0.0)
	stars_row.queue_redraw()
	_intro = create_tween().set_ignore_time_scale()
	_intro.tween_property(background, "modulate:a", 1.0, DIM_FADE_TIME)
	_intro.parallel().tween_method(_set_slide, start_y, SLIDE_OVERSHOOT_PX, SLIDE_TIME - SLIDE_SETTLE_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro.tween_method(_set_slide, SLIDE_OVERSHOOT_PX, 0.0, SLIDE_SETTLE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Las estrellas ganadas se encienden una tras otra cuando el marco ya está en su sitio.
	for index: int in _stars:
		_intro.parallel().tween_method(_set_star_light.bind(index), 0.0, 1.0, STAR_LIGHT_TIME) \
				.set_delay(STAR_FIRST_DELAY + index * STAR_STEP_DELAY)
	_intro.tween_callback(func() -> void: _intro = null)

# Corta la entrada y deja el panel y las estrellas en su estado final.
func _finish_intro() -> void:
	if _intro != null:
		_intro.kill()
		_intro = null
	background.modulate.a = 1.0
	_set_slide(0.0)
	_set_all_lit()

func _set_all_lit() -> void:
	for index: int in _star_light.size():
		_star_light[index] = 1.0
	stars_row.queue_redraw()

func _set_star_light(progress: float, index: int) -> void:
	_star_light[index] = progress
	stars_row.queue_redraw()

# Desplazamiento vertical del marco respecto a su sitio, en píxeles enteros para que no tiemble.
func _set_slide(offset_y: float) -> void:
	center.position.y = roundf(offset_y)

func _on_area_gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if _intro != null:
		_finish_intro()
		accept_event()
