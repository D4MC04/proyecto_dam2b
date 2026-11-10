extends "res://scripts/tools/make_siege_cannon.gd"
## Genera la animación de mejora del Cañón pesado al Cañón de asedio: las piezas del nivel 1 se mueven
## y se convierten en las del nivel 2 (assets/sprites/turrets/turret2_fusion/t2_transform_sheet.png y
## resources/sprite_frames/rocket_launcher_fusion_transform.tres).
##
## Uso (después de make_siege_cannon.gd, que deja la base y el cañón del nivel 2):
##   godot --headless --path . -s scripts/tools/make_siege_transform.gd
##
## Cada frame es de 64x64 con la torreta en el centro, para que quepan las chispas y el vapor.
## Tiempos (s): 0,45 se apaga la lente; 0,55 "clac" y se parte el cañón; 0,8 el tubo viejo entra;
## 1,0 salen los tubos nuevos; 1,25 la cúpula pasa a recámara; 1,3 postes a pistones; 1,6 brazos;
## 1,35 luces a rojo; 1,6 placas de aviso; 1,75 se abren las ventanas y entran las balas; 2,25 cerrojos.

const L1_DIR: String = "res://assets/sprites/turrets/turret2/"
const TRANSFORM_PATH: String = "res://resources/sprite_frames/rocket_launcher_fusion_transform.tres"
const FRAME: int = 64
const OFFSET: int = (FRAME - SIZE) / 2
const FPS: int = 25
# Tramo de la animación que se usa (antes de START la torreta es la del nivel 1 sin cambios)
const START: float = 0.4
const END: float = 2.75
const LENS_COLOR: Color = Color("#40e0f0")
const STEAM_COLOR: Color = Color(0.59, 0.62, 0.69, 0.5)
const STEAM_LIFE: float = 0.3
const SPARK_LIFE: float = 0.3
# Luces de la base, en el orden en que pasan a rojo (en círculo), y placas de franjas de aviso
const BASE_LIGHTS: Array[Rect2i] = [Rect2i(14, 2, 4, 2), Rect2i(23, 3, 6, 6), Rect2i(27, 14, 3, 4),
	Rect2i(23, 23, 6, 6), Rect2i(14, 27, 4, 2), Rect2i(3, 23, 6, 6), Rect2i(2, 14, 3, 4), Rect2i(3, 3, 6, 6)]
const PLATES: Array[Rect2i] = [Rect2i(2, 10, 4, 12), Rect2i(26, 10, 4, 12)]

var _l1_base: Image
var _l2_base: Image
var _l1: Dictionary = {}
var _l1_dark: Dictionary = {}
var _sparks: Array[Dictionary] = []
var _steam: Array[Dictionary] = []
# Claves de las chispas y del vapor ya soltados
var _emitted: Array[String] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 3
	_l1_base = _load(L1_DIR + "t2_base.png")
	_l2_base = _load(DIR + "t2_base.png")
	var cannon: Image = _load(L1_DIR + "t2_cannon_sheet.png").get_region(Rect2i(0, 0, SIZE, SIZE))
	_l1 = _l1_pieces(cannon)
	# Lente apagada: el cian pasa al gris oscuro del metal.
	for y: int in SIZE:
		for x: int in SIZE:
			if cannon.get_pixel(x, y).is_equal_approx(LENS_COLOR):
				cannon.set_pixel(x, y, PALETTE["B"])
	_l1_dark = _l1_pieces(cannon)
	var frames: Array[Image] = []
	var count: int = roundi((END - START) * FPS)
	for i: int in count:
		frames.append(_frame(START + float(i) / FPS))
	var error: Error = _save(_sheet(frames), DIR + "t2_transform_sheet.png")
	error = maxi(error, _save_frames(count))
	quit(error)


func _load(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _blank() -> Image:
	return Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)


# Trozo de la imagen en su sitio (x0..x1, y0..y1 incluidos); el resto transparente.
func _cut(image: Image, x0: int, y0: int, x1: int, y1: int) -> Image:
	var out: Image = _blank()
	out.blit_rect(image, Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1), Vector2i(x0, y0))
	return out


func _shifted(image: Image, dx: int, dy: int) -> Image:
	var out: Image = _blank()
	for y: int in SIZE:
		for x: int in SIZE:
			var color: Color = image.get_pixel(x, y)
			if color.a > 0.0 and x + dx >= 0 and x + dx < SIZE and y + dy >= 0 and y + dy < SIZE:
				out.set_pixel(x + dx, y + dy, color)
	return out


