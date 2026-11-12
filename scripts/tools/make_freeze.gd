extends SceneTree
## Genera los sprites del poder de congelar: copos que caen, escarcha de esquina e icono del botón.
## Escribe en assets/sprites/effects/freeze/ y assets/ui/power_freeze.png.
##
## Uso: godot --headless --path . -s scripts/tools/make_freeze.gd
## Después, importar: godot --headless --path . --import

const DIR: String = "res://assets/sprites/effects/freeze/"
const ICON_PATH: String = "res://assets/ui/power_freeze.png"

const FLAKE_VARIANTS: int = 3
const CORNER_SIZE: int = 112

# Paleta Cryo (art.md) más un azul muy oscuro para el contorno y el fondo del cristal.
const ICE: Array[Color] = [Color("#245296"), Color("#54a0e2"), Color("#a6defa"), Color("#ecfaff")]
const OUTLINE: Color = Color("#0c0e16")
const CLEAR: Color = Color(0, 0, 0, 0)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 21
	DirAccess.make_dir_recursive_absolute(DIR)
	for i: int in FLAKE_VARIANTS:
		_save(_flake(i), "freeze_flake_%d.png" % i)
	_save(_corner(), "freeze_corner.png")
	_icon().save_png(ICON_PATH)
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
	# Polvo de escarcha pegado a los dos bordes de la esquina.
	for y: int in CORNER_SIZE:
		for x: int in CORNER_SIZE:
			var d: float = Vector2(x, y).length()
			if d < 72.0 and _hash(x, y) > 0.55 + d / 72.0 * 0.4:
				_put(img, x, y, Color(ICE[1 + int(_hash(y, x) * 3.0)], 0.85 * (1.0 - d / 90.0)))
	_snowflake(img, Vector2(28, 28), 22.0, 1.0)
	_snowflake(img, Vector2(70, 14), 9.0, 0.9)
	_snowflake(img, Vector2(14, 72), 9.0, 0.9)
	_snowflake(img, Vector2(58, 58), 7.0, 0.8)
	_snowflake(img, Vector2(92, 8), 4.0, 0.7)
	_snowflake(img, Vector2(8, 92), 4.0, 0.7)
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
