extends SceneTree
## Genera los sprites del poder de congelar: bloque de hielo de la nave (frames que brillan), trozos al romperse,
## copos que caen, escarcha de esquina y de borde, frente de frío e icono del botón. Escribe en
## assets/sprites/effects/freeze/ (frames sueltos), assets/ui/power_freeze.png y los SpriteFrames
## freeze_block.tres y freeze_shatter.tres en resources/sprite_frames/.
##
## Uso: godot --headless --path . -s scripts/tools/make_freeze.gd
## Después, importar: godot --headless --path . --import

const DIR: String = "res://assets/sprites/effects/freeze/"
const FRAMES_DIR: String = "res://resources/sprite_frames/"
const ICON_PATH: String = "res://assets/ui/power_freeze.png"

const BLOCK_FRAMES: int = 3
const SHATTER_FRAMES: int = 6
const FLAKE_VARIANTS: int = 3
const SIZE: int = 32
const CORNER_SIZE: int = 176
const EDGE_LENGTH: int = 64
const EDGE_DEPTH: int = 28
const FRONT_SIZE: Vector2i = Vector2i(40, 64)

# Paleta Cryo (art.md) más un azul muy oscuro para el contorno y el fondo del cristal.
const ICE: Array[Color] = [Color("#245296"), Color("#54a0e2"), Color("#a6defa"), Color("#ecfaff")]
const OUTLINE: Color = Color("#0c0e16")
const CLEAR: Color = Color(0, 0, 0, 0)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 21
	DirAccess.make_dir_recursive_absolute(DIR)
	for i: int in BLOCK_FRAMES:
		_save(_block(i), "freeze_block_%d.png" % i)
	for i: int in SHATTER_FRAMES:
		_save(_shatter(float(i) / (SHATTER_FRAMES - 1)), "freeze_shatter_%d.png" % i)
	for i: int in FLAKE_VARIANTS:
		_save(_flake(i), "freeze_flake_%d.png" % i)
	_save(_corner(), "freeze_corner.png")
	_save(_edge(), "freeze_edge.png")
	_save(_front(), "freeze_front.png")
	_icon().save_png(ICON_PATH)
	_save_frames("freeze_block", "freeze_block", BLOCK_FRAMES, true, 4.0)
	_save_frames("freeze_shatter", "freeze_shatter", SHATTER_FRAMES, false, 16.0)
	quit()


func _new(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _save(img: Image, file: String) -> void:
	img.save_png(DIR + file)


# Costra de hielo alrededor de la nave: contorno facetado y semitransparente (deja ver la nave), con
# brillos que cambian de un frame a otro.
func _block(index: int) -> Image:
	var img: Image = _new(SIZE, SIZE)
	var c: Vector2 = Vector2(SIZE / 2.0, SIZE / 2.0)
	for y: int in SIZE:
		for x: int in SIZE:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			# Octógono: |x|, |y| y |x|+|y| acotados.
			var oct: float = maxf(maxf(absf(p.x), absf(p.y)), (absf(p.x) + absf(p.y)) * 0.72)
			if oct > 14.5:
				continue
			if oct > 13.0:
				_put(img, x, y, ICE[2] if (p.x + p.y) < 0.0 else ICE[1])
			elif oct > 11.8:
				_put(img, x, y, Color(ICE[0], 0.9))
			else:
				var shade: Color = Color(ICE[1], 0.16)
				if (x + y * 2) % 11 == 0:
					shade = Color(ICE[3], 0.3)
				_put(img, x, y, shade)
	# Grietas y destellos: cambian por frame para que el hielo brille.
	for k: int in 4:
		var spot: Vector2i = Vector2i(7 + ((k * 7 + index * 5) % 18), 6 + ((k * 11 + index * 3) % 19))
		_put(img, spot.x, spot.y, ICE[3])
		_put(img, spot.x + 1, spot.y, ICE[2])
		_put(img, spot.x, spot.y + 1, ICE[2])
	for i: int in 6:
		_put(img, 9 + i, 10 + i, Color(ICE[3], 0.7))
	return img


# Rotura: el bloque se parte en trozos que se abren y se desvanecen.
func _shatter(t: float) -> Image:
	var img: Image = _new(SIZE, SIZE)
	var c: Vector2 = Vector2(SIZE / 2.0, SIZE / 2.0)
	var pieces: RandomNumberGenerator = RandomNumberGenerator.new()
	pieces.seed = 9
	for i: int in 14:
		var angle: float = TAU * i / 14.0 + pieces.randf_range(-0.2, 0.2)
		var start: float = pieces.randf_range(2.0, 9.0)
		var reach: float = pieces.randf_range(12.0, 15.0)
		var pos: Vector2 = c + Vector2.from_angle(angle) * lerpf(start, reach, 1.0 - pow(1.0 - t, 2.0))
		var color: Color = ICE[1 + i % 3]
		color.a = clampf((1.0 - t) * 1.6, 0.0, 1.0)
		var size: int = 3 if (i % 3 == 0 and t < 0.6) else 2
		for oy: int in size:
			for ox: int in size:
				_put(img, int(pos.x) + ox, int(pos.y) + oy, color)
	# Destello blanco del golpe en los primeros frames.
	if t < 0.4:
		for i: int in 8:
			var spark: Vector2 = c + Vector2.from_angle(TAU * i / 8.0) * (4.0 + t * 20.0)
			_put(img, int(spark.x), int(spark.y), ICE[3])
	return img


# Copo de nieve pequeño (5x5 o 7x7) en blanco hielo.
func _flake(index: int) -> Image:
	var img: Image = _new(7, 7)
	_put(img, 3, 3, ICE[3])
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_put(img, 3 + d.x, 3 + d.y, ICE[3])
		if index > 0:
			_put(img, 3 + d.x * 2, 3 + d.y * 2, ICE[2])
	if index == 2:
		for d: Vector2i in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			_put(img, 3 + d.x * 2, 3 + d.y * 2, ICE[1])
	return img


# Escarcha de la esquina de arriba a la izquierda: cristales que salen de la esquina; el código la voltea
# para las otras tres. Más densa y clara cerca de la esquina; cristal en ramas por los lados.
func _corner() -> Image:
	var img: Image = _new(CORNER_SIZE, CORNER_SIZE)
	for y: int in CORNER_SIZE:
		for x: int in CORNER_SIZE:
			var d: float = Vector2(x, y).length()
			var angle: float = atan2(float(y), float(x))
			# Borde irregular con ramas: picos cada cierto ángulo.
			var reach: float = 120.0 + 38.0 * absf(sin(angle * 5.0)) + _hash(x / 3, y / 3) * 14.0
			if d > reach:
				continue
			var t: float = d / reach
			var density: float = 1.0 - t
			var h: float = _hash(x / 4, y / 4)
			if h > density * 1.1 + 0.15 and t > 0.25:
				continue
			var tone: int = clampi(int((1.0 - t) * 3.4 + h * 0.8), 0, 3)
			var alpha: float = lerpf(0.9, 0.3, t)
			_put(img, x, y, Color(ICE[tone], alpha))
	# Rayas de cristal desde la esquina.
	for i: int in 5:
		var angle2: float = lerpf(0.1, PI / 2.0 - 0.1, i / 4.0)
		for r: int in range(6, 120):
			var p: Vector2 = Vector2.from_angle(angle2) * r
			if _hash(r, i) > 0.12:
				_put(img, int(p.x), int(p.y), ICE[3] if r % 9 < 4 else ICE[2])
	return img


# Escarcha del borde (arriba): franja que se repite a lo largo; el código la gira para los demás lados.
func _edge() -> Image:
	var img: Image = _new(EDGE_LENGTH, EDGE_DEPTH)
	for x: int in EDGE_LENGTH:
		var reach: float = 9.0 + 14.0 * absf(sin(x * TAU / EDGE_LENGTH * 2.0)) + _hash(x, 3) * 5.0
		for y: int in EDGE_DEPTH:
			if y > reach:
				continue
			var t: float = y / reach
			if _hash(x, y) > 1.15 - t * 0.2 - 0.3 * (1.0 - t) and t > 0.4:
				continue
			_put(img, x, y, Color(ICE[clampi(int((1.0 - t) * 3.5 + _hash(y, x) * 0.7), 0, 3)], lerpf(0.85, 0.3, t)))
		# Aguja de hielo ocasional.
		if x % 11 == 5:
			for y2: int in range(int(reach), int(reach) + 4):
				_put(img, x, y2, ICE[2])
	return img


# Frente de frío: banda vertical con degradado hacia la izquierda y borde claro a la derecha (barre el mapa).
func _front() -> Image:
	var img: Image = _new(FRONT_SIZE.x, FRONT_SIZE.y)
	for x: int in FRONT_SIZE.x:
		var t: float = float(x) / (FRONT_SIZE.x - 1)
		for y: int in FRONT_SIZE.y:
			if (x + y) % 2 == 0 or t > 0.85:
				var tone: int = 3 if t > 0.9 else (2 if t > 0.6 else 1)
				_put(img, x, y, Color(ICE[tone], pow(t, 1.6) * 0.8))
	return img


# Icono 16x16: copo de seis brazos con cristal facetado en el centro, rampa Cryo y contorno oscuro.
func _icon() -> Image:
	var img: Image = _new(16, 16)
	var c: Vector2 = Vector2(7.5, 7.5)
	# Relleno: seis brazos largos (cruz + diagonales cortas) en el azul del Cryo.
	var arms: Array[Vector2] = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	var cells: Dictionary[Vector2i, int] = {}
	for dir: Vector2 in arms:
		for r: int in range(0, 7):
			var p: Vector2i = Vector2i((c + dir * (r + 0.5) - Vector2(0.5, 0.5)).round())
			cells[p] = 1 if r > 4 else 2
			cells[p + Vector2i(int(dir.y != 0), int(dir.x != 0))] = 1 if r > 4 else 2
	for dir: Vector2i in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		for r: int in range(1, 6):
			cells[Vector2i(7, 7) + dir * r + Vector2i(1 if dir.x > 0 else 0, 1 if dir.y > 0 else 0)] = 0 if r > 3 else 1
	# Contorno de 1 px en cruz alrededor del relleno.
	for p: Vector2i in cells:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not cells.has(p + d):
				_put(img, p.x + d.x, p.y + d.y, OUTLINE)
	for p: Vector2i in cells:
		var tone: int = clampi(cells[p] + 1, 0, 3)
		_put(img, p.x, p.y, ICE[tone])
	# Núcleo claro y brillos.
	for p: Vector2i in [Vector2i(7, 7), Vector2i(8, 7), Vector2i(7, 8), Vector2i(8, 8)]:
		_put(img, p.x, p.y, ICE[3])
	_put(img, 7, 3, ICE[3])
	_put(img, 3, 7, ICE[3])
	return img


func _hash(x: int, y: int) -> float:
	return float(((x * 374761393 + y * 668265263) ^ 0x5bd1e995) & 0xffff) / 65535.0


# SpriteFrames con los PNG sueltos (rutas por ext_resource, como los demás de resources/sprite_frames/).
func _save_frames(file: String, prefix: String, count: int, loop: bool, fps: float) -> void:
	var text: String = "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
	for i: int in count:
		text += "[ext_resource type=\"Texture2D\" path=\"%s%s_%d.png\" id=\"%d\"]\n" % [DIR, prefix, i, i + 1]
	text += "\n[resource]\nanimations = [{\n\"frames\": ["
	var items: Array[String] = []
	for i: int in count:
		items.append("{\n\"duration\": 1.0,\n\"texture\": ExtResource(\"%d\")\n}" % (i + 1))
	text += ", ".join(items)
	text += "],\n\"loop\": %s,\n\"name\": &\"default\",\n\"speed\": %.1f\n}]\n" % [str(loop).to_lower(), fps]
	var f: FileAccess = FileAccess.open(FRAMES_DIR + file + ".tres", FileAccess.WRITE)
	f.store_string(text)
	f.close()
