extends SceneTree
## Genera los sprites de la Minigun y de la Minigun pesada
## (assets/sprites/turrets/minigun/ y assets/sprites/turrets/minigun_fusion/).
##
## Uso: godot --headless --path . -s scripts/tools/make_minigun.gd
##
## Por carpeta: minigun_base.png (32x32), minigun_cannon_sheet.png (5 frames de 32x32: reposo,
## fire_0 y fire_1 con retroceso y los tubos girando), minigun_full_up.png (icono con base y
## cañón), minigun_flash_sheet.png (3 frames de 16x16), minigun_bullet_sheet.png (2 frames de 4x8,
## trazadora) y minigun_impact_sheet.png (4 frames de 16x16). Los cuerpos se sombrean por bloques
## con luz arriba a la izquierda y al final se cierra el contorno; los efectos no llevan contorno.

const SIZE: int = 32
const EFFECT_SIZE: int = 16
const CENTER_X: float = 15.5
const CANNON_FRAMES: int = 5

const OUTLINE: Color = Color("#0c0e16")
# Metal gris azulado de las torretas, de sombra a luz (ver docs/design/art.md)
const METAL: PackedColorArray = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6"), Color("#d2dceb")]
# Acento de la Minigun: naranja de trazadora, de oscuro a claro, y núcleo casi blanco
const ORANGE: PackedColorArray = [Color("#a8401a"), Color("#ff7326"), Color("#ffc890"), Color("#fff4e0")]
# Acento nuevo de la Minigun pesada: rojo, de oscuro a claro, y núcleo casi blanco
const RED: PackedColorArray = [Color("#961432"), Color("#ff3c5a"), Color("#ffaabe"), Color("#fff0f4")]

var _image: Image
var _heavy: bool = false
var _accent: PackedColorArray = ORANGE


func _initialize() -> void:
	var error: Error = OK
	for heavy: bool in [false, true]:
		_heavy = heavy
		_accent = RED if heavy else ORANGE
		var dir: String = "res://assets/sprites/turrets/%s/" % ("minigun_fusion" if heavy else "minigun")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var base: Image = _make_base()
		var cannons: Array[Image] = []
		for frame: int in CANNON_FRAMES:
			cannons.append(_make_cannon(frame))
		var icon: Image = base.duplicate()
		icon.blend_rect(cannons[0], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
		error = maxi(error, _save(base, dir + "minigun_base.png"))
		error = maxi(error, _save(_sheet(cannons), dir + "minigun_cannon_sheet.png"))
		error = maxi(error, _save(icon, dir + "minigun_full_up.png"))
		error = maxi(error, _save(_sheet(_make_frames(3, _draw_flash, EFFECT_SIZE)), dir + "minigun_flash_sheet.png"))
		error = maxi(error, _save(_sheet(_make_frames(2, _draw_bullet, 0)), dir + "minigun_bullet_sheet.png"))
		error = maxi(error, _save(_sheet(_make_frames(4, _draw_impact, EFFECT_SIZE)), dir + "minigun_impact_sheet.png"))
	quit(error)


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("Guardado %s (error %d)" % [path, error])
	return error


## Une varias imágenes del mismo tamaño en una tira horizontal.
func _sheet(frames: Array[Image]) -> Image:
	var width: int = frames[0].get_width()
	var sheet: Image = Image.create(width * frames.size(), frames[0].get_height(), false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, width, frames[i].get_height()), Vector2i(width * i, 0))
	return sheet


## Crea `count` frames de efecto llamando a `draw(frame)`. `size` 0 es la bala (4x8).
func _make_frames(count: int, draw: Callable, size: int) -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in count:
		_image = Image.create(4 if size == 0 else size, 8 if size == 0 else size, false, Image.FORMAT_RGBA8)
		draw.call(frame)
		frames.append(_image)
	return frames


# --- Base ---

