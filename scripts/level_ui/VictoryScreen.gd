extends OverlayScreen
class_name VictoryScreen

# Pantalla de victoria ("sector asegurado"): el marco entra deslizando desde arriba mientras se
# funde el oscurecido. Un clic en el área de juego (fuera de los botones) salta la entrada. Bajo el
# título van las estrellas, que se encienden una a una al llegar el marco. Si la victoria desbloquea algo,
# el botón dice "Siguiente" y, dentro del mismo marco, enseña cada desbloqueo (tipo, icono, nombre y
# frase); en el último dice "Oficina" y ya lleva a la oficina.
# Corre con el árbol en pausa (hereda process_mode ALWAYS de LevelUI), así que va en tiempo real.

# Duración del fundido del oscurecido, a la vez que la entrada.
const DIM_FADE_TIME: float = 0.2
# Duración total de la entrada: el marco baja hasta pasarse SLIDE_OVERSHOOT_PX px de su sitio
# y en los últimos SLIDE_SETTLE_TIME s vuelve a él.
const SLIDE_TIME: float = 0.35
const SLIDE_SETTLE_TIME: float = 0.08
const SLIDE_OVERSHOOT_PX: float = 2.0

# Estrellas bajo el título: hologramas de cinco puntas, como los de la oficina. Son un contorno con
# cuerpo translúcido y líneas de barrido que suben despacio; las que faltan son un contorno apagado.
# Polígonos de vértices enteros, sin antialiasing. La del centro es mayor y va más arriba.
const STAR_RADIUS: float = 29.0
const STAR_CENTER_RADIUS: float = 36.0
# Radio de los vértices de dentro respecto al de las puntas.
const STAR_INNER_RATIO: float = 0.45
const STAR_GAP: int = 14
# Cuánto más abajo van las estrellas de los lados que la del centro.
const STAR_SIDE_DROP: int = 8
# Grosor del contorno y del resplandor que lo rodea en las encendidas.
const STAR_RIM_WIDTH: float = 2.0
const STAR_GLOW_WIDTH: float = 6.0
# Opacidad del cuerpo, de las líneas de barrido y del resplandor de las encendidas.
const STAR_BODY_ALPHA: float = 0.14
const STAR_SCAN_ALPHA: float = 0.55
const STAR_GLOW_ALPHA: float = 0.22
# Líneas de barrido: cada cuántos píxeles, grosor y velocidad a la que suben (px/s).
const STAR_SCAN_STEP: int = 4
const STAR_SCAN_THICKNESS: int = 2
const STAR_SCAN_SPEED: float = 10.0
# Parpadeo suave del holograma: cuánto baja su brillo y a qué ritmo.
const STAR_FLICKER_DEPTH: float = 0.08
const STAR_FLICKER_RATE: float = 9.0
# Encendido de una estrella, como si el holograma se proyectara: sale de arriba abajo línea a línea
# (con un frente brillante), parpadea y se descuadra un poco hasta estabilizarse. Duración total,
# parte de ella que tarda el barrido y momento (0..1) desde el que ya no parpadea.
const STAR_LIGHT_TIME: float = 0.7
const STAR_REVEAL_PORTION: float = 0.6
const STAR_STABLE_AT: float = 0.85
# Pasos de parpadeo durante el encendido, probabilidad de que un paso se apague y brillo de esos pasos.
const STAR_FLICKER_STEPS: int = 28
const STAR_FLICKER_OFF_CHANCE: float = 0.4
const STAR_FLICKER_DIM: float = 0.25
# Desplazamiento máximo en píxeles de las líneas descuadradas al empezar (baja hasta 0).
const STAR_GLITCH_PX: float = 4.0
# Probabilidad de que una línea se descuadre en un momento dado.
const STAR_GLITCH_CHANCE: float = 0.25
# Pausa antes de la primera estrella (tras llegar el marco) y entre una y la siguiente.
const STAR_FIRST_DELAY: float = 0.2
const STAR_STEP_DELAY: float = 0.35
# Colores: holograma ámbar (rampa de art.md), destello y contorno apagado (como la ficha).
const STAR_HOLO_COLOR: Color = Color("#ecb23c")
const STAR_RIM_COLOR: Color = Color("#ffe082")
# Frente brillante del barrido de encendido.
const STAR_FRONT_COLOR: Color = Color("#fff4c8")
const STAR_EMPTY_COLOR: Color = Color("#3a5a78")
const STAR_EMPTY_BODY_ALPHA: float = 0.10

# Páginas de desbloqueo: cada una entra con este fundido. El icono se amplía en enteros hasta caber en
# ICON_BOX px de lado.
const PAGE_FADE_TIME: float = 0.2
const ICON_BOX: int = 96
# Texto del botón mientras queda algo por ver y al final.
const NEXT_KEY: String = "BTN_NEXT"
const LAST_KEY: String = "BTN_MENU"

@onready var stars_row: Control = %StarsRow
@onready var center: CenterContainer = $Center
@onready var unlock_page: VBoxContainer = %UnlockPage
@onready var kind_label: Label = %KindLabel
@onready var icon_frame: OverlayFrame = %IconFrame
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel

# Entrada en curso (deslizamiento y fundido); null si no hay.
var _intro: Tween
# Estrellas ganadas en esta victoria (0..GameState.MAX_STARS).
var _stars: int = 0
# Progreso del encendido de cada estrella (0 apagada, 1 encendida del todo).
var _star_light: Array[float] = []
# Tiempo en segundos desde que se abrió la pantalla; mueve el barrido y el parpadeo.
var _time: float = 0.0
# Desbloqueos de esta victoria, en orden.
var _unlocks: Array[UnlockInfo] = []
# Página que se ve: 0 la victoria con sus estrellas; desde 1, el desbloqueo `_page - 1`.
var _page: int = 0
# Fundido de entrada de la página de desbloqueo; null si no hay.
var _page_fade: Tween

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
	set_process(is_visible_in_tree())

## Estrellas ganadas en esta victoria. Se llama antes de mostrar la pantalla.
func set_stars(stars: int) -> void:
	_stars = stars
	_set_all_lit()

## Lo que desbloquea esta victoria, en orden (vacío si nada). Se llama antes de mostrar la pantalla.
func set_unlocks(unlocks: Array[UnlockInfo]) -> void:
	_unlocks = unlocks
	_show_page(0)

# "Siguiente" pasa a la página siguiente; en la última, el botón ya elige la opción (Oficina).
func _on_option_pressed(option: Option) -> void:
	if option == Option.QUIT and _page < _unlocks.size():
		_finish_intro()
		_show_page(_page + 1)
		return
	super(option)

# Enseña la victoria (página 0) o un desbloqueo, sin cambiar el marco: solo cambia su contenido.
func _show_page(page: int) -> void:
	_page = page
	var victory: bool = page == 0
	title_label.visible = victory
	stars_row.visible = victory
	unlock_page.visible = not victory
	set_option_text(Option.QUIT, NEXT_KEY if page < _unlocks.size() else LAST_KEY)
	if _page_fade != null:
		_page_fade.kill()
		_page_fade = null
	unlock_page.modulate.a = 1.0
	if victory:
		frame.custom_minimum_size.x = 0.0
		return
	# El marco no encoge al pasar de la victoria a los desbloqueos.
	frame.custom_minimum_size.x = maxf(frame.custom_minimum_size.x, frame.size.x)
	var info: UnlockInfo = _unlocks[page - 1]
	kind_label.text = tr(info.kind_key)
	kind_label.add_theme_color_override(&"font_color", info.accent)
	icon_frame.accent_color = info.accent
	name_label.text = info.title
	text_label.text = info.text
	text_label.visible = not info.text.is_empty()
	_set_icon(info.icon)
	icon_rect.modulate = info.icon_tint
	unlock_page.modulate.a = 0.0
	_page_fade = create_tween().set_ignore_time_scale()
	_page_fade.tween_property(unlock_page, "modulate:a", 1.0, PAGE_FADE_TIME)

# Icono en píxeles: se amplía en enteros (sin emborronar) hasta caber en ICON_BOX.
func _set_icon(texture: Texture2D) -> void:
	icon_rect.texture = texture
	if texture == null:
		icon_rect.custom_minimum_size = Vector2.ONE * ICON_BOX
		return
	var side: int = maxi(texture.get_width(), texture.get_height())
	var factor: int = maxi(1, ICON_BOX / maxi(side, 1))
	icon_rect.custom_minimum_size = Vector2(texture.get_size()) * factor

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

