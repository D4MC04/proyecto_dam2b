extends SceneTree
## Genera la animación de mejora del Cañón cuádruple (nivel 2) a la Lanza dorada (nivel 3): cada pieza
## del nivel 2 se mueve y se convierte en una del nivel 3 (assets/sprites/turrets/turret_level3/
## t1_transform_sheet.png y resources/sprite_frames/turret_level3_transform.tres).
##
## Uso (si cambian los sprites del nivel 2 o del 3, volver a lanzarlo):
##   godot --headless --path . -s scripts/tools/make_quad_lance_transform.gd
##
## Parte de los sprites que ya hay (base y frame 0 del cañón de cada nivel) y los recorta en piezas.
## Cada frame es de 64x64 con la torreta en el centro, para que quepan las chispas y el vapor.
## Tiempos (s): 0,08 las luces de la base pasan a oro en círculo; 0,36 entran las placas de las
## esquinas y a 0,6 encajan con un "clac"; 0,66 los dos cañones de cada cápsula se juntan; 0,84 se
## estiran hasta la fila 0; 1,02 se abre el freno oro con chispas; 1,08 las cápsulas se apartan;
## 1,24 las chapas se doblan hacia delante (vapor); 1,44 sube la cuña; 1,62 la lente se alarga hasta
## ser la franja oro; 1,74 el bloque de atrás se abre en los cargadores; 1,88 se abren las ventanas;
## 1,96 entra el dardo; 2,06 la abrazadera cierra con "clac" y vapor. Termina en la Lanza en reposo.

const L2_DIR: String = "res://assets/sprites/turrets/turret_fusion/"
const DIR: String = "res://assets/sprites/turrets/turret_level3/"
const TRANSFORM_PATH: String = "res://resources/sprite_frames/turret_level3_transform.tres"
const SIZE: int = 32
const FRAME: int = 64
const OFFSET: int = (FRAME - SIZE) / 2
const FPS: int = 25
const DURATION: float = 2.24
const OUTLINE: Color = Color("#0c0e16")
const DARK: Color = Color("#343a4a")
const MID: Color = Color("#606a7c")
const LIGHT: Color = Color("#96a2b6")
const SPARK_HOT: Color = Color("#fff8e6")
const SPARK: Color = Color("#ecb23c")
const STEAM_COLOR: Color = Color(0.59, 0.62, 0.69, 0.5)
const STEAM_LIFE: float = 0.12
const SPARK_LIFE: float = 0.3
# Verde del nivel 2 -> oro del nivel 3
const GREEN: Array[String] = ["1c7440", "3cb860", "c4f5d0", "0e3a24"]
const GOLD: Array[String] = ["96641e", "ecb23c", "ffe082", "4a3210"]
# Ventana de la recarga de la cápsula izquierda (la derecha es su espejo)
const WINDOW: Rect2i = Rect2i(3, 15, 7, 2)
# Bisagra de la chapa que se dobla hasta ser la cuchilla (cápsula izquierda)
const HINGE: Vector2 = Vector2(3.0, 13.0)
const BLADE_LENGTH: float = 5.7