func _make_base() -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# Placa octogonal de 24 px con las esquinas recortadas 6 px
	for y: int in range(4, 28):
		for x: int in range(4, 28):
			var dx: int = mini(x - 4, 27 - x)
			var dy: int = mini(y - 4, 27 - y)
			if dx + dy < 6:
				continue
			_put(x, y, _plate_tone(x, y))
	# Anillo hundido donde gira el cañón
	_fill_circle(Vector2(CENTER_X, 15.5), 8.0, func(_u: float, _v: float) -> Color: return OUTLINE)
	_fill_circle(Vector2(CENTER_X, 15.5), 7.0, func(u: float, v: float) -> Color: return METAL[1] if u + v > 0.8 else METAL[0])
	# Remaches en las diagonales y luces de acento en los lados
	for pixel: Vector2i in [Vector2i(8, 8), Vector2i(23, 8), Vector2i(8, 23), Vector2i(23, 23)]:
		_put(pixel.x, pixel.y, METAL[3] if pixel.x + pixel.y < 32 else METAL[2])
	for pixel: Vector2i in [Vector2i(5, 15), Vector2i(5, 16), Vector2i(26, 15), Vector2i(26, 16)]:
		_put(pixel.x, pixel.y, _accent[1])
	if _heavy:
		# Placas de blindaje arriba y abajo con franjas de aviso en el acento
		for x: int in range(11, 21):
			for y: int in [5, 26]:
				_put(x, y, _accent[1] if (x + y) % 4 < 2 else OUTLINE)
		# Más remaches y luces claras
		for pixel: Vector2i in [Vector2i(11, 7), Vector2i(20, 7), Vector2i(11, 24), Vector2i(20, 24)]:
			_put(pixel.x, pixel.y, METAL[3])
		for pixel: Vector2i in [Vector2i(5, 15), Vector2i(26, 15)]:
			_put(pixel.x, pixel.y, _accent[2])
	_close_outline()
	return _image


## Tono de la placa: luz arriba a la izquierda, sombra abajo a la derecha.
func _plate_tone(x: int, y: int) -> Color:
	var edge: int = mini(mini(x - 4, 27 - x), mini(y - 4, 27 - y))
	if edge == 0 or x + y <= 13:
		return METAL[2] if x + y < 32 else METAL[0]
	if x + y >= 49:
		return METAL[0]
	return METAL[1]


# --- Cañón ---