# Deja solo las filas from_y <= y < to_y.
func _rows(image: Image, from_y: int, to_y: int) -> Image:
	var out: Image = image.duplicate()
	for y: int in SIZE:
		if y < from_y or y >= to_y:
			out.fill_rect(Rect2i(0, y, SIZE, 1), Color.TRANSPARENT)
	return out


# Deja solo las columnas a distancia <= half_width de center_x.
func _cols(image: Image, center_x: int, half_width: float) -> Image:
	var out: Image = image.duplicate()
	for x: int in SIZE:
		if absf(x - center_x) > half_width:
			out.fill_rect(Rect2i(x, 0, 1, SIZE), Color.TRANSPARENT)
	return out


func _over(dst: Image, src: Image) -> void:
	dst.blend_rect(src, Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)


func _l1_pieces(cannon: Image) -> Dictionary:
	return {
		"post_l": _cut(cannon, 7, 9, 8, 18), "post_r": _cut(cannon, 23, 9, 24, 18),
		"top_l": _cut(cannon, 9, 0, 15, 9), "top_r": _cut(cannon, 16, 0, 22, 9),
		"bot_l": _cut(cannon, 9, 10, 15, 31), "bot_r": _cut(cannon, 16, 10, 22, 31),
	}


# Piezas del nivel 2, igual que en _make_cannon (side 0 izquierda, 1 derecha).
func _cylinder(side: int) -> Image:
	var image: Image = _blank()
	_part(image, 3 + side * 21, 14, 7 + side * 21, 24)
	return image


func _arm(side: int) -> Image:
	var image: Image = _blank()
	if side == 0:
		_part(image, 4, 8, 6, 15)
		_part(image, 4, 7, 10, 10)
	else:
		_part(image, 25, 8, 27, 15)
		_part(image, 21, 7, 27, 10)
	return image


func _barrel(side: int) -> Image:
	var image: Image = _blank()
	_part(image, 9 + side * 8, 2, 14 + side * 8, 17)
	_part(image, 8 + side * 8, 0, 15 + side * 8, 3, true)
	return image


# Recámara con las balas entrando (progress 0..1) y las tapas de las ventanas (shutter 1 cerrada, 0 abierta).
func _breech(progress: float, shutter: float) -> Image:
	var image: Image = _blank()
	_part(image, 8, 15, 23, 26)
	_rect(image, 15, 16, 16, 25, "A")
	for side: int in 2:
		var sx: int = WINDOW_X[side]
		_rect(image, sx - 1, 15, sx + 3, 25, "A")
		var top: int = WINDOW_TOP + roundi((1.0 - _smooth(progress)) * SHELL_TRAVEL)
		for j: int in SHELL.size():
			for i: int in 3:
				var key: String = SHELL[j][i]
				if key != "." and top + j <= WINDOW_BOTTOM:
					_px(image, sx + i, top + j, key)
		_rect(image, sx, BOLT_Y, sx + 2, BOLT_Y, "C" if progress >= 1.0 else "B")
		# La tapa se desliza hacia fuera para abrir la ventana.
		var width: int = roundi(shutter * 3)
		if width > 0:
			var x0: int = sx if side == 0 else sx + 3 - width
			if width >= 2:
				_part(image, x0 - 1, 15, x0 + width, 25)
			else:
				_rect(image, x0, 16, x0 + width - 1, 23, "F")
	return image


func _seg(t: float, t0: float, t1: float) -> float:
	return clampf((t - t0) / (t1 - t0), 0.0, 1.0)


# Llega a 1 pasándose un poco y volviendo.
func _overshoot(q: float) -> float:
	if q >= 1.0:
		return 1.0
	return 1.0 - (1.0 - q) * (1.0 - q) + 0.2 * sin(q * PI)


func _base_at(t: float) -> Image:
	if t >= 1.9:
		return _l2_base
	var image: Image = _l1_base.duplicate()
	for k: int in BASE_LIGHTS.size():
		if t >= 1.35 + k * 0.05:
			image.blit_rect(_l2_base, BASE_LIGHTS[k], BASE_LIGHTS[k].position)
	var q: float = _seg(t, 1.6, 1.85)
	for plate: Rect2i in PLATES:
		# La placa baja desde arriba: se ve su parte de abajo asomando.
		var rows: int = roundi(q * plate.size.y)
		if rows > 0:
			image.blit_rect(_l2_base, Rect2i(plate.position.x, plate.end.y - rows, plate.size.x, rows), plate.position)
	return image