var _l2_base: Image
var _l3_base: Image
var _l2: Image
var _l3: Image
# Frames de la recarga con la abrazadera destellando (izquierda y derecha)
var _l3_flash: Array[Image] = []
var _lights: Array[Dictionary] = []
var _plates: Array[Image] = []
var _sparks: Array[Dictionary] = []
var _steam: Array[Dictionary] = []
# Claves de las chispas y del vapor ya soltados
var _emitted: Array[String] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 7
	_l2_base = _load(L2_DIR + "t1_base.png")
	_l3_base = _load(DIR + "t1_base.png")
	_l2 = _load(L2_DIR + "t1_cannon_sheet.png").get_region(Rect2i(0, 0, SIZE, SIZE))
	var l3_sheet: Image = _load(DIR + "t1_cannon_sheet.png")
	_l3 = l3_sheet.get_region(Rect2i(0, 0, SIZE, SIZE))
	_l3_flash = [l3_sheet.get_region(Rect2i(3 * SIZE, 0, SIZE, SIZE)), l3_sheet.get_region(Rect2i(6 * SIZE, 0, SIZE, SIZE))]
	_prepare_base()
	var frames: Array[Image] = []
	var count: int = roundi(DURATION * FPS)
	for i: int in count:
		frames.append(_frame(float(i) / FPS))
	# El último frame es la Lanza dorada en reposo, sin chispas ni vapor.
	var rest: Image = _blank_frame()
	var composite: Image = _l3_base.duplicate()
	_over(composite, _l3)
	rest.blit_rect(composite, Rect2i(0, 0, SIZE, SIZE), Vector2i(OFFSET, OFFSET))
	if not frames[count - 1].get_data() == rest.get_data():
		push_warning("El final de la animación no coincide con el reposo; se fuerza el último frame")
	frames[count - 1] = rest
	var error: Error = _save(_sheet(frames), DIR + "t1_transform_sheet.png")
	error = maxi(error, _save_frames(count))
	quit(error)


func _load(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _blank() -> Image:
	return Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)


func _blank_frame() -> Image:
	return Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)


# Rectángulo x0..x1, y0..y1 (incluidos) de la mitad izquierda; en la derecha (side 1) su espejo.
func _side_rect(side: int, x0: int, y0: int, x1: int, y1: int) -> Rect2i:
	if side == 1:
		var mirrored: int = SIZE - 1 - x1
		x1 = SIZE - 1 - x0
		x0 = mirrored
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


# Trozo de la imagen en su sitio; el resto transparente.
func _cut(image: Image, rect: Rect2i) -> Image:
	var out: Image = _blank()
	out.blit_rect(image, rect, rect.position)
	return out


func _shifted(image: Image, dx: int, dy: int) -> Image:
	var out: Image = _blank()
	out.blit_rect(image, Rect2i(0, 0, SIZE, SIZE), Vector2i(dx, dy))
	return out


# Deja solo las filas from_y <= y <= to_y.
func _rows(image: Image, from_y: int, to_y: int) -> Image:
	var out: Image = image.duplicate()
	for y: int in SIZE:
		if y < from_y or y > to_y:
			out.fill_rect(Rect2i(0, y, SIZE, 1), Color.TRANSPARENT)
	return out


func _over(dst: Image, src: Image) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i.ZERO)


func _gold(image: Image) -> Image:
	var out: Image = image.duplicate()
	for y: int in SIZE:
		for x: int in SIZE:
			var index: int = GREEN.find(out.get_pixel(x, y).to_html(false))
			if index >= 0:
				out.set_pixel(x, y, Color("#" + GOLD[index]))
	return out


func _seg(t: float, t0: float, t1: float) -> float:
	return clampf((t - t0) / (t1 - t0), 0.0, 1.0)


func _smooth(q: float) -> float:
	q = clampf(q, 0.0, 1.0)
	return q * q * (3.0 - 2.0 * q)


# Llega a 1 pasándose un poco y volviendo.
func _overshoot(q: float, amount: float = 0.2) -> float:
	if q >= 1.0:
		return 1.0
	return 1.0 - (1.0 - q) * (1.0 - q) + amount * sin(q * PI)


# Luces de la base (píxeles que cambian del nivel 2 al 3) ordenadas en círculo desde arriba, y las
# cuatro placas de las esquinas (lo que el nivel 3 tiene y el 2 no).
func _prepare_base() -> void:
	for k: int in 4:
		_plates.append(_blank())
	for y: int in SIZE:
		for x: int in SIZE:
			var before: Color = _l2_base.get_pixel(x, y)
			var after: Color = _l3_base.get_pixel(x, y)
			if before.a == 0.0 and after.a > 0.0:
				_plates[(1 if x >= SIZE / 2 else 0) + (2 if y >= SIZE / 2 else 0)].set_pixel(x, y, after)
			elif before != after:
				var angle: float = fposmod(atan2(x - 15.5, 15.5 - y), TAU)
				_lights.append({"pos": Vector2i(x, y), "color": after, "at": 0.08 + angle / TAU * 0.28})


