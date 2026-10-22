extends SceneTree
## Genera los frames de la Reparadora (assets/sprites/enemies/reparadora/reparadora_up_<n>.png).
##
## Uso: godot --headless --path . -s scripts/tools/make_reparadora.gd
##
## Nave de apoyo de 32x32 mirando hacia arriba, simétrica: casco blanco redondeado con franjas
## verdes, un núcleo verde que late en el centro, dos brazos con módulos de reparación a los lados
## y motores de llama verde. Se dibuja con formas (elipses y rectángulos) sombreadas por bloques con
## luz desde arriba, y al final se cierra el contorno. Los frames cambian el latido del núcleo, las
## luces de los módulos y la llama.

const TARGET_DIR: String = "res://assets/sprites/enemies/reparadora/"
const SIZE: int = 32
const FRAMES: int = 3
const CENTER_X: float = 15.5

const OUTLINE: Color = Color("#0a0810")
# Metal de los enemigos, de sombra a luz (ver docs/design/art.md), más un blanco para los brillos
const METAL: PackedColorArray = [Color("#2c303e"), Color("#545c6e"), Color("#8c96aa"), Color("#d2dceb"), Color("#f4f8ff")]
# Verde de la reparación, de oscuro a claro
const GREEN: PackedColorArray = [Color("#0e3a24"), Color("#1c7440"), Color("#3cb860"), Color("#7ee89a"), Color("#c4f5d0"), Color("#f0fff4")]

var _image: Image


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for frame: int in FRAMES:
		_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_draw_ship(frame)
		_close_outline()
		var path: String = TARGET_DIR + "reparadora_up_%d.png" % (frame + 1)
		error = _image.save_png(ProjectSettings.globalize_path(path))
		print("Guardado %s (error %d)" % [path, error])
	quit(error)


func _draw_ship(frame: int) -> void:
	# Llamas debajo de todo para que el casco las tape por arriba
	_draw_flames(frame)
	# Brazos y módulos de reparación
	for side: int in [-1, 1]:
		_draw_arm(side, frame)
	# Casco: cuerpo ancho y morro estrecho
	_fill_ellipse(Vector2(CENTER_X, 15.5), Vector2(7.0, 8.5), _hull_tone)
	_fill_ellipse(Vector2(CENTER_X, 9.0), Vector2(4.0, 7.0), _hull_tone)
	# Toberas
	for x: int in [11, 12, 13, 18, 19, 20]:
		_put(x, 24, METAL[1])
		_put(x, 25, METAL[0])
	for x: int in [11, 13, 18, 20]:
		_put(x, 26, OUTLINE)
	# Junta entre el morro y el cuerpo
	for x: int in range(10, 22):
		if _image.get_pixel(x, 10).a > 0.0:
			_put(x, 10, OUTLINE)
	# Franjas verdes a lo largo del casco
	for y: int in range(11, 22):
		for x: int in [10, 21]:
			if _image.get_pixel(x, y).a > 0.0:
				_put(x, y, GREEN[2] if y < 14 else GREEN[1])
	# Remaches
	for pixel: Vector2i in [Vector2i(12, 12), Vector2i(19, 12), Vector2i(12, 21), Vector2i(19, 21)]:
		_put(pixel.x, pixel.y, METAL[3])
	# Cabina en el morro
	_put(15, 4, GREEN[4])
	_put(16, 4, GREEN[3])
	_put(15, 5, GREEN[3])
	_put(16, 5, GREEN[2])
	_put(15, 6, GREEN[1])
	_put(16, 6, GREEN[1])
	_put(15, 7, GREEN[0])
	_put(16, 7, GREEN[0])
	_draw_core(frame)


## Tono de metal de un punto de una elipse: claro arriba, oscuro abajo y en los bordes.
func _hull_tone(u: float, v: float) -> Color:
	var light: float = 0.65 - 0.7 * v - 0.6 * (u * u + v * v)
	if light > 0.75:
		return METAL[4]
	if light > 0.35:
		return METAL[3]
	if light > -0.05:
		return METAL[2]
	if light > -0.45:
		return METAL[1]
	return METAL[0]


## Los módulos van un tono más oscuros que el casco para que el núcleo destaque.
func _pod_tone(u: float, v: float) -> Color:
	var color: Color = _hull_tone(u, v)
	var index: int = METAL.find(color)
	return METAL[maxi(index - 1, 0)]


