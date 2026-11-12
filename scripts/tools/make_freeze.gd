extends SceneTree
## Genera los sprites del poder de congelar: cristales de hielo sobre la nave (frames que brillan), trozos al romperse,
## copos que caen, copos de escarcha de esquina, frente de frío e icono del botón. Escribe en
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
const CORNER_SIZE: int = 80
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


# Hielo sobre la nave sin taparla: aro finísimo y roto, cristales de 6 brazos en las esquinas y unos
# destellos que cambian por frame. El centro queda vacío para que se vea la nave.
func _block(index: int) -> Image:
	var img: Image = _new(SIZE, SIZE)
	var c: Vector2 = Vector2(SIZE / 2.0, SIZE / 2.0)
	for y: int in SIZE:
		for x: int in SIZE:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			var oct: float = maxf(maxf(absf(p.x), absf(p.y)), (absf(p.x) + absf(p.y)) * 0.72)
			if oct > 13.0 and oct <= 14.5 and (x + y) % 3 != 0:
				_put(img, x, y, Color(ICE[2], 0.55))
	_snowflake(img, Vector2(6, 6), 5.0, 0.9)
	_snowflake(img, Vector2(26, 25), 4.0, 0.9)
	_snowflake(img, Vector2(25, 8), 2.5, 0.8)
	for k: int in 3:
		var spot: Vector2i = Vector2i(8 + ((k * 9 + index * 7) % 17), 8 + ((k * 13 + index * 5) % 17))
		_put(img, spot.x, spot.y, Color(ICE[3], 0.9))
	return img


# Copo de 6 brazos centrado en `center`, con ramitas en V a 60 % del brazo. Alfa `alpha`.
func _snowflake(img: Image, center: Vector2, radius: float, alpha: float) -> void:
	for i: int in 6:
		var dir: Vector2 = Vector2.from_angle(TAU * i / 6.0 + PI / 2.0)
		for r: int in range(0, int(radius) + 1):
			var tone: int = 3 if r < radius * 0.5 else 2
			var q: Vector2 = center + dir * r
			_put(img, int(round(q.x)), int(round(q.y)), Color(ICE[tone], alpha))
		if radius >= 4.0:
			var fork: Vector2 = center + dir * (radius * 0.6)
			for side: float in [-1.0, 1.0]:
				var branch: Vector2 = dir.rotated(side * PI / 3.0)
				for r2: int in range(1, int(radius * 0.4) + 1):
					var q2: Vector2 = fork + branch * r2
					_put(img, int(round(q2.x)), int(round(q2.y)), Color(ICE[1], alpha))


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


# Escarcha de la esquina de arriba a la izquierda: un copo grande, uno pequeño y algo de polvo de escarcha
# pegado a los lados; sutil. El código la voltea para las otras tres.
func _corner() -> Image:
	var img: Image = _new(CORNER_SIZE, CORNER_SIZE)
	# Polvo fino pegado a los dos bordes de la esquina.
	for y: int in CORNER_SIZE:
		for x: int in CORNER_SIZE:
			var d: float = Vector2(x, y).length()
			if d < 46.0 and _hash(x, y) > 0.78 + d / 46.0 * 0.2:
				_put(img, x, y, Color(ICE[1 + int(_hash(y, x) * 2.0)], 0.5 * (1.0 - d / 46.0)))
	_snowflake(img, Vector2(20, 20), 14.0, 0.85)
	_snowflake(img, Vector2(44, 12), 6.0, 0.7)
	_snowflake(img, Vector2(11, 46), 6.0, 0.7)
	_snowflake(img, Vector2(37, 37), 4.0, 0.6)
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