func _base_at(t: float) -> Image:
	var image: Image = _blank()
	# Las placas entran en diagonal desde fuera, por debajo de la base, y encajan en su esquina.
	var q: float = _seg(t, 0.36, 0.6)
	if q > 0.0:
		var away: int = roundi((1.0 - q) * (1.0 - q) * 7)
		for k: int in 4:
			var dx: int = away if k % 2 else -away
			var dy: int = away if k >= 2 else -away
			_over(image, _shifted(_plates[k], dx, dy))
	var base: Image = _l2_base.duplicate()
	for light: Dictionary in _lights:
		if t >= float(light["at"]):
			base.set_pixelv(light["pos"], light["color"])
	_over(image, base)
	return image


# Cápsula del nivel 3 con la ventana cerrada, abriéndose, vacía, con el dardo entrando o cargada.
func _pod_l3(side: int, t: float) -> Image:
	var source: Image = _l3
	if t >= 2.06 and t < 2.14:
		source = _l3_flash[side]
	var pod: Image = _cut(source, _side_rect(side, 0, 13, 10, 22))
	if t >= 2.06:
		return pod
	var window: Rect2i = _side_rect(side, WINDOW.position.x, WINDOW.position.y, WINDOW.end.x - 1, WINDOW.end.y - 1)
	var opened: int = roundi(_seg(t, 1.88, 1.96) * WINDOW.size.x)
	var dart_in: int = roundi((1.0 - _smooth(_seg(t, 1.96, 2.06))) * WINDOW.size.x)
	for y: int in range(window.position.y, window.end.y):
		for i: int in WINDOW.size.x:
			# i cuenta desde el lado de dentro de la cápsula, por donde se abre la tapa y entra el dardo.
			var x: int = window.end.x - 1 - i if side == 0 else window.position.x + i
			var color: Color = MID if i >= opened else DARK
			if t >= 1.96 and i < WINDOW.size.x - dart_in:
				var from_x: int = x - dart_in if side == 0 else x + dart_in
				color = _l3.get_pixel(from_x, y)
			pod.set_pixel(x, y, color)
	return pod


# Chapa de la cápsula doblándose hacia delante: q 0 pegada al costado, 1 en diagonal como la cuchilla.
func _flap(layer: Image, side: int, q: float) -> void:
	var angle: float = lerpf(PI / 2.0, deg_to_rad(255.0), q)
	var direction: Vector2 = Vector2.from_angle(angle)
	var core: Dictionary = {}
	var steps: int = roundi(BLADE_LENGTH * 2.0)
	for k: int in steps + 1:
		var point: Vector2 = HINGE + direction * (k * 0.5)
		core[Vector2i(roundi(point.x), roundi(point.y))] = LIGHT
	var shape: Dictionary = core.duplicate()
	for pixel: Vector2i in core:
		var inner: Vector2i = pixel + Vector2i(1, 0)
		if not shape.has(inner):
			shape[inner] = MID
	var outline: Dictionary = {}
	for pixel: Vector2i in shape:
		for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if not shape.has(pixel + offset):
				outline[pixel + offset] = OUTLINE
	for pixels: Dictionary in [outline, shape]:
		for pixel: Vector2i in pixels:
			var x: int = pixel.x if side == 0 else SIZE - 1 - pixel.x
			if x >= 0 and x < SIZE and pixel.y >= 0 and pixel.y < SIZE:
				layer.set_pixel(x, pixel.y, pixels[pixel])