func _draw_arm(side: int, frame: int) -> void:
	# Brazo: viga entre el casco y el módulo, con un conducto verde
	for x: int in range(5, 10):
		var px: int = _mirror(x, side)
		_put(px, 14, METAL[2])
		_put(px, 15, GREEN[1] if x % 2 == 0 else METAL[1])
		_put(px, 16, METAL[0])
	# Módulo: cápsula vertical
	var pod_x: float = CENTER_X + side * 12.0
	_fill_ellipse(Vector2(pod_x, 14.5), Vector2(2.5, 6.5), _pod_tone)
	# Pinzas de reparación que abrazan el emisor por delante
	for pixel: Vector2i in [Vector2i(1, 8), Vector2i(1, 7), Vector2i(5, 8), Vector2i(5, 7)]:
		_put(_mirror(pixel.x, side), pixel.y, METAL[2])
	_put(_mirror(2, side), 6, METAL[3])
	_put(_mirror(4, side), 6, METAL[3])
	# Emisor verde entre las pinzas; parpadea
	var bright: bool = frame == 1
	_put(_mirror(2, side), 8, GREEN[3])
	_put(_mirror(3, side), 8, GREEN[5] if bright else GREEN[4])
	_put(_mirror(4, side), 8, GREEN[3])
	_put(_mirror(3, side), 7, GREEN[4] if bright else GREEN[3])
	_put(_mirror(2, side), 9, GREEN[1])
	_put(_mirror(3, side), 9, GREEN[2])
	_put(_mirror(4, side), 9, GREEN[1])
	# Franja verde del módulo, como las del casco
	for y: int in range(11, 18):
		_put(_mirror(3, side), y, GREEN[2] if y < 13 else GREEN[1])
	# Llamita del módulo
	_put(_mirror(3, side), 21, GREEN[3] if frame != 2 else GREEN[2])


## Núcleo: anillo oscuro con un disco verde que late.
func _draw_core(frame: int) -> void:
	var center: Vector2 = Vector2(CENTER_X, 16.0)
	var pulse: float = [0.0, 0.7, 0.35][frame]
	for y: int in SIZE:
		for x: int in SIZE:
			var distance: float = (Vector2(x + 0.5, y + 0.5) - center).length()
			if distance < 1.0 + pulse:
				_put(x, y, GREEN[5])
			elif distance < 1.8 + pulse:
				_put(x, y, GREEN[4])
			elif distance < 2.4 + pulse * 0.5:
				_put(x, y, GREEN[3])
			elif distance < 3.0:
				_put(x, y, GREEN[1])
			elif distance < 3.8:
				_put(x, y, OUTLINE)


func _draw_flames(frame: int) -> void:
	var length: int = [3, 4, 2][frame]
	for nozzle_x: int in [12, 19]:
		for i: int in length:
			var color: Color = GREEN[4] if i == 0 else (GREEN[3] if i < length - 1 else GREEN[2])
			_put(nozzle_x, 27 + i, color)
			if i < length - 1:
				_put(nozzle_x - 1 if nozzle_x == 12 else nozzle_x + 1, 27 + i, GREEN[2])


func _fill_ellipse(center: Vector2, radius: Vector2, tone: Callable) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			var u: float = (x + 0.5 - center.x) / radius.x
			var v: float = (y + 0.5 - center.y) / radius.y
			if u * u + v * v <= 1.0:
				_put(x, y, tone.call(u, v))


## Contorno de 1 px en los huecos que tocan la figura (en cruz). Las llamas no llevan contorno.
func _close_outline() -> void:
	var outline: Array[Vector2i] = []
	for y: int in SIZE:
		for x: int in SIZE:
			if _image.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= SIZE or neighbor.y >= SIZE:
					continue
				var color: Color = _image.get_pixelv(neighbor)
				if color.a > 0.0 and not _is_flame(color, neighbor):
					outline.append(Vector2i(x, y))
					break
	for pixel: Vector2i in outline:
		_image.set_pixelv(pixel, OUTLINE)


func _is_flame(color: Color, pixel: Vector2i) -> bool:
	return pixel.y >= 21 and color in [GREEN[2], GREEN[3], GREEN[4]] and (pixel.y >= 27 or pixel.x < 6 or pixel.x > 25)


func _mirror(x: int, side: int) -> int:
	return x if side < 0 else SIZE - 1 - x


func _put(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		_image.set_pixel(x, y, color)