## Frame 0: reposo. 1 y 2: fire_0 (retroceso y giro). 3 y 4: fire_1.
func _make_cannon(frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var recoil: int = 1 if frame == 1 or frame == 3 else 0
	var phase: int = frame
	var half: int = 4 if _heavy else 3
	var top: int = (2 if _heavy else 3) + recoil
	if _heavy:
		# Tambores de munición a los lados
		for side: int in [-1, 1]:
			var drum_x: float = CENTER_X + side * 7.5
			_fill_circle(Vector2(drum_x, 18.5), 3.2, _metal_tone)
			_put(roundi(drum_x - 0.5), 18, _accent[1])
			_put(roundi(drum_x + 0.5) - 1, 19, _accent[0])
		# Contorno propio para separarlos de la carcasa
		_close_outline()
	# Carcasa del motor de giro
	_fill_circle(Vector2(CENTER_X, 17.0 + recoil), 5.6, _metal_tone)
	# Tubos: columnas de 2 px centradas; el tubo con brillo rota con la fase para que parezca que giran
	var tube_count: int = half
	var left: int = 16 - tube_count
	for tube: int in tube_count:
		var x0: int = left + tube * 2
		var lit: bool = (tube + phase) % tube_count == 0
		for y: int in range(top, 13 + recoil):
			_put(x0, y, METAL[3] if lit else METAL[2])
			_put(x0 + 1, y, METAL[1] if lit else METAL[0])
		# Boca del tubo
		_put(x0, top, OUTLINE)
		_put(x0 + 1, top, METAL[0])
	# Abrazaderas
	var right: int = _rightmost(top)
	var first: int = _leftmost(top)
	for y: int in [top + 2, top + 6]:
		for x: int in range(first, right + 1):
			_put(x, y, _accent[1] if y == top + 2 else METAL[2] if x < CENTER_X else METAL[1])
	# Luz del motor
	_put(15, 18 + recoil, _accent[2] if frame in [1, 3] else _accent[1])
	_put(16, 18 + recoil, _accent[1])
	_close_outline()
	# Brillo en las bocas al disparar
	if recoil == 1:
		for x: int in range(first, right + 1):
			if _image.get_pixel(x, top).is_equal_approx(OUTLINE):
				_put(x, top, _accent[1])
	return _image


func _leftmost(y: int) -> int:
	for x: int in SIZE:
		if _image.get_pixel(x, y).a > 0.0:
			return x
	return 0


func _rightmost(y: int) -> int:
	for x: int in range(SIZE - 1, -1, -1):
		if _image.get_pixel(x, y).a > 0.0:
			return x
	return 0


func _metal_tone(u: float, v: float) -> Color:
	var light: float = -0.6 * u - 0.6 * v - 0.4 * (u * u + v * v)
	if light > 0.35:
		return METAL[3]
	if light > -0.1:
		return METAL[2]
	if light > -0.6:
		return METAL[1]
	return METAL[0]


# --- Efectos (sin contorno) ---

## Fogonazo hacia arriba: grande, mediano y unas chispas.
func _draw_flash(frame: int) -> void:
	var length: int = [6, 4, 2][frame]
	var cx: int = 7
	for i: int in length:
		var y: int = 10 - i
		var color: Color = _accent[3] if i < length / 2 else _accent[2]
		_put(cx, y, color)
		_put(cx + 1, y, color)
		if i < length - 1 and frame < 2:
			_put(cx - 1, y, _accent[1])
			_put(cx + 2, y, _accent[1])
	if frame == 0:
		for pixel: Vector2i in [Vector2i(4, 9), Vector2i(11, 9), Vector2i(5, 7), Vector2i(10, 7)]:
			_put(pixel.x, pixel.y, _accent[1])
	elif frame == 2:
		for pixel: Vector2i in [Vector2i(5, 8), Vector2i(10, 8), Vector2i(7, 6)]:
			_put(pixel.x, pixel.y, Color(_accent[0], 0.7))


## Trazadora corta: punta clara arriba y cola que se apaga.
func _draw_bullet(frame: int) -> void:
	var tail: PackedColorArray = [_accent[3], _accent[2], _accent[1], _accent[1], _accent[0], Color(_accent[0], 0.5)]
	for i: int in tail.size():
		var y: int = 1 + i
		var color: Color = tail[i]
		if frame == 1 and i == 1:
			color = _accent[3]
		_put(1, y, color)
		_put(2, y, color if i < 2 else Color(color, color.a * 0.6))


## Impacto: chispazo central que se abre en un anillo de chispas.
func _draw_impact(frame: int) -> void:
	var center: Vector2 = Vector2(7.5, 7.5)
	if frame == 0:
		_fill_circle(center, 2.5, func(_u: float, _v: float) -> Color: return _accent[3])
		for pixel: Vector2i in [Vector2i(7, 3), Vector2i(8, 12), Vector2i(3, 8), Vector2i(12, 7)]:
			_put(pixel.x, pixel.y, _accent[2])
		return
	var radius: float = 2.0 + frame * 2.0
	var alpha: float = 1.0 - (frame - 1) * 0.3
	for i: int in 8:
		var angle: float = TAU * i / 8.0 + frame * 0.3
		var pixel: Vector2i = Vector2i((center + Vector2.from_angle(angle) * radius).round())
		_put(pixel.x, pixel.y, Color(_accent[1] if frame < 3 else _accent[0], alpha))
	if frame == 1:
		_fill_circle(center, 1.5, func(_u: float, _v: float) -> Color: return _accent[2])


# --- Utilidades ---

func _put(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < _image.get_width() and y < _image.get_height():
		_image.set_pixel(x, y, color)


## Rellena un círculo; `tone(u, v)` recibe la posición normalizada (-1 a 1) dentro de él.
func _fill_circle(center: Vector2, radius: float, tone: Callable) -> void:
	for y: int in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			var offset: Vector2 = (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				_put(x, y, tone.call(offset.x, offset.y))


## Pinta de contorno los píxeles vacíos que tocan (en cruz) a uno opaco.
func _close_outline() -> void:
	var source: Image = _image.duplicate()
	for y: int in SIZE:
		for x: int in SIZE:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= SIZE or neighbor.y >= SIZE:
					continue
				if source.get_pixel(neighbor.x, neighbor.y).a > 0.0:
					_image.set_pixel(x, y, OUTLINE)
					break