# Una estrella con su punta de arriba en `top_center`: apagada si no se ha ganado; si se ha ganado,
# el holograma se proyecta (`_star_light`, 0..1) y queda encendido.
func _draw_star(index: int, top_center: Vector2, radius: float) -> void:
	var progress: float = _star_light[index] if index < _stars else 0.0
	var center_point: Vector2 = Vector2(roundf(top_center.x), roundf(top_center.y + radius))
	# Vértices de la estrella: punta, vértice de dentro, punta...
	var points: PackedVector2Array = PackedVector2Array()
	for point: int in 5:
		var outer_angle: float = deg_to_rad(-90.0 + 72.0 * point)
		var inner_angle: float = outer_angle + deg_to_rad(36.0)
		points.append(center_point + (Vector2.from_angle(outer_angle) * radius).round())
		points.append(center_point + (Vector2.from_angle(inner_angle) * radius * STAR_INNER_RATIO).round())
	# El hueco apagado se ve siempre debajo: el holograma se enciende sobre él.
	var empty_body: Color = STAR_EMPTY_COLOR
	empty_body.a = STAR_EMPTY_BODY_ALPHA
	stars_row.draw_colored_polygon(points, empty_body)
	_draw_outline(points, STAR_EMPTY_COLOR, STAR_RIM_WIDTH, INF)
	if progress <= 0.0:
		return
	var top: float = points[0].y
	var bottom: float = points[0].y
	for point: Vector2 in points:
		bottom = maxf(bottom, point.y)
	var powering: bool = progress < 1.0
	var reveal: float = clampf(progress / STAR_REVEAL_PORTION, 0.0, 1.0)
	var limit_y: float = top + (bottom - top) * reveal if reveal < 1.0 else INF
	var brightness: float = 1.0 - STAR_FLICKER_DEPTH * (0.5 + 0.5 * sin(_time * STAR_FLICKER_RATE + index * 2.0))
	var glitch: float = 0.0
	if progress < STAR_STABLE_AT:
		var step: int = int(progress * STAR_FLICKER_STEPS)
		if _noise(step, index) < STAR_FLICKER_OFF_CHANCE:
			brightness *= STAR_FLICKER_DIM
		glitch = (1.0 - progress / STAR_STABLE_AT) * STAR_GLITCH_PX
	if not powering or reveal >= 1.0:
		var body: Color = STAR_HOLO_COLOR
		body.a = STAR_BODY_ALPHA * brightness
		stars_row.draw_colored_polygon(points, body)
	var scan: Color = STAR_HOLO_COLOR
	scan.a = STAR_SCAN_ALPHA * brightness
	_draw_scanlines(points, scan, top, limit_y, glitch, index)
	var glow: Color = STAR_HOLO_COLOR
	glow.a = STAR_GLOW_ALPHA * brightness
	_draw_outline(points, glow, STAR_GLOW_WIDTH, limit_y)
	var rim: Color = STAR_RIM_COLOR
	rim.a = brightness
	_draw_outline(points, rim, STAR_RIM_WIDTH, limit_y)
	# Frente del barrido: una línea brillante por donde va la proyección.
	if limit_y < INF:
		var front: Color = STAR_FRONT_COLOR
		front.a = 0.9
		var front_xs: Array[float] = _crossings(points, limit_y)
		for k: int in range(0, front_xs.size() - 1, 2):
			var from_x: float = roundf(front_xs[k])
			stars_row.draw_rect(Rect2(from_x, roundf(limit_y) - 1.0, roundf(front_xs[k + 1]) - from_x, STAR_SCAN_THICKNESS), front)

# Ruido determinista en 0..1 a partir de dos enteros (para el parpadeo y las líneas descuadradas).
func _noise(a: int, b: int) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)

# Cruces de una línea horizontal en `y` con el contorno de la estrella (las x, ordenadas). Van de dos
# en dos: dentro entre el primero y el segundo, fuera entre el segundo y el tercero... (no es convexa).
func _crossings(points: PackedVector2Array, y: float) -> Array[float]:
	var xs: Array[float] = []
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		if (a.y <= y) != (b.y <= y):
			xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x))
	xs.sort()
	return xs

# Contorno cerrado de la estrella, solo por encima de `limit_y` (INF: entero).
func _draw_outline(points: PackedVector2Array, color: Color, width: float, limit_y: float) -> void:
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		if a.y > limit_y and b.y > limit_y:
			continue
		if a.y > limit_y:
			a = a.lerp(b, (limit_y - a.y) / (b.y - a.y)).round()
		elif b.y > limit_y:
			b = b.lerp(a, (limit_y - b.y) / (a.y - b.y)).round()
		stars_row.draw_line(a, b, color, width)

# Rellena la estrella con líneas horizontales cada STAR_SCAN_STEP px que suben con el tiempo, solo por
# encima de `limit_y`. Al encenderse, algunas líneas se desplazan de lado `glitch` px como mucho.
func _draw_scanlines(points: PackedVector2Array, color: Color, top: float, limit_y: float, glitch: float, seed_value: int) -> void:
	var shift: int = int(fposmod(-_time * STAR_SCAN_SPEED, float(STAR_SCAN_STEP)))
	var y: int = int(top) + shift
	while y < limit_y and y < top + 200.0:
		var xs: Array[float] = _crossings(points, y)
		var offset_x: float = 0.0
		if glitch > 0.0 and _noise(y, seed_value + int(_time * 20.0)) < STAR_GLITCH_CHANCE:
			offset_x = roundf((_noise(y + 1, seed_value) * 2.0 - 1.0) * glitch)
		for k: int in range(0, xs.size() - 1, 2):
			var from_x: float = roundf(xs[k]) + offset_x
			stars_row.draw_rect(Rect2(from_x, y, roundf(xs[k + 1]) + offset_x - from_x, STAR_SCAN_THICKNESS), color)
		y += STAR_SCAN_STEP

func _on_visibility_changed() -> void:
	# Solo hay que animar el holograma mientras se ve.
	set_process(is_visible_in_tree())
	# Cada vez que se abre, la entrada empieza de cero; al cerrarse se deja en su sitio.
	if is_visible_in_tree():
		_start_intro()
	else:
		_finish_intro()

func _process(delta: float) -> void:
	_time += delta
	if _stars > 0:
		stars_row.queue_redraw()

func _start_intro() -> void:
	if _intro != null:
		_intro.kill()
	_time = 0.0
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
