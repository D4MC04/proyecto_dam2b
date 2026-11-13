extends SceneTree
## Genera los sprites del ataque orbital: carga (retícula que se cierra), emisor de arriba, impacto en el
## suelo, chispas, estela quemada, destello final e icono del botón. Escribe en
## assets/sprites/effects/orbital/ (frames sueltos), assets/ui/power_orbital.png y los SpriteFrames
## orbital_charge.tres, orbital_emitter.tres, orbital_impact.tres, orbital_spark.tres y orbital_flash.tres
## en resources/sprite_frames/. El cuerpo del rayo no es un sprite: lo pinta Powers en código.
##
## Uso: godot --headless --path . -s scripts/tools/make_orbital.gd
## Después, importar: godot --headless --path . --import

const DIR: String = "res://assets/sprites/effects/orbital/"
const FRAMES_DIR: String = "res://resources/sprite_frames/"
const ICON_PATH: String = "res://assets/ui/power_orbital.png"

const CHARGE_FRAMES: int = 6
const EMITTER_FRAMES: int = 4
const IMPACT_FRAMES: int = 4
const SPARK_FRAMES: int = 4
const SCORCH_VARIANTS: int = 3
const FLASH_FRAMES: int = 8
const LENS_SIZE: int = 32
const IMPACT_SIZE: Vector2i = Vector2i(32, 24)
const SPARK_SIZE: int = 8
const SCORCH_SIZE: Vector2i = Vector2i(8, 14)
const FLASH_SIZE: int = 64

# De oscuro a claro: la rampa cian de la interfaz y el blanco del núcleo.
const CYAN: Array[Color] = [Color("#14304a"), Color("#1c7496"), Color("#40e0f0"), Color("#befaff"), Color("#f0faff")]
const METAL: Array[Color] = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6")]
const OUTLINE: Color = Color("#0c0e16")
const CLEAR: Color = Color(0, 0, 0, 0)

# Icono 16x16. Minúsculas llevan contorno; mayúsculas (ramas y chispas) no.
const ICON: Array[String] = [
	"................",
	".deed.bccb.deed.",
	".ddddabbbbadddd.",
	"......aeea......",
	".......ff.......",
	"......ewwe......",
	"......ewwe......",
	"......ewweF.....",
	"......ewwe.F....",
	".....Fewwe......",
	"....F.ewwe......",
	"......ewwe..E...",
	"..E..efwwfe.....",
	"...defwwwwfed...",
	"..ddeeffffeedd..",
	"................",
]
const ICON_COLORS: Dictionary[String, Color] = {
	"a": Color("#343a4a"), "b": Color("#606a7c"), "c": Color("#96a2b6"),
	"d": Color("#1c7496"), "e": Color("#40e0f0"), "f": Color("#befaff"), "w": Color("#f0faff"),
	"E": Color("#40e0f0"), "F": Color("#befaff"),
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for i: int in CHARGE_FRAMES:
		_save(_charge_frame(float(i) / (CHARGE_FRAMES - 1)), "orbital_charge_%d.png" % i)
	for i: int in EMITTER_FRAMES:
		_save(_emitter_frame(i), "orbital_emitter_%d.png" % i)
	for i: int in IMPACT_FRAMES:
		_save(_impact_frame(i), "orbital_impact_%d.png" % i)
	for i: int in SPARK_FRAMES:
		_save(_spark_frame(i), "orbital_spark_%d.png" % i)
	for i: int in SCORCH_VARIANTS:
		_save(_scorch(i), "orbital_scorch_%d.png" % i)
	for i: int in FLASH_FRAMES:
		_save(_flash_frame(float(i) / (FLASH_FRAMES - 1)), "orbital_flash_%d.png" % i)
	_icon().save_png(ICON_PATH)
	_save_frames("orbital_charge", CHARGE_FRAMES, false, 40.0)
	_save_frames("orbital_emitter", EMITTER_FRAMES, true, 16.0)
	_save_frames("orbital_impact", IMPACT_FRAMES, true, 20.0)
	_save_frames("orbital_spark", SPARK_FRAMES, false, 16.0)
	_save_frames("orbital_flash", FLASH_FRAMES, false, 24.0)
	quit()


func _new(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _disc(img: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y: int in range(int(center.y - radius.y) - 1, int(center.y + radius.y) + 2):
		for x: int in range(int(center.x - radius.x) - 1, int(center.x + radius.x) + 2):
			if ((Vector2(x + 0.5, y + 0.5) - center) / radius).length() <= 1.0:
				_put(img, x, y, color)


# Cruz de rayos desde el centro: largo en vertical y horizontal; el último tercio, más oscuro.
func _cross(img: Image, c: Vector2i, length: int, color: Color, tip: Color) -> void:
	for k: int in range(1, length + 1):
		var tone: Color = tip if k > length * 2 / 3 else color
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_put(img, c.x + dir.x * k, c.y + dir.y * k, tone)


# Esquinas en L a una distancia del centro: la retícula del satélite.
func _brackets(img: Image, c: Vector2i, dist: int, color: Color) -> void:
	for sx: int in [-1, 1]:
		for sy: int in [-1, 1]:
			var corner: Vector2i = c + Vector2i(sx * dist, sy * dist)
			for k: int in 3:
				_put(img, corner.x - sx * k, corner.y, color)
				_put(img, corner.x, corner.y - sy * k, color)


func _save(img: Image, file: String) -> void:
	img.save_png(DIR + file)


# Carga: la retícula se cierra hacia el centro mientras crece un destello en cruz.
func _charge_frame(t: float) -> Image:
	var img: Image = _new(LENS_SIZE, LENS_SIZE)
	var c: Vector2i = Vector2i(LENS_SIZE / 2, LENS_SIZE / 2)
	_brackets(img, c, roundi(lerpf(14.0, 7.0, t)), CYAN[2] if t < 0.8 else CYAN[3])
	var r: float = lerpf(1.0, 5.0, t)
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(r + 2.0, r + 2.0), Color(CYAN[2], 0.35))
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(r, r), CYAN[3])
	_cross(img, c, roundi(lerpf(2.0, 13.0, t)), CYAN[3], CYAN[2])
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(r * 0.5, r * 0.5), CYAN[4])
	return img


# Emisor: el destello ya cargado, que late mientras dura el rayo.
func _emitter_frame(index: int) -> Image:
	var img: Image = _new(LENS_SIZE, LENS_SIZE)
	var c: Vector2i = Vector2i(LENS_SIZE / 2, LENS_SIZE / 2)
	var pulse: float = [0.0, 1.0, 2.0, 1.0][index]
	_brackets(img, c, 7 + int(pulse) % 2, CYAN[1])
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(7.0, 7.0) + Vector2.ONE * pulse, Color(CYAN[2], 0.3))
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(4.5, 4.5) + Vector2.ONE * pulse * 0.5, CYAN[3])
	_cross(img, c, 10 + roundi(pulse) * 2, CYAN[3], CYAN[2])
	_disc(img, Vector2(c) + Vector2(0.5, 0.5), Vector2(2.5, 2.5), CYAN[4])
	return img


# Impacto en el suelo: óvalo de luz con núcleo blanco y salpicaduras que saltan hacia arriba.
func _impact_frame(index: int) -> Image:
	var img: Image = _new(IMPACT_SIZE.x, IMPACT_SIZE.y)
	var c: Vector2 = Vector2(IMPACT_SIZE.x / 2.0, 16.0)
	var grow: float = [0.0, 1.0, 0.5, 1.5][index]
	_disc(img, c, Vector2(13.0 + grow, 6.0 + grow * 0.5), Color(CYAN[2], 0.3))
	_disc(img, c, Vector2(9.0 + grow, 4.0), CYAN[1])
	_disc(img, c, Vector2(7.0 + grow, 3.0), CYAN[2])
	_disc(img, c, Vector2(4.0, 2.0), CYAN[3])
	_disc(img, c, Vector2(2.0, 1.0), CYAN[4])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 30 + index
	for i: int in 6:
		var x: int = int(c.x) + rng.randi_range(-10, 10)
		var top: int = int(c.y) - rng.randi_range(4, 14)
		for y: int in range(top, int(c.y) - 2):
			_put(img, x, y, CYAN[3] if y == top else CYAN[2])
	return img


# Chispa: se encoge y se enfría por frames.
func _spark_frame(index: int) -> Image:
	var img: Image = _new(SPARK_SIZE, SPARK_SIZE)
	var c: int = SPARK_SIZE / 2
	var tone: Color = CYAN[clampi(4 - index, 0, 4)]
	_put(img, c, c, tone)
	if index < 3:
		_put(img, c - 1, c, tone)
		_put(img, c, c - 1, tone)
	if index < 2:
		_put(img, c + 1, c, tone)
		_put(img, c, c + 1, tone)
	return img


