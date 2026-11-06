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

# Pantalla pintada de frente (tamaño _source) y llevada al trapecio de la tablet.
func _draw_screen(origin: Vector2i) -> void:
	var w: int = _source.x
	var h: int = _source.y
	for y: int in range(1, h, 2):
		_quad_rect(Rect2i(0, y, w, 1), OfficePaint.SCREEN_DARK, origin)
	for i: int in 3:
		_quad_rect(Rect2i(6 + i * 16, 6, 12, 3), OfficePaint.CYAN if i == 0 else OfficePaint.SCREEN_LINE, origin)
	_quad_rect(Rect2i(6, 12, w - 12, 2), OfficePaint.CYAN_DARK, origin)
	for k: int in 3:
		_quad_rect(Rect2i(8, 54 + k * 6, [40, 28, 34][k], 2), OfficePaint.SCREEN_LINE if k > 0 else OfficePaint.CYAN_DARK, origin)
	@warning_ignore("integer_division")
	var cells_x: int = (w - (4 * 16 + 3 * 3)) / 2
	var selected: int = int(time / SHIP_TIME) % 4
	for i: int in 4:
		var cell: Rect2i = Rect2i(cells_x + i * 19, h - 22, 16, 16)
		var on: bool = i == selected
		_quad_rect(cell, OfficePaint.CYAN if on else OfficePaint.SCREEN_LINE, origin)
		_quad_rect(cell.grow(-2), SELECTED_FILL if on else OfficePaint.SCREEN_DARK, origin)
		_quad_rect(cell.grow(-5), OfficePaint.CYAN_DARK if on else OfficePaint.SCREEN_LINE, origin)
	if hovered:
		_quad_rect(Rect2i(0, int(time * 50.0) % h, w, 2), Color(OfficePaint.CYAN_LIGHT, 0.3), origin)
	# La nave, de frente en el centro de la pantalla (es pequeña: no hace falta deformarla).
	var ship: Texture2D = _holograms[int(time / SHIP_TIME) % _holograms.size()]
	var turn: float = cos(time * 3.0) if hovered else 1.0
	var width: int = maxi(2, roundi(absf(turn) * ship.get_width()))
	var row: int = 34
	var span: Vector2 = OfficePaint.quad_span(_screen, row)
	var center: Vector2i = origin + Vector2i(roundi((span.x + span.y) / 2.0), _screen.top + row)
	@warning_ignore("integer_division")
	var box: Rect2 = Rect2(center.x - width / 2, center.y - ship.get_height() / 2, width, ship.get_height())
	if turn < 0.0:
		box = Rect2(box.position.x + box.size.x, box.position.y, -box.size.x, box.size.y)
	draw_texture_rect(ship, box, false)

func _quad_rect(r: Rect2i, color: Color, origin: Vector2i) -> void:
	OfficePaint.quad_rect(self, _screen, _source, r, color, origin)
