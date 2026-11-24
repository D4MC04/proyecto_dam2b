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

# Estrellas bajo el título: gemas facetadas de cinco puntas, hechas con polígonos de vértices enteros
# (sin antialiasing). La del centro es mayor y va más arriba que las de los lados. Cada punta se
# parte en dos caras que reciben la luz (arriba a la izquierda) de forma distinta.
const STAR_RADIUS: float = 29.0
const STAR_CENTER_RADIUS: float = 36.0
# Radio de los vértices de dentro respecto al de las puntas.
const STAR_INNER_RATIO: float = 0.45
const STAR_GAP: int = 14
# Cuánto más abajo van las estrellas de los lados que la del centro.
const STAR_SIDE_DROP: int = 8
# Grosor del borde claro de las encendidas y del trazo de las apagadas.
const STAR_RIM_WIDTH: float = 2.0
# Salto de una estrella al encenderse, en píxeles, y duración total del encendido.
const STAR_JUMP_PX: float = 8.0
const STAR_LIGHT_TIME: float = 0.4
# Tramo inicial del encendido en que la estrella se ve toda blanca.
const STAR_FLASH_PORTION: float = 0.25
# Pausa antes de la primera estrella (tras llegar el marco) y entre una y la siguiente.
const STAR_FIRST_DELAY: float = 0.2
const STAR_STEP_DELAY: float = 0.25
# Dirección de la luz (hacia donde mira la cara más iluminada) y umbrales de cara clara y oscura.
const STAR_LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)
const STAR_BRIGHT_THRESHOLD: float = 0.35
const STAR_DARK_THRESHOLD: float = -0.35
# Colores de la gema encendida (rampa ámbar de art.md), el destello y la apagada (como la ficha).
const STAR_BRIGHT_COLOR: Color = Color("#ffe082")
const STAR_MID_COLOR: Color = Color("#ecb23c")
const STAR_DARK_COLOR: Color = Color("#b87a1c")
const STAR_RIM_COLOR: Color = Color("#fff4c8")
const STAR_FLASH_COLOR: Color = Color("#fff4c8")
const STAR_EMPTY_FILL_COLORS: Array[Color] = [Color("#0b2132"), Color("#122c42")]
const STAR_EMPTY_RIM_COLOR: Color = Color("#3a5a78")

@onready var stars_row: Control = %StarsRow
@onready var center: CenterContainer = $Center

# Entrada en curso (deslizamiento y fundido); null si no hay.
var _intro: Tween
# Estrellas ganadas en esta victoria (0..GameState.MAX_STARS).
var _stars: int = 0
# Progreso del encendido de cada estrella (0 apagada, 1 encendida del todo).
var _star_light: Array[float] = []

func _ready() -> void:
	super()
	title_label.add_theme_color_override("font_color", accent_color)
	# La fila mide lo que la estrella central más el hueco que el título deja bajo sus letras, para que
	# la estrella quede igual de separada del título que del botón.
	var font: Font = title_label.get_theme_font("font")
	var title_gap: float = font.get_descent(title_label.get_theme_font_size("font_size"))
	stars_row.custom_minimum_size.y = _star_height(STAR_CENTER_RADIUS) + roundf(title_gap)
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

# Alto y ancho de una estrella de radio `radius`.
func _star_height(radius: float) -> float:
	return roundf(radius * (1.0 + cos(deg_to_rad(36.0))))

func _star_width(radius: float) -> float:
	return roundf(2.0 * radius * sin(deg_to_rad(72.0)))

# Pinta las tres estrellas centradas: la del centro, mayor y más arriba.
func _draw_stars() -> void:
	var side_width: float = _star_width(STAR_RADIUS)
	var center_width: float = _star_width(STAR_CENTER_RADIUS)
	var total_width: float = side_width * 2.0 + center_width + STAR_GAP * 2
	var left: float = roundf((stars_row.size.x - total_width) / 2.0)
	_draw_star(0, Vector2(left + side_width / 2.0, STAR_SIDE_DROP), STAR_RADIUS)
	_draw_star(1, Vector2(left + side_width + STAR_GAP + center_width / 2.0, 0.0), STAR_CENTER_RADIUS)
	_draw_star(2, Vector2(left + side_width + STAR_GAP * 2 + center_width + side_width / 2.0, STAR_SIDE_DROP), STAR_RADIUS)

# Una estrella con su punta de arriba en `top_center`: apagada si no se ha ganado, blanca al empezar
# a encenderse y después una gema ámbar con salto.
func _draw_star(index: int, top_center: Vector2, radius: float) -> void:
	var earned: bool = index < _stars
	var progress: float = _star_light[index] if earned else 0.0
	var flash: bool = earned and progress > 0.0 and progress < STAR_FLASH_PORTION
	var lit: bool = earned and progress >= STAR_FLASH_PORTION
	var jump: float = 0.0
	if earned and progress > 0.0 and progress < 1.0:
		jump = roundf(sin(progress * PI) * STAR_JUMP_PX)
	var center_point: Vector2 = Vector2(roundf(top_center.x), roundf(top_center.y + radius - jump))
	var outer: Array[Vector2] = []
	var inner: Array[Vector2] = []
	for point: int in 5:
		var outer_angle: float = deg_to_rad(-90.0 + 72.0 * point)
		var inner_angle: float = outer_angle + deg_to_rad(36.0)
		outer.append(center_point + (Vector2.from_angle(outer_angle) * radius).round())
		inner.append(center_point + (Vector2.from_angle(inner_angle) * radius * STAR_INNER_RATIO).round())
	# Cada punta tiene dos caras: la de su lado izquierdo (hasta el vértice de dentro anterior) y
	# la de su lado derecho (hasta el siguiente).
	for point: int in 5:
		var previous_inner: int = posmod(point - 1, 5)
		_draw_facet(center_point, outer[point], inner[previous_inner], inner[previous_inner] - center_point, lit, flash, point * 2)
		_draw_facet(center_point, outer[point], inner[point], inner[point] - center_point, lit, flash, point * 2 + 1)
	var outline: PackedVector2Array = PackedVector2Array()
	for point: int in 5:
		outline.append(outer[point])
		outline.append(inner[point])
	outline.append(outer[0])
	var rim: Color = STAR_FLASH_COLOR if flash else (STAR_RIM_COLOR if lit else STAR_EMPTY_RIM_COLOR)
	stars_row.draw_polyline(outline, rim, STAR_RIM_WIDTH)

# Una cara triangular. La luz la decide hacia dónde se inclina (`tilt`: dirección del vértice de dentro).
func _draw_facet(center_point: Vector2, outer_point: Vector2, inner_point: Vector2, tilt: Vector2, lit: bool, flash: bool, facet_index: int) -> void:
	var color: Color
	if flash:
		color = STAR_FLASH_COLOR
	elif lit:
		var shade: float = tilt.normalized().dot(STAR_LIGHT_DIR.normalized())
		if shade >= STAR_BRIGHT_THRESHOLD:
			color = STAR_BRIGHT_COLOR
		elif shade >= STAR_DARK_THRESHOLD:
			color = STAR_MID_COLOR
		else:
			color = STAR_DARK_COLOR
	else:
		color = STAR_EMPTY_FILL_COLORS[facet_index % 2]
	stars_row.draw_colored_polygon(PackedVector2Array([center_point, outer_point, inner_point]), color)

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
