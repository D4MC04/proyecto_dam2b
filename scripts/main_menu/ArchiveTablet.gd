class_name ArchiveTablet
extends OfficeObject

# Tablet del Archivo en su bandeja de la consola inclinada: abre la Navedex. La bandeja es parte de
# center_static.png y la tablet es tablet.png (marco grueso con escuadras y el canto abajo). Aquí se
# pinta la pantalla (pestañas, el holograma cian de una nave, líneas de datos y fichas), llevada al
# trapecio de la tablet. Con el ratón encima la tablet sube un poco, como para sacarla, con su
# sombra, se enciende la luz del fondo de la bandeja, la nave gira y baja una línea de escaneo.

const TABLET: Texture2D = preload("res://assets/sprites/office/tablet.png")
# Naves que enseña la pantalla, en su animación hacia arriba.
const SHIPS: Array[SpriteFrames] = [
	preload("res://resources/sprite_frames/nave_normal.tres"),
	preload("res://resources/sprite_frames/wasp.tres"),
	preload("res://resources/sprite_frames/acorazado.tres"),
	preload("res://resources/sprite_frames/nave_agresiva.tres"),
]
const SHIP_TIME: float = 1.6
# Rampa del holograma, de oscuro a claro: cada píxel de la nave toma el tono de su brillo.
const HOLOGRAM_RAMP: Array[Color] = [Color("#14304a"), Color("#1c7496"), Color("#40e0f0"), Color("#befaff")]
const SELECTED_FILL: Color = Color("#13414f")
# Cuánto sube la tablet con el ratón encima y lo deprisa que llega.
const LIFT: int = 8
const LIFT_SPEED: float = 12.0
const SHADOW: Color = Color(0, 0, 0, 0.45)
# Maqueta de la pantalla (en píxeles de la pantalla de frente): margen a los cuatro lados, pestañas,
# alto reservado para la nave (la más grande mide 32), líneas de datos (fracción del ancho) y fichas.
const MARGIN: int = 6
const TAB_WIDTH: int = 14
const TAB_GAP: int = 4
const SHIP_BOX: int = 32
const DATA_LINES: Array[float] = [0.7, 0.45, 0.58]
const DATA_LINE_STEP: int = 5
const CELL_GAP: int = 3

var _holograms: Array[Texture2D] = []
var _lift: float = 0.0
var _tablet: Dictionary
var _screen: Dictionary
var _source: Vector2i

func _ready() -> void:
	super()
	_tablet = OfficeLayout.CENTER.tablet
	_screen = _tablet.screen
	_source = OfficePaint.quad_source_size(_screen)
	for frames: SpriteFrames in SHIPS:
		_holograms.append(_make_hologram(frames.get_frame_texture(&"up", 0)))

func _process(delta: float) -> void:
	_lift = lerpf(_lift, 1.0 if hovered else 0.0, minf(1.0, delta * LIFT_SPEED))
	super(delta)

# Copia de la nave en la rampa cian: el contorno y las sombras en los tonos oscuros, las luces en los claros.
func _make_hologram(texture: Texture2D) -> Texture2D:
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var step: int = clampi(int(pixel.get_luminance() * HOLOGRAM_RAMP.size() * 1.4), 0, HOLOGRAM_RAMP.size() - 1)
			image.set_pixel(x, y, HOLOGRAM_RAMP[step])
	return ImageTexture.create_from_image(image)

func _draw_object() -> void:
	var lift: int = roundi(_lift * LIFT)
	var light: Array = OfficeLayout.CENTER.tray_light
	var light_at: Vector2i = Vector2i(to_local_point(Vector2(light[0], light[1])))
	OfficePaint.rect(self, Rect2i(light_at, Vector2i(light[2], 1)), OfficePaint.CYAN if hovered else OfficePaint.SCREEN_LINE)
	if lift > 0:
		var s: Dictionary = _tablet.shadow
		var shadow: PackedVector2Array = PackedVector2Array([Vector2(s.tl + 2, s.top + 4), Vector2(s.tr + 2, s.top + 4),
				Vector2(s.br + 2, s.bot + 2), Vector2(s.bl + 2, s.bot + 2)])
		for i: int in shadow.size():
			shadow[i] = to_local_point(shadow[i])
		draw_colored_polygon(shadow, SHADOW)
	var origin: Vector2i = Vector2i(to_local_point(Vector2(_tablet.x, _tablet.y - lift)))
	draw_texture(TABLET, origin)
	_draw_screen(origin)