# Cuña del nivel 3 con la franja de oro solo a reach filas del centro de la lente (fila 16,5).
func _wedge(rise: int, reach: float) -> Image:
	var wedge: Image = _shifted(_cut(_l3, Rect2i(11, 5, 10, 18)), 0, rise)
	for y: int in SIZE:
		for x: int in [15, 16]:
			var color: Color = wedge.get_pixel(x, y)
			if color.a > 0.0 and color != OUTLINE and absf(y - 16.5) > reach and color.r > color.b + 0.1:
				wedge.set_pixel(x, y, MID)
	return _rows(wedge, 0, 22)


func _turret_at(t: float) -> Image:
	var layer: Image = _base_at(t)
	# 6. El bloque de atrás se parte en dos y cada mitad va a su cargador.
	if t < 1.88:
		var open: int = roundi(_smooth(_seg(t, 1.74, 1.88)) * 7)
		for side: int in 2:
			var half: Image = _cut(_l2, _side_rect(side, 11, 24, 15, 26))
			_over(layer, _shifted(half, open if side else -open, 0))
	else:
		for side: int in 2:
			_over(layer, _cut(_l3, _side_rect(side, 4, 23, 9, 26)))
	# 5. El cuerpo central sube hasta formar la cuña y la lente se alarga hasta ser la franja.
	if t < 1.88:
		var body: Image = _cut(_l2, Rect2i(12, 10, 8, 4))
		_over(body, _cut(_l2, Rect2i(13, 14, 6, 10)))
		_over(layer, body)
	if t >= 1.88:
		_over(layer, _cut(_l3, Rect2i(11, 5, 10, 20)))
	elif t >= 1.44:
		var rise: int = roundi((1.0 - _smooth(_seg(t, 1.44, 1.7))) * 5)
		_over(layer, _wedge(rise, 1.0 + _smooth(_seg(t, 1.62, 1.8)) * 12.0))
	for side: int in 2:
		var inward: int = -1 if side else 1
		# 4. Las cápsulas se apartan hacia fuera y la chapa de fuera se dobla hasta ser la cuchilla.
		if t < 1.24:
			var pod: Image = _cut(_l2, _side_rect(side, 4, 13, 12, 23))
			pod.fill_rect(_side_rect(side, 4, 13, 12, 13), OUTLINE)
			if t >= 1.08:
				pod = _gold(pod)
			_over(layer, _shifted(pod, -inward * roundi(_smooth(_seg(t, 1.08, 1.24)) * 3), 0))
		else:
			_over(layer, _pod_l3(side, t))
		if t >= 1.48:
			_over(layer, _cut(_l3, _side_rect(side, 0, 7, 6, 12)))
		elif t >= 1.24:
			_flap(layer, side, _overshoot(_seg(t, 1.24, 1.48)))
		# 3. El cañón de fuera se mete en el de dentro; ese se estira hasta la fila 0 y se abre el freno.
		if t >= 1.1:
			_over(layer, _cut(_l3, _side_rect(side, 6, 0, 11, 3)))
			_over(layer, _cut(_l3, _side_rect(side, 7, 4, 10, 12)))
			continue
		var join: float = _smooth(_seg(t, 0.66, 0.84))
		if join < 1.0:
			_over(layer, _shifted(_cut(_l2, _side_rect(side, 6, 7, 9, 13)), inward * roundi(join), 0))
		var dx: int = -inward * roundi(join * 2)
		var up: int = roundi(_overshoot(_seg(t, 0.84, 1.02), 0.35) * 3)
		var tube_row: Image = _cut(_l2, _side_rect(side, 9, 6, 12, 6))
		for y: int in range(6 - up, 14):
			_over(layer, _shifted(tube_row, dx, y - 6))
		_over(layer, _shifted(_cut(_l2, _side_rect(side, 8, 3, 13, 5)), dx, -up))
		var wipe: int = roundi(_seg(t, 1.02, 1.1) * 4)
		if wipe > 0:
			_over(layer, _rows(_cut(_l3, _side_rect(side, 6, 0, 11, 3)), 0, wipe - 1))
	return layer