# Tramo de estela quemada: franja carbonizada con brasas cian; los tramos se ponen uno junto a otro.
func _scorch(variant: int) -> Image:
	var img: Image = _new(SCORCH_SIZE.x, SCORCH_SIZE.y)
	var mid: float = SCORCH_SIZE.y / 2.0
	for x: int in SCORCH_SIZE.x:
		var half: float = 5.0 + _hash(x + variant * 8, 3) * 2.0
		for y: int in SCORCH_SIZE.y:
			var d: float = absf(y + 0.5 - mid)
			if d > half:
				continue
			if d > 3.0:
				if (x + y + variant) % 2 == 0:
					_put(img, x, y, Color(0.05, 0.03, 0.06, 0.4))
			else:
				_put(img, x, y, Color(0.05, 0.03, 0.06, 0.75))
				var h: float = _hash(x + variant * 8, y)
				if h > 0.86:
					_put(img, x, y, CYAN[2])
				elif h > 0.8:
					_put(img, x, y, CYAN[1])
	return img


# Destello final: disco blanco que se apaga, anillo que se abre y cruz de rayos que se encoge.
func _flash_frame(t: float) -> Image:
	var img: Image = _new(FLASH_SIZE, FLASH_SIZE)
	var c: Vector2 = Vector2(FLASH_SIZE / 2.0, FLASH_SIZE / 2.0)
	var ring_r: float = lerpf(6.0, 28.0, 1.0 - pow(1.0 - t, 2.0))
	var ring: Color = CYAN[3] if t < 0.5 else CYAN[2]
	ring.a = clampf((1.0 - t) * 1.5, 0.0, 1.0)
	for y: int in FLASH_SIZE:
		for x: int in FLASH_SIZE:
			if absf(Vector2(x + 0.5, y + 0.5).distance_to(c) - ring_r) < lerpf(1.6, 0.6, t):
				_put(img, x, y, ring)
	if t < 0.7:
		var r: float = 12.0 * (1.0 - t / 0.7)
		_disc(img, c, Vector2(r + 3.0, r + 3.0), Color(CYAN[2], 0.4))
		_disc(img, c, Vector2(r, r), CYAN[3])
		_disc(img, c, Vector2(r * 0.6, r * 0.6), CYAN[4])
	if t < 0.85:
		_cross(img, Vector2i(c), roundi(lerpf(30.0, 4.0, t)), CYAN[4] if t < 0.4 else CYAN[3], CYAN[2])
	return img


# Icono 16x16: satélite arriba, rayo con ramas y salpicadura en el suelo; contorno #0c0e16.
func _icon() -> Image:
	var img: Image = _new(16, 16)
	for y: int in 16:
		for x: int in 16:
			var key: String = ICON[y][x]
			if key == key.to_lower() and key != ".":
				_put(img, x, y, ICON_COLORS[key])
	# Contorno: cada hueco que toca un píxel de la figura (en cruz).
	var outlined: Image = img.duplicate()
	for y: int in 16:
		for x: int in 16:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + dir
				if n.x >= 0 and n.y >= 0 and n.x < 16 and n.y < 16 and img.get_pixel(n.x, n.y).a > 0.0:
					outlined.set_pixel(x, y, OUTLINE)
					break
	for y: int in 16:
		for x: int in 16:
			var key: String = ICON[y][x]
			if key != key.to_lower():
				outlined.set_pixel(x, y, ICON_COLORS[key])
	return outlined


func _hash(x: int, y: int) -> float:
	return float(((x * 374761393 + y * 668265263) ^ 0x5bd1e995) & 0xffff) / 65535.0


# SpriteFrames con los PNG sueltos (rutas por ext_resource, como los demás de resources/sprite_frames/).
func _save_frames(prefix: String, count: int, loop: bool, fps: float) -> void:
	var text: String = "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
	for i: int in count:
		text += "[ext_resource type=\"Texture2D\" path=\"%s%s_%d.png\" id=\"%d\"]\n" % [DIR, prefix, i, i + 1]
	text += "\n[resource]\nanimations = [{\n\"frames\": ["
	var items: Array[String] = []
	for i: int in count:
		items.append("{\n\"duration\": 1.0,\n\"texture\": ExtResource(\"%d\")\n}" % (i + 1))
	text += ", ".join(items)
	text += "],\n\"loop\": %s,\n\"name\": &\"default\",\n\"speed\": %.1f\n}]\n" % [str(loop).to_lower(), fps]
	var f: FileAccess = FileAccess.open(FRAMES_DIR + prefix + ".tres", FileAccess.WRITE)
	f.store_string(text)
	f.close()