# Pantalla pintada de frente (tamaño _source) y llevada al trapecio de la tablet. Todo va centrado y
# llena la pantalla: pestañas y cabecera arriba, fichas abajo a todo el ancho y, en medio, la nave y
# las líneas de datos con el mismo hueco arriba, entre ellas y abajo.
func _draw_screen(origin: Vector2i) -> void:
	var w: int = _source.x
	var h: int = _source.y
	for y: int in range(1, h, 2):
		_quad_rect(Rect2i(0, y, w, 1), OfficePaint.SCREEN_DARK, origin)
	var column: int = w - 2 * MARGIN
	@warning_ignore("integer_division")
	var tabs_x: int = (w - (3 * TAB_WIDTH + 2 * TAB_GAP)) / 2
	for i: int in 3:
		_quad_rect(Rect2i(tabs_x + i * (TAB_WIDTH + TAB_GAP), MARGIN, TAB_WIDTH, 3),
				OfficePaint.CYAN if i == 0 else OfficePaint.SCREEN_LINE, origin)
	_quad_rect(Rect2i(MARGIN, MARGIN + 6, column, 2), OfficePaint.CYAN_DARK, origin)
	var header_end: int = MARGIN + 8
	# Fichas: cuatro a todo el ancho, pegadas al margen de abajo.
	@warning_ignore("integer_division")
	var cell_size: int = (column - 3 * CELL_GAP) / 4
	@warning_ignore("integer_division")
	var cells_x: int = (w - (4 * cell_size + 3 * CELL_GAP)) / 2
	var cells_y: int = h - MARGIN - cell_size
	@warning_ignore("integer_division")
	var icon_inset: int = maxi(5, cell_size / 2 - 4)
	var selected: int = int(time / SHIP_TIME) % 4
	for i: int in 4:
		var cell: Rect2i = Rect2i(cells_x + i * (cell_size + CELL_GAP), cells_y, cell_size, cell_size)
		var on: bool = i == selected
		_quad_rect(cell, OfficePaint.CYAN if on else OfficePaint.SCREEN_LINE, origin)
		_quad_rect(cell.grow(-2), SELECTED_FILL if on else OfficePaint.SCREEN_DARK, origin)
		_quad_rect(cell.grow(-icon_inset), OfficePaint.CYAN_DARK if on else OfficePaint.SCREEN_LINE, origin)
	# En medio, la nave y las líneas de datos repartidas a partes iguales.
	var lines_height: int = (DATA_LINES.size() - 1) * DATA_LINE_STEP + 2
	@warning_ignore("integer_division")
	var gap: int = (cells_y - header_end - SHIP_BOX - lines_height) / 3
	var lines_y: int = header_end + 2 * gap + SHIP_BOX
	for k: int in DATA_LINES.size():
		var line_width: int = roundi(column * DATA_LINES[k])
		@warning_ignore("integer_division")
		_quad_rect(Rect2i((w - line_width) / 2, lines_y + k * DATA_LINE_STEP, line_width, 2),
				OfficePaint.CYAN_DARK if k == 0 else OfficePaint.SCREEN_LINE, origin)
	if hovered:
		_quad_rect(Rect2i(0, int(time * 50.0) % h, w, 2), Color(OfficePaint.CYAN_LIGHT, 0.3), origin)
	@warning_ignore("integer_division")
	_draw_ship(origin, header_end + gap + SHIP_BOX / 2)

# La nave, de frente y centrada en la fila `row` de la pantalla (es pequeña: no hace falta
# deformarla). Con el ratón encima gira: se estrecha lo mismo por los dos lados y, de espaldas, se
# voltea en su sitio, así que no se mueve de lado.
func _draw_ship(origin: Vector2i, row: int) -> void:
	var ship: Texture2D = _holograms[int(time / SHIP_TIME) % _holograms.size()]
	var ship_size: Vector2i = Vector2i(ship.get_size())
	var span: Vector2 = OfficePaint.quad_span(_screen, row)
	var left: int = origin.x + roundi((span.x + span.y - ship_size.x) / 2.0)
	@warning_ignore("integer_division")
	var top: int = origin.y + _screen.top + row - ship_size.y / 2
	var turn: float = cos(time * 3.0) if hovered else 1.0
	# Lo que se estrecha por cada lado, en píxeles enteros.
	var squeeze: int = floori((1.0 - absf(turn)) * (ship_size.x - 2) / 2.0)
	var width: int = ship_size.x - 2 * squeeze
	# Con ancho negativo Godot voltea la textura sin mover la posición.
	draw_texture_rect(ship, Rect2(left + squeeze, top, width if turn >= 0.0 else -width, ship_size.y), false)

# Los corchetes siguen el contorno inclinado de la bandeja.
func hover_quad() -> PackedVector2Array:
	return to_local_quad(OfficeLayout.CENTER.tray_quad)

func _quad_rect(r: Rect2i, color: Color, origin: Vector2i) -> void:
	OfficePaint.quad_rect(self, _screen, _source, r, color, origin)