func _turret_at(t: float) -> Image:
	var l1: Dictionary = _l1_dark if t >= 0.45 else _l1
	var split: int = roundi(_smooth(_seg(t, 0.55, 0.8)) * 2)
	var layer: Image = _base_at(t).duplicate()
	# Pistones: los postes bajan y se separan; luego se ensanchan hasta ser los cilindros.
	var post_q: float = _smooth(_seg(t, 1.3, 1.45))
	var grow: float = _seg(t, 1.45, 1.6)
	for side: int in 2:
		var sign_x: int = 1 if side else -1
		if grow < 1.0:
			_over(layer, _shifted(l1["post_r" if side else "post_l"], sign_x * (split + roundi(post_q * 2)), roundi(post_q * 5)))
		if grow > 0.0:
			_over(layer, _cols(_cylinder(side), 26 if side else 5, 0.5 + grow * 2.0))
	# Brazos: salen del cilindro y suben hasta el cañón.
	if t >= 1.6:
		var arm_q: float = _overshoot(_seg(t, 1.6, 1.75))
		for side: int in 2:
			# Mientras sube no tapa el cilindro; al llegar, el vástago entra en él.
			_over(layer, _rows(_shifted(_arm(side), 0, roundi((1.0 - arm_q) * 7)), 0, 14 if t < 1.75 else SIZE))
	# Cañones: el tubo viejo se mete en la cúpula y por ahí salen los dos nuevos.
	var retract: float = _smooth(_seg(t, 0.8, 1.0))
	var extend: float = _overshoot(_seg(t, 1.0, 1.25))
	# Fila hasta la que la cúpula ya es recámara
	var wipe: int = 10 + roundi(_seg(t, 1.25, 1.45) * 18)
	var dome_top: int = wipe if t >= 1.25 else 10
	for side: int in 2:
		var dx: int = (1 if side else -1) * split
		if retract < 1.0:
			_over(layer, _rows(_shifted(l1["top_r" if side else "top_l"], dx, roundi(retract * 10)), 0, 10))
		if t >= 1.0:
			_over(layer, _rows(_shifted(_barrel(side), 0, roundi((1.0 - extend) * 12)), 0, dome_top))
		_over(layer, _rows(_shifted(l1["bot_r" if side else "bot_l"], dx, 0), dome_top, SIZE))
	if t >= 1.25:
		_over(layer, _rows(_breech(_seg(t, 1.9, 2.25), 1.0 - _seg(t, 1.75, 1.9)), 0, wipe))
		# Línea naranja por donde va la transformación de la cúpula
		if wipe < 28:
			_rect(layer, 8, wipe, 23, wipe, "H")
	return layer


func _frame(t: float) -> Image:
	var image: Image = Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(FRAME, FRAME) / 2.0
	# "Clac": la torreta baja 1 px al desbloquearse y al cerrar los cerrojos.
	var dy: int = 1 if (t >= 0.55 and t < 0.6) or (t >= 2.25 and t < 2.31) else 0
	var corner: Vector2i = Vector2i(OFFSET, OFFSET + dy)
	if t >= 0.55:
		_emit("unlock", [center + Vector2(0, -6)], 25.0, t)
	if t >= 2.25:
		_emit("lock", [Vector2(corner) + Vector2(11, 24), Vector2(corner) + Vector2(20, 24)], 30.0, t)
		if not _emitted.has("steam"):
			_emitted.append("steam")
			for side: int in [-1, 1]:
				for k: int in 3:
					_steam.append({"pos": center + Vector2(side * 12, 3), "vel": Vector2(side * (8 + k * 5), -5 - k * 3), "born": 2.3 + k * 0.05})
	image.blend_rect(_turret_at(t), Rect2i(0, 0, SIZE, SIZE), corner)
	for spark: Dictionary in _sparks:
		var age: float = t - float(spark["born"])
		if age >= 0.0 and age <= SPARK_LIFE:
			var pos: Vector2 = (spark["pos"] as Vector2) + (spark["vel"] as Vector2) * age
			_px(image, roundi(pos.x), roundi(pos.y), "Y" if age < 0.12 else "H")
	for puff: Dictionary in _steam:
		var age: float = t - float(puff["born"])
		if age >= 0.0 and age < STEAM_LIFE:
			var color: Color = STEAM_COLOR
			color.a *= 1.0 - age / STEAM_LIFE
			_disc(image, (puff["pos"] as Vector2) + (puff["vel"] as Vector2) * age, 1.0 + age * 4.0, color)
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


func _save_frames(count: int) -> Error:
	var text: String = '[gd_resource type="SpriteFrames" format=3]\n\n'
	text += '[ext_resource type="Texture2D" path="%st2_transform_sheet.png" id="1"]\n\n' % DIR
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
