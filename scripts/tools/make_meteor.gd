extends SceneTree
## Genera los sprites del poder del meteorito: roca en llamas (cae), chispas de la estela, marca de aviso,
## explosión con onda y cascotes, marca de quemado e icono del botón. Escribe en
## assets/sprites/effects/meteor/ (frames sueltos), assets/ui/power_meteor.png y los SpriteFrames
## meteor_fall.tres, meteor_spark.tres y meteor_explosion.tres en resources/sprite_frames/.
##
## Uso: godot --headless --path . -s scripts/tools/make_meteor.gd
## Después, importar: godot --headless --path . --import

const DIR: String = "res://assets/sprites/effects/meteor/"
const FRAMES_DIR: String = "res://resources/sprite_frames/"
const ICON_PATH: String = "res://assets/ui/power_meteor.png"

const FALL_FRAMES: int = 4
const FALL_SIZE: Vector2i = Vector2i(48, 24)
const SPARK_FRAMES: int = 4
const SPARK_SIZE: int = 8
const BLAST_FRAMES: int = 12
const BLAST_SIZE: int = 112
const WARNING_SIZE: int = 96
const SCORCH_SIZE: int = 64
# Radio del área del meteorito (Powers.METEOR_RADIUS): la onda termina en él.
const AREA_RADIUS: float = 40.0

const ROCK: Array[Color] = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6")]
# De oscuro a claro: rojo, naranja, ámbar, crema, blanco.
const FIRE: Array[Color] = [Color("#a8401a"), Color("#dc461e"), Color("#ff8c32"), Color("#ffe28c"), Color("#fff4e0")]
const SMOKE: Color = Color("#462c62")
const CLEAR: Color = Color(0, 0, 0, 0)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 11
	DirAccess.make_dir_recursive_absolute(DIR)
	for i: int in FALL_FRAMES:
		_save(_fall_frame(i), "meteor_fall_%d.png" % i)
	for i: int in SPARK_FRAMES:
		_save(_spark_frame(i), "meteor_spark_%d.png" % i)
	for i: int in BLAST_FRAMES:
		_save(_blast_frame(float(i) / (BLAST_FRAMES - 1)), "meteor_explosion_%d.png" % i)
	_save(_warning(), "meteor_warning.png")
	_save(_scorch(), "meteor_scorch.png")
	_icon().save_png(ICON_PATH)
	_save_frames("meteor_fall", "meteor_fall", FALL_FRAMES, true, 14.0)
	_save_frames("meteor_spark", "meteor_spark", SPARK_FRAMES, false, 14.0)
	_save_frames("meteor_explosion", "meteor_explosion", BLAST_FRAMES, false, 24.0)
	quit()


