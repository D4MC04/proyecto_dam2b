extends SceneTree
## Genera los sprites de la Mender: insecto chupador de 32x32 mirando hacia arriba, con una aguja
## delante (de su punta sale el rayo) y un saco de vida verde colgando detrás que se encoge al curar.
##
## Uso: godot --headless --path . -s scripts/tools/make_reparadora.gd
##
## Es una figura calculada (elipses, polígonos y líneas), como la Ram y la Mothership de
## make_base_ships.gd, con su paleta y su luz desde la izquierda: cabeza, tórax y alas en flecha en
## morado, columna y bandas del saco en granate, ojos y luces de las alas rojas, aguja y toberas de
## metal y llamas de las naves base. El saco usa la rampa verde de HealEffect.
## Hay LEVELS tamaños de saco, de lleno a casi vacío (cada vez más pequeño y oscuro, arrugado al final),
## y cada uno tiene sus FRAME_COUNT frames (late la punta de la aguja, brilla el saco y cambia la llama).
##
## Escribe assets/sprites/enemies/reparadora/reparadora_<nivel>_<frame>.png y sus SpriteFrames:
## resources/sprite_frames/reparadora.tres (lleno) y reparadora_<nivel>.tres (los demás).

const SPRITE_DIR: String = "res://assets/sprites/enemies/reparadora/"
const FRAMES_DIR: String = "res://resources/sprite_frames/"
const SIZE: int = 32
const CENTER: float = 16.0
const LEVELS: int = 5
const FRAME_COUNT: int = 3
const ANIMATION_SPEED: float = 8.0
const ANIMATIONS: Array[String] = ["down", "left", "right", "up"]

const OUTLINE: Color = Color("#0a0810")
const HULL: Array[Color] = [Color("#140c1e"), Color("#221632"), Color("#462c62"), Color("#785096"), Color("#a882c8")]
const RED: Array[Color] = [Color("#2a0a1a"), Color("#561428"), Color("#8a2238"), Color("#c0384e")]
const LIGHT: Color = Color("#f0323c")
const METAL: Array[Color] = [Color("#2c303e"), Color("#545c6e"), Color("#8c96aa"), Color("#d2dceb")]
const GREEN: Array[Color] = [Color("#0e3a24"), Color("#1c7440"), Color("#3cb860"), Color("#7ee89a"), Color("#c4f5d0")]
const FLAME: Array[Color] = [Color("#fff4dc"), Color("#ffdc78"), Color("#ff8c5a"), Color("#f0323c")]
# Llama de cada motor en cada frame (índices de FLAME), desde la tobera hacia atrás
const FLAMES: Array[Array] = [[1, 2, 3], [1, 1, 2, 3], [1, 2]]

# Saco: radio con el saco lleno y casi vacío, y fila de arriba (pegada al tórax)
const SAC_RADIUS_FULL: float = 7.0
const SAC_RADIUS_EMPTY: float = 3.0
const SAC_TOP: float = 16.0

var _image: Image


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITE_DIR))
	var error: Error = OK
	for level: int in LEVELS:
		var paths: Array[String] = []
		for frame: int in FRAME_COUNT:
			var path: String = SPRITE_DIR + "reparadora_%d_%d.png" % [level, frame]
			error = _draw(level, frame).save_png(ProjectSettings.globalize_path(path))
			print("Guardado %s (error %d)" % [path, error])
			if error != OK:
				quit(error)
				return
			paths.append(path)
		var frames_path: String = FRAMES_DIR + ("reparadora.tres" if level == 0 else "reparadora_%d.tres" % level)
		error = _write_frames(frames_path, paths)
		if error != OK:
			break
	quit(error)


# --- Dibujo -------------------------------------------------------------------------------

