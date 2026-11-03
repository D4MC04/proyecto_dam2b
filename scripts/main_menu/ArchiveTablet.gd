class_name ArchiveTablet
extends OfficeObject

# Tablet en su base sobre el escritorio: abre la Navedex (Archivo). Marco oscuro con las esquinas
# recortadas como los botones y, en la pantalla, el holograma cian de una nave con sus líneas de
# datos al lado. Con el ratón encima pasa de una nave a otra y una línea de escaneo baja por la
# pantalla.

const BODY := Rect2i(4, 0, 84, 58)
const BODY_CLIP := 4
const BEZEL := Color("#262c3c")
const SCREEN_RECT := Rect2i(9, 5, 74, 46)
# Base: pie y labio delantero que sujeta la tablet.
const BASE := Rect2i(10, 59, 72, 8)
const LIP := Rect2i(18, 52, 56, 9)
# Naves que enseña la pantalla, en su animación hacia arriba.
const SHIPS: Array[SpriteFrames] = [
	preload("res://resources/sprite_frames/nave_normal.tres"),
	preload("res://resources/sprite_frames/wasp.tres"),
	preload("res://resources/sprite_frames/acorazado.tres"),
	preload("res://resources/sprite_frames/nave_agresiva.tres"),
]
const SHIP_CENTER := Vector2i(30, 28)
const SHIP_TIME := 0.8
# Rampa del holograma, de oscuro a claro: cada píxel de la nave toma el tono de su brillo.
const HOLOGRAM_RAMP: Array[Color] = [Color("#14304a"), Color("#1c7496"), Color("#40e0f0"), Color("#befaff")]
# Largo de las líneas de datos, de arriba abajo.
const DATA_LINES: Array[int] = [24, 18, 22, 12, 20, 16]

var _holograms: Array[Texture2D] = []

func _ready() -> void:
	super()
	for frames in SHIPS:
		_holograms.append(_make_hologram(frames.get_frame_texture(&"up", 0)))

# Copia de la nave en la rampa cian: el contorno y las sombras en los tonos oscuros, las luces en los claros.
func _make_hologram(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var step := clampi(int(pixel.get_luminance() * HOLOGRAM_RAMP.size() * 1.4), 0, HOLOGRAM_RAMP.size() - 1)
			image.set_pixel(x, y, HOLOGRAM_RAMP[step])
	return ImageTexture.create_from_image(image)

func _draw_object() -> void:
	OfficePaint.metal_box(self, BASE)
	var ci := get_canvas_item()
	ClippedBoxStyle.fill_inside(ci, BODY, BODY_CLIP, BEZEL)
	ClippedBoxStyle.draw_outline(ci, BODY, BODY_CLIP, OfficePaint.OUTLINE)
	ClippedBoxStyle.draw_outline(ci, BODY.grow(-1), BODY_CLIP - 1, OfficePaint.METAL_DARK)
	OfficePaint.screen(self, SCREEN_RECT)
	# Cámara arriba al centro.
	OfficePaint.rect(self, Rect2i(45, 2, 2, 1), OfficePaint.OUTLINE)
	OfficePaint.metal_box(self, LIP)
	OfficePaint.rect(self, Rect2i(40, 56, 12, 1), OfficePaint.CYAN if hovered else OfficePaint.CYAN_DARK)
	_draw_ship()
	_draw_data()
	_draw_corners()
	if hovered:
		var scan_y := SCREEN_RECT.position.y + 1 + int(fmod(time * 30.0, SCREEN_RECT.size.y - 2))
		OfficePaint.rect(self, Rect2i(SCREEN_RECT.position.x + 1, scan_y, SCREEN_RECT.size.x - 2, 1),
				Color(OfficePaint.CYAN, 0.35))

func _draw_ship() -> void:
	var index := int(time / SHIP_TIME) % _holograms.size() if hovered else 0
	var texture := _holograms[index]
	var half := Vector2i(texture.get_size() / 2.0)
	# Parpadeo leve de holograma; fijo con el ratón encima.
	var alpha := 1.0 if hovered or fmod(time, 2.3) > 0.08 else 0.5
	draw_texture(texture, Vector2(SHIP_CENTER - half), Color(1, 1, 1, alpha))

func _draw_data() -> void:
	var x := 54
	for i in DATA_LINES.size():
		var color := OfficePaint.CYAN if i == 0 else OfficePaint.CYAN_DARK
		OfficePaint.rect(self, Rect2i(x, 11 + i * 6 + (2 if i > 0 else 0), DATA_LINES[i], 2 if i == 0 else 1), color)

# Corchetes en L de 3 px en las esquinas de la pantalla, como las barras de los niveles.
func _draw_corners() -> void:
	var r := SCREEN_RECT.grow(-2)
	for corner: Vector2i in [r.position, Vector2i(r.end.x - 1, r.position.y),
			Vector2i(r.position.x, r.end.y - 1), r.end - Vector2i.ONE]:
		var x_dir := 1 if corner.x == r.position.x else -1
		var y_dir := 1 if corner.y == r.position.y else -1
		OfficePaint.rect(self, Rect2i(corner.x if x_dir > 0 else corner.x - 2, corner.y, 3, 1), OfficePaint.CYAN_DARK)
		OfficePaint.rect(self, Rect2i(corner.x, corner.y if y_dir > 0 else corner.y - 2, 1, 3), OfficePaint.CYAN_DARK)