func _new(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _disc(img: Image, center: Vector2, radius: float, color: Color) -> void:
	for y: int in range(int(center.y - radius) - 1, int(center.y + radius) + 2):
		for x: int in range(int(center.x - radius) - 1, int(center.x + radius) + 2):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				_put(img, x, y, color)


func _save(img: Image, file: String) -> void:
	img.save_png(DIR + file)


# Roca con cabeza a la derecha y estela de fuego a la izquierda; cada frame mueve las lenguas.
func _fall_frame(index: int) -> Image:
	var img: Image = _new(FALL_SIZE.x, FALL_SIZE.y)
	var head: Vector2 = Vector2(38.5, 12.0)
	for x: int in range(2, 38):
		var t: float = (38.0 - x) / 36.0
		var half: float = lerpf(6.5, 0.5, t) + _rng.randf_range(-1.0, 1.0) * (1.0 - t * 0.5)
		var tone: int = clampi(int((1.0 - t) * 4.2 + _rng.randf_range(-0.6, 0.6)), 0, 4)
		for y: int in range(int(12 - half), int(12 + half) + 1):
			# El fuego se parte en lenguas: huecos que cambian de un frame a otro.
			if t > 0.35 and (x * 7 + y * 3 + index * 5) % 9 == 0:
				continue
			var core: float = absf(y + 0.5 - 12.0) / maxf(half, 1.0)
			_put(img, x, y, FIRE[clampi(tone - int(core * 2.0), 0, 4)])
	_disc(img, head, 8.0, FIRE[1])
	_disc(img, head, 6.5, FIRE[2])
	_disc(img, head + Vector2(1.0, 0.0), 5.0, ROCK[0])
	_disc(img, head + Vector2(1.5, -0.5), 3.5, ROCK[1])
	_disc(img, head + Vector2(2.0, -1.0), 1.5, ROCK[2])
	_put(img, 36, 14, ROCK[0])
	_put(img, 38, 15, ROCK[0])
	_put(img, 41, 10, FIRE[3])
	return img


# Chispa que se queda atrás: se encoge y se enfría por frames.
func _spark_frame(index: int) -> Image:
	var img: Image = _new(SPARK_SIZE, SPARK_SIZE)
	var c: int = SPARK_SIZE / 2
	var tone: Color = FIRE[clampi(4 - index, 0, 4)]
	_put(img, c, c, tone)
	if index < 3:
		_put(img, c - 1, c, tone)
		_put(img, c, c - 1, tone)
	if index < 2:
		_put(img, c + 1, c, tone)
		_put(img, c, c + 1, tone)
	return img


# Anillo discontinuo del radio del área sobre una sombra suave: el código lo escala al caer.
func _warning() -> Image:
	var img: Image = _new(WARNING_SIZE, WARNING_SIZE)
	var c: Vector2 = Vector2(WARNING_SIZE / 2.0, WARNING_SIZE / 2.0)
	for y: int in WARNING_SIZE:
		for x: int in WARNING_SIZE:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			var angle: float = Vector2(x + 0.5 - c.x, y + 0.5 - c.y).angle()
			if d <= AREA_RADIUS and (x + y) % 2 == 0:
				_put(img, x, y, Color(0.05, 0.03, 0.06, 0.3))
			if absf(d - AREA_RADIUS) < 0.8 and int(floor((angle + PI) / TAU * 24.0)) % 2 == 0:
				_put(img, x, y, FIRE[2])
			if absf(d - (AREA_RADIUS - 3.0)) < 0.6 and int(floor((angle + PI) / TAU * 24.0)) % 2 == 1:
				_put(img, x, y, FIRE[0])
	# Marcas en los cuatro puntos cardinales, hacia fuera.
	for k: int in 6:
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var p: Vector2i = Vector2i(int(c.x), int(c.y)) + dir * (int(AREA_RADIUS) + 2 + k)
			_put(img, p.x, p.y, FIRE[3])
	return img


# Explosión: destello, bola de fuego, onda que llega al radio del área y cascotes que salen despedidos.
func _blast_frame(t: float) -> Image:
	var img: Image = _new(BLAST_SIZE, BLAST_SIZE)
	var c: Vector2 = Vector2(BLAST_SIZE / 2.0, BLAST_SIZE / 2.0)
	var fade: float = clampf((1.0 - t) / 0.35, 0.0, 1.0)
	# Bola de fuego: crece deprisa y luego se apaga hacia el rojo oscuro y el humo.
	var radius: float = 30.0 * (1.0 - pow(1.0 - minf(t / 0.55, 1.0), 2.0)) if t < 0.9 else 0.0
	var cooled: float = clampf((t - 0.35) / 0.55, 0.0, 1.0)
	for y: int in BLAST_SIZE:
		for x: int in BLAST_SIZE:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var d: float = p.distance_to(c)
			var edge: float = radius * (1.0 + 0.18 * sin((p - c).angle() * 5.0 + t * 9.0) + _hash(x, y) * 0.12)
			if d <= edge:
				var ratio: float = d / maxf(edge, 1.0)
				var tone: int = clampi(int((1.0 - ratio) * 4.0 + 0.8 - cooled * 3.2), 0, 4)
				var color: Color = SMOKE if (cooled > 0.8 and ratio > 0.5) else FIRE[tone]
				color.a = fade if cooled > 0.5 else 1.0
				_put(img, x, y, color)
	if t < 0.12:
		_disc(img, c, 16.0 * (1.0 - t / 0.12) + 6.0, FIRE[4])
	# Onda expansiva: anillo que termina en AREA_RADIUS y se afina.
	var wave_r: float = AREA_RADIUS * (1.0 - pow(1.0 - minf(t / 0.8, 1.0), 2.0))
	var thick: float = lerpf(3.0, 1.0, t)
	if t > 0.04:
		for y: int in BLAST_SIZE:
			for x: int in BLAST_SIZE:
				var d2: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
				if absf(d2 - wave_r) < thick * 0.5 + 0.3:
					var ring: Color = FIRE[3] if t < 0.5 else FIRE[2]
					ring.a = clampf((1.0 - t) * 1.4, 0.0, 1.0)
					_put(img, x, y, ring)
	# Cascotes: 12 trozos 2x2 que salen en línea recta y se apagan al final.
	var chunks: RandomNumberGenerator = RandomNumberGenerator.new()
	chunks.seed = 5
	for i: int in 12:
		var angle: float = TAU * i / 12.0 + chunks.randf_range(-0.2, 0.2)
		var reach: float = chunks.randf_range(30.0, 50.0)
		var pos: Vector2 = c + Vector2.from_angle(angle) * reach * (1.0 - pow(1.0 - t, 3.0))
		var color: Color = ROCK[i % 3] if i % 3 != 2 else FIRE[2]
		color.a = clampf((1.0 - t) * 2.5, 0.0, 1.0)
		for off: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_put(img, int(pos.x) + off.x, int(pos.y) + off.y, color)
	return img


# Cráter quemado: borde oscuro, interior carbonizado y brasas; irregular y sin contorno duro.
func _scorch() -> Image:
	var img: Image = _new(SCORCH_SIZE, SCORCH_SIZE)
	var c: Vector2 = Vector2(SCORCH_SIZE / 2.0, SCORCH_SIZE / 2.0)
	for y: int in SCORCH_SIZE:
		for x: int in SCORCH_SIZE:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var edge: float = 30.0 + 2.0 * sin((p - c).angle() * 7.0) + _hash(x, y) * 1.5
			var d: float = p.distance_to(c)
			if d > edge:
				continue
			if d > edge - 3.0:
				_put(img, x, y, Color(0.05, 0.03, 0.06, 0.35))
			elif d > 14.0:
				_put(img, x, y, Color(0.05, 0.03, 0.06, 0.6) if (x + y) % 3 != 0 else Color(0.05, 0.03, 0.06, 0.45))
			else:
				_put(img, x, y, Color("#0c0e16"))
				if _hash(x, y) > 0.95:
					_put(img, x, y, FIRE[0])
				if _hash(y, x) > 0.985:
					_put(img, x, y, FIRE[2])
	return img


# Icono 16x16: roca gris abajo a la derecha con estela de fuego en diagonal hacia arriba a la izquierda.
func _icon() -> Image:
	var img: Image = _new(16, 16)
	for k: int in range(0, 11):
		var half: float = lerpf(0.4, 3.2, k / 10.0)
		var tone: int = clampi(int(k / 10.0 * 4.2) , 0, 4)
		for off: int in range(-int(half), int(half) + 1):
			var x: int = 1 + k + off
			var y: int = 1 + k - off
			_put(img, x, y, FIRE[clampi(tone - int(absf(off) / 1.5), 0, 4)])
	_disc(img, Vector2(10.5, 10.5), 4.6, ROCK[0])
	_disc(img, Vector2(11.0, 10.0), 3.4, ROCK[1])
	_disc(img, Vector2(11.5, 9.5), 1.6, ROCK[2])
	_put(img, 9, 12, ROCK[0])
	_put(img, 12, 12, ROCK[0])
	_put(img, 13, 2, FIRE[3])
	_put(img, 2, 12, FIRE[2])
	_put(img, 14, 5, FIRE[2])
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