func _draw(level: int, frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# Lo que queda del saco: 1 lleno, 0 casi vacío
	var fill: float = 1.0 - float(level) / (LEVELS - 1)
	_draw_wings()
	_draw_sac(fill, level, frame)
	_draw_body()
	_draw_needle(frame)
	_outline()
	_draw_flames(frame)
	return _image


func _draw_wings() -> void:
	# Alas finas en flecha que salen del tórax, con el borde de ataque claro y una franja granate
	_poly_pair(PackedVector2Array([Vector2(13, 11), Vector2(3, 17), Vector2(2, 20), Vector2(5, 20), Vector2(13, 15)]), HULL[2], HULL[1])
	_line_pair(Vector2i(12, 11), Vector2i(3, 17), HULL[4], HULL[3])
	_line_pair(Vector2i(11, 14), Vector2i(5, 18), RED[3], RED[2])
	_pixel_pair(2, 20, LIGHT, LIGHT)
	# Tobera metida en el borde de salida de cada ala, por fuera del saco lleno
	_pixel_pair(4, 19, METAL[2], METAL[1])
	_pixel_pair(5, 19, METAL[1], METAL[0])


func _draw_sac(fill: float, level: int, frame: int) -> void:
	var radius: float = lerpf(SAC_RADIUS_EMPTY, SAC_RADIUS_FULL, fill)
	var center_y: float = SAC_TOP + radius
	# Cada vez más oscuro al vaciarse: se quitan tonos claros de arriba de la rampa
	var ramp: Array[Color] = GREEN.slice(0, GREEN.size() - mini(level, 2))
	if level >= LEVELS - 1:
		ramp = [GREEN[0], GREEN[0], GREEN[1], GREEN[1], GREEN[2]]
	_ellipse(CENTER, center_y, radius, radius * 1.05, ramp)
	# Bandas de membrana granate, curvadas con el saco
	for side: int in [-1, 1]:
		for x: int in SIZE:
			var nx: float = (x + 0.5 - CENTER) / radius
			if absf(nx) > 0.8:
				continue
			var y: int = roundi(center_y + side * radius * 0.45 + side * nx * nx * radius * 0.15)
			_pixel(x, y, RED[2] if x < CENTER else RED[1])
	# Brillo arriba a la izquierda, que late en el frame 1
	if level < LEVELS - 1:
		var shine: Vector2i = Vector2i(roundi(CENTER - radius * 0.45), roundi(center_y - radius * 0.6))
		_pixel(shine.x, shine.y, GREEN[4])
		if frame == 1 and radius > 4.0:
			_pixel(shine.x + 1, shine.y, GREEN[4])
	else:
		# Arrugas del saco casi vacío
		_pixel(15, roundi(center_y), GREEN[0])
		_pixel(17, roundi(center_y) + 1, GREEN[0])
	# Cuello que une el saco al tórax
	_pixel_pair(15, 16, RED[2], RED[1])


func _draw_body() -> void:
	# Tórax con la columna granate
	_ellipse(CENTER, 13.5, 4.5, 3.0, HULL)
	_line_pair(Vector2i(15, 11), Vector2i(15, 15), RED[2], RED[1])
	_pixel_pair(15, 12, RED[3], RED[2])
	# Cabeza con dos ojos rojos
	_ellipse(CENTER, 8.5, 3.0, 2.4, HULL, 0.1)
	_pixel_pair(14, 8, LIGHT, LIGHT)
	_pixel_pair(14, 9, RED[2], RED[1])


func _draw_needle(frame: int) -> void:
	_line_pair(Vector2i(15, 2), Vector2i(15, 6), METAL[3] if frame == 0 else METAL[2], METAL[1])
	_pixel_pair(15, 6, RED[2], RED[1])
	# Punta verde que late
	_pixel_pair(15, 1, GREEN[4] if frame == 2 else GREEN[3], GREEN[3] if frame == 2 else GREEN[2])
	if frame == 2:
		_pixel_pair(15, 0, GREEN[2], GREEN[1])


func _draw_flames(frame: int) -> void:
	var flame: Array = FLAMES[frame]
	for i: int in flame.size():
		_pixel_pair(4, 20 + i, FLAME[flame[i]], FLAME[flame[i]])
		_pixel_pair(5, 20 + i, FLAME[flame[i]], FLAME[flame[i]])


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


# Elipse sombreada con la luz arriba a la izquierda y el borde más oscuro.
func _ellipse(center_x: float, center_y: float, radius_x: float, radius_y: float, ramp: Array[Color], bias: float = 0.0) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			var nx: float = (x + 0.5 - center_x) / radius_x
			var ny: float = (y + 0.5 - center_y) / radius_y
			var distance: float = nx * nx + ny * ny
			if distance > 1.0:
				continue
			var light: float = 0.55 - 0.45 * nx - 0.3 * ny + bias
			if distance > 0.7:
				light -= 0.2
			_pixel(x, y, ramp[clampi(roundi(light * (ramp.size() - 1)), 0, ramp.size() - 1)])


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