func _frame(t: float) -> Image:
	var image: Image = _blank_frame()
	# "Clac": la torreta baja 1 px al encajar las placas y al cerrar la abrazadera.
	var dy: int = 1 if (t >= 0.6 and t < 0.68) or (t >= 2.06 and t < 2.14) else 0
	var corner: Vector2 = Vector2(OFFSET, OFFSET + dy)
	if t >= 0.6:
		_emit("plates", [corner + Vector2(2, 2), corner + Vector2(29, 2), corner + Vector2(2, 29), corner + Vector2(29, 29)], 22.0, t)
	if t >= 1.02:
		_emit("brakes", [corner + Vector2(8.5, 1), corner + Vector2(22.5, 1)], 25.0, t)
	if t >= 1.3 and not _emitted.has("hinges"):
		_emitted.append("hinges")
		for side: int in [-1, 1]:
			for k: int in 2:
				_steam.append({"pos": corner + Vector2(15.5 + side * 13.0, 13), "vel": Vector2(side * (10 + k * 6), -6 - k * 4), "born": 1.3 + k * 0.04})
	if t >= 2.06 and not _emitted.has("clamps"):
		_emitted.append("clamps")
		for side: int in [-1, 1]:
			for k: int in 2:
				_steam.append({"pos": corner + Vector2(15.5 + side * 16.0, 16), "vel": Vector2(side * (12 + k * 6), -4 - k * 3), "born": 2.06 + k * 0.02})
	image.blend_rect(_turret_at(t), Rect2i(0, 0, SIZE, SIZE), Vector2i(corner))
	for spark: Dictionary in _sparks:
		var age: float = t - float(spark["born"])
		if age >= 0.0 and age <= SPARK_LIFE:
			var pos: Vector2 = (spark["pos"] as Vector2) + (spark["vel"] as Vector2) * age
			var x: int = roundi(pos.x)
			var y: int = roundi(pos.y)
			if x >= 0 and y >= 0 and x < FRAME and y < FRAME:
				image.set_pixel(x, y, SPARK_HOT if age < 0.12 else SPARK)
	for puff: Dictionary in _steam:
		var age: float = t - float(puff["born"])
		if age >= 0.0 and age < STEAM_LIFE:
			var color: Color = STEAM_COLOR
			color.a *= 1.0 - age / STEAM_LIFE
			_disc(image, (puff["pos"] as Vector2) + (puff["vel"] as Vector2) * age, 1.0 + age * 6.0, color)
	return image


# Chispas que salen en todas direcciones desde cada punto (una sola vez por clave).
func _emit(key: String, points: Array[Vector2], speed: float, t: float) -> void:
	if _emitted.has(key):
		return
	_emitted.append(key)
	for point: Vector2 in points:
		for i: int in 4:
			var velocity: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.4, 1.0) * speed
			_sparks.append({"pos": point, "vel": velocity, "born": t})


func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	for y: int in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if x >= 0 and y >= 0 and x < FRAME and y < FRAME and Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, image.get_pixel(x, y).blend(color))


func _sheet(frames: Array[Image]) -> Image:
	var sheet: Image = Image.create(FRAME * frames.size(), FRAME, false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, FRAME, FRAME), Vector2i(i * FRAME, 0))
	return sheet


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("No se pudo guardar %s" % path)
	return error


func _save_frames(count: int) -> Error:
	var text: String = '[gd_resource type="SpriteFrames" format=3]\n\n'
	text += '[ext_resource type="Texture2D" path="%st1_transform_sheet.png" id="1"]\n\n' % DIR
	var frames: PackedStringArray = []
	for i: int in count:
		text += '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("1")\n' % i
		text += "region = Rect2(%d, 0, %d, %d)\n\n" % [i * FRAME, FRAME, FRAME]
		frames.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % i)
	text += "[resource]\nanimations = [{\n"
	text += '"frames": [%s],\n' % ", ".join(frames)
	text += '"loop": false,\n"name": &"default",\n"speed": %d.0\n}]\n' % FPS
	var file: FileAccess = FileAccess.open(TRANSFORM_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar %s" % TRANSFORM_PATH)
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK
