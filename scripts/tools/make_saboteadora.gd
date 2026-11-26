extends SceneTree
## Genera los sprites de la Payload: una bomba voladora de 32x32 mirando hacia arriba, que explota al
## morir. Cuerpo de bomba aérea (gota de morro redondo) con espoleta de metal y luz roja delante, franja de peligro
## granate, una ventanilla con el núcleo azul eléctrico del EMP y aletas de cola con motor.
##
## Uso: godot --headless --path . -s scripts/tools/make_saboteadora.gd
## Con `-- --preview=<carpeta>` solo escribe los PNG en esa carpeta (para enseñar el boceto).
##
## Es una figura calculada (gota, círculos, polígonos y líneas), como la Mender (make_reparadora.gd), con la
## paleta y la luz desde la izquierda de las naves base (make_base_ships.gd): casco morado, franjas y
## aletas con franja granate, luces rojas, espoleta y tobera de metal y llamas de las naves base. El núcleo usa
## la rampa azul de EmpCharge. Los FRAME_COUNT frames solo cambian la llama: el latido del núcleo y la
## luz de la espoleta los pinta EmpCharge encima (CORE_CENTER y la fila 1 del morro).
##
## Escribe assets/sprites/enemies/saboteadora/saboteadora_<frame>.png y resources/sprite_frames/saboteadora.tres.

const SPRITE_DIR: String = "res://assets/sprites/enemies/saboteadora/"
const FRAMES_PATH: String = "res://resources/sprite_frames/saboteadora.tres"
const SIZE: int = 32
const CENTER: float = 16.0
const FRAME_COUNT: int = 3
const ANIMATION_SPEED: float = 8.0
const ANIMATIONS: Array[String] = ["down", "left", "right", "up"]

const OUTLINE: Color = Color("#0a0810")
const HULL: Array[Color] = [Color("#140c1e"), Color("#221632"), Color("#462c62"), Color("#785096"), Color("#a882c8")]
const RED: Array[Color] = [Color("#2a0a1a"), Color("#561428"), Color("#8a2238"), Color("#c0384e")]
const LIGHT: Color = Color("#f0323c")
const LIGHT_DIM: Color = Color("#8c1628")
const METAL: Array[Color] = [Color("#2c303e"), Color("#545c6e"), Color("#8c96aa"), Color("#d2dceb")]
# Rampa azul del EMP (la misma que EmpCharge y EmpWave), de apagada a blanca
const BLUE: Array[Color] = [Color("#16307a"), Color("#2a6ae6"), Color("#78bcff"), Color("#e6f6ff")]
const FLAME: Array[Color] = [Color("#fff4dc"), Color("#ffdc78"), Color("#ff8c5a"), Color("#f0323c")]
# Llama de cada motor en cada frame (índices de FLAME), desde la tobera hacia atrás
const FLAMES: Array[Array] = [[1, 2, 3], [1, 1, 2, 3], [1, 2]]

# Cuerpo de la bomba: morro redondo (centro NOSE_Y, radio BODY_RADIUS) y cola que se estrecha hasta
# TAIL_RADIUS en TAIL_Y
const NOSE_Y: float = 11.0
const BODY_RADIUS: float = 7.5
const TAIL_Y: float = 24.0
const TAIL_RADIUS: float = 2.5
# Franja de peligro (filas) y ventanilla del núcleo (centro en una esquina de píxel, como EmpCharge)
const STRIPE_ROWS: Array[int] = [17, 18]
const CORE_CENTER: Vector2 = Vector2(16, 11)
const CORE_RADIUS: float = 4.0

var _image: Image


func _initialize() -> void:
	var preview_dir: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			preview_dir = arg.get_slice("=", 1)
	var folder: String = preview_dir if preview_dir != "" else ProjectSettings.globalize_path(SPRITE_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	var error: Error = OK
	var paths: Array[String] = []
	for frame: int in FRAME_COUNT:
		var file: String = "saboteadora_%d.png" % frame
		error = _draw(frame).save_png(folder.path_join(file))
		print("Guardado %s (error %d)" % [folder.path_join(file), error])
		if error != OK:
			quit(error)
			return
		paths.append(SPRITE_DIR + file)
	if preview_dir == "":
		error = _write_frames(FRAMES_PATH, paths)
	quit(error)


# --- Dibujo -------------------------------------------------------------------------------

func _draw(frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	_draw_fins()
	_draw_body()
	_draw_stripe()
	_draw_core()
	_draw_fuse()
	_outline()
	_draw_flames(frame)
	return _image


func _draw_fins() -> void:
	# Aletas de cola en flecha, moradas con el borde de ataque claro, franja granate y la punta roja
	_poly_pair(PackedVector2Array([Vector2(12, 17), Vector2(6, 24), Vector2(6, 28), Vector2(10, 28), Vector2(14, 24)]), HULL[2], HULL[1])
	_line_pair(Vector2i(11, 18), Vector2i(6, 24), HULL[4], HULL[3])
	_line_pair(Vector2i(11, 21), Vector2i(8, 25), RED[2], RED[1])
	_pixel_pair(6, 27, LIGHT, LIGHT)
	_pixel_pair(6, 26, RED[3], RED[2])
	# Tobera: cuello corto y copa que se abre hasta la llama
	_line_pair(Vector2i(14, 24), Vector2i(14, 26), METAL[1], METAL[0])
	_line_pair(Vector2i(15, 24), Vector2i(15, 26), METAL[0], METAL[0])
	_pixel_pair(13, 27, METAL[2], METAL[1])
	_pixel_pair(14, 27, METAL[1], METAL[0])
	_pixel_pair(15, 27, METAL[0], METAL[0])


func _draw_body() -> void:
	# Gota morada: morro redondo y cola que se estrecha
	for y: int in SIZE:
		for x: int in SIZE:
			var width: float = _body_width(y + 0.5)
			if width <= 0.0:
				continue
			var nx: float = (x + 0.5 - CENTER) / width
			if absf(nx) > 1.0:
				continue
			var ny: float = (y + 0.5 - (NOSE_Y + TAIL_Y) / 2.0) / ((TAIL_Y - NOSE_Y) / 2.0 + BODY_RADIUS)
			var light: float = 0.42 - 0.45 * nx - 0.3 * ny
			if absf(nx) > 0.8 or y + 0.5 < NOSE_Y - BODY_RADIUS * 0.75:
				light -= 0.2
			_pixel(x, y, HULL[clampi(roundi(light * (HULL.size() - 1)), 0, HULL.size() - 1)])
	# Costura granate a lo largo de la cola
	_line_pair(Vector2i(15, 20), Vector2i(15, 23), RED[2], RED[1])


# Media anchura del cuerpo en la altura `y` (0 fuera).
func _body_width(y: float) -> float:
	if y < NOSE_Y:
		var dy: float = (NOSE_Y - y) / BODY_RADIUS
		return BODY_RADIUS * sqrt(1.0 - dy * dy) if dy < 1.0 else 0.0
	if y > TAIL_Y:
		return 0.0
	return lerpf(BODY_RADIUS, TAIL_RADIUS, pow((y - NOSE_Y) / (TAIL_Y - NOSE_Y), 1.4))


func _draw_stripe() -> void:
	# Franja de peligro: rayas diagonales granate claras y oscuras
	for row: int in STRIPE_ROWS:
		var width: float = _body_width(row + 0.5)
		for x: int in SIZE / 2:
			if CENTER - (x + 0.5) >= width - 0.5:
				continue
			var lit: bool = (x + row) % 4 < 2
			_pixel_pair(x, row, RED[3] if lit else RED[1], RED[2] if lit else RED[0])


func _draw_core() -> void:
	# Ventanilla: aro de metal con dos reflejos y núcleo azul apagado (el latido lo pinta EmpCharge)
	_disc(CORE_CENTER, CORE_RADIUS, METAL[0])
	_disc(CORE_CENTER, CORE_RADIUS - 0.9, BLUE[0])
	_disc(CORE_CENTER, CORE_RADIUS - 1.9, BLUE[1])
	_disc(CORE_CENTER, 1.0, BLUE[2])
	_pixel(12, 9, METAL[2])
	_pixel(13, 7, METAL[2])


func _draw_fuse() -> void:
	# Espoleta en el morro: tapón de metal y luz roja apagada (se enciende con el latido, en EmpCharge)
	_pixel_pair(15, 3, METAL[3], METAL[1])
	_pixel_pair(14, 3, METAL[2], METAL[1])
	_pixel_pair(15, 2, METAL[2], METAL[1])
	_pixel_pair(15, 1, LIGHT_DIM, LIGHT_DIM)


func _draw_flames(frame: int) -> void:
	var flame: Array = FLAMES[frame]
	for i: int in flame.size():
		_pixel_pair(15, 28 + i, FLAME[flame[i]], FLAME[flame[i]])
		_pixel_pair(14, 28 + i, FLAME[mini(flame[i] + 1, FLAME.size() - 1)], FLAME[mini(flame[i] + 1, FLAME.size() - 1)])


# --- Primitivas ---------------------------------------------------------------------------

func _pixel(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		_image.set_pixel(x, y, color)


# Píxel del lado izquierdo y su espejo en sombra.
func _pixel_pair(x: int, y: int, lit: Color, shade: Color) -> void:
	_pixel(x, y, lit)
	_pixel(SIZE - 1 - x, y, shade)


func _line_pair(from: Vector2i, to: Vector2i, lit: Color, shade: Color) -> void:
	for point: Vector2i in Geometry2D.bresenham_line(from, to):
		_pixel_pair(point.x, point.y, lit, shade)


# Polígono del lado izquierdo y su espejo en sombra.
func _poly_pair(points: PackedVector2Array, lit: Color, shade: Color) -> void:
	for y: int in SIZE:
		for x: int in SIZE / 2:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_pixel_pair(x, y, lit, shade)


# Círculo relleno de píxeles enteros con el centro en una esquina de píxel.
func _disc(center: Vector2, radius: float, color: Color) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			if (Vector2(x + 0.5, y + 0.5) - center).length() <= radius:
				_pixel(x, y, color)


# Contorno de 1 px alrededor de todo lo pintado (las llamas se pintan después, sin contorno).
func _outline() -> void:
	var source: Image = _image.duplicate()
	for y: int in SIZE:
		for x: int in SIZE:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if Rect2i(0, 0, SIZE, SIZE).has_point(neighbor) and source.get_pixelv(neighbor).a > 0.0:
					_image.set_pixel(x, y, OUTLINE)
					break


# --- SpriteFrames -------------------------------------------------------------------------

# Ids de ext_resource de las texturas: los que ya tenía el archivo (para no cambiarlos) o "<n>_f".
func _texture_ids(path: String, textures: Array[String]) -> PackedStringArray:
	var old_ids: Dictionary[String, String] = {}
	if FileAccess.file_exists(path):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("[ext_resource"):
				old_ids[line.get_slice("path=\"", 1).get_slice("\"", 0)] = line.get_slice(" id=\"", 1).get_slice("\"", 0)
	var ids: PackedStringArray = []
	for i: int in textures.size():
		ids.append(old_ids.get(textures[i], "%d_f" % (i + 1)))
	return ids


# SpriteFrames con las cuatro animaciones (el giro lo hace Enemy), escrito como el resto de enemigos.
func _write_frames(path: String, textures: Array[String]) -> Error:
	var ids: PackedStringArray = _texture_ids(path, textures)
	var lines: PackedStringArray = ["[gd_resource type=\"SpriteFrames\" format=3]", ""]
	for i: int in textures.size():
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%s\"]" % [textures[i], ids[i]])
	lines.append("")
	var frames: PackedStringArray = []
	for i: int in textures.size():
		frames.append("{\n\"duration\": 1.0,\n\"texture\": ExtResource(\"%s\")\n}" % ids[i])
	var animations: PackedStringArray = []
	for animation: String in ANIMATIONS:
		animations.append("{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [", ".join(frames), animation, ANIMATION_SPEED])
	lines.append("[resource]")
	lines.append("animations = [%s]" % ", ".join(animations))
	lines.append("")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string("\n".join(lines))
	file.close()
	print("Guardado %s" % path)
	return OK
