extends SceneTree
## Redibuja con las naves base nuevas las dos piezas del tileset de espacio que son naves: la nave
## estrellada animada (espacio_animados.png, casilla (0, 8), 3x3, 6 frames) y el casco roto de los restos
## (espacio_rocas.png, casilla (6, 6), 2x2). Mantiene el tamaño y el sitio de cada pieza en el atlas.
##
## Uso: godot --headless --path . -s scripts/tools/make_ship_wrecks.gd
##
## Las naves salen de las plantillas de make_base_ships.gd (mismo casco, paleta y luz), sin llamas:
## - Nave estrellada: el Cruiser girado con la proa clavada en una roca gris de 2x2 del atlas de rocas,
##   la punta de un ala arrancada, quemaduras y trozos de casco alrededor. Por frame, el humo sube desde
##   el choque, un motor chisporrotea y una luz roja parpadea.
## - Casco roto: el Juggernaut partido (sin la proa ni la punta de un ala), con el borde del corte en
##   metal al aire y quemaduras.

const BaseShips: GDScript = preload("res://scripts/tools/make_base_ships.gd")

const TILE: int = 16
const ANIMATED_PATH: String = "res://assets/tilesets/espacio/espacio_animados.png"
const ROCKS_PATH: String = "res://assets/tilesets/espacio/espacio_rocas.png"
const SHIP_SIZE: int = 32

# Nave estrellada: casilla, tamaño en casillas y frames (en fila, como en el tileset)
const CRASH_CELL: Vector2i = Vector2i(0, 8)
const CRASH_TILES: int = 3
const CRASH_FRAMES: int = 6
# Roca gris de 2x2 del atlas de rocas en la que se clava la nave, y dónde va dentro del frame
const CRASH_ROCK_CELL: Vector2i = Vector2i(0, 4)
const CRASH_ROCK_AT: Vector2i = Vector2i(17, 8)
# Dónde va la nave girada dentro del frame, y la zona de la cabina, que parpadea
const CRASH_SHIP_AT: Vector2i = Vector2i(-5, 8)
const CABIN_AREA: Rect2i = Rect2i(14, 18, 8, 9)

# Casco roto: casilla y tamaño en casillas
const HULL_CELL: Vector2i = Vector2i(6, 6)
const HULL_TILES: int = 2

# Dientes del borde de los cortes, para que no salgan rectos
const JAG: Array[int] = [0, 1, 1, 2, 1, 0, -1, -1, 0, 1, 2, 2, 1, 0, -1, 0]

# Humo: tono de cada fase de una bocanada, de recién salida a casi deshecha
const SMOKE_SHADES: Array[String] = ["w", "s", "s", "m", "m", "m"]
const SMOKE_START: Vector2i = Vector2i(20, 12)
# Tamaño de la bocanada en cada fase: cruz de 3 px, cuadrado de 2 y punto
const SMOKE_SIZES: Array[int] = [3, 3, 2, 2, 1, 1]

# Trozos de casco sueltos junto a la nave estrellada (plantilla y esquina en el frame)
const DEBRIS: Array[Array] = [
	[["OO.", "OHO", ".OO"], Vector2i(13, 40)],
	[[".O.", "OMO", ".O."], Vector2i(27, 39)],
	[["OOO.", "OHMO", ".OOO"], Vector2i(31, 4)],
]


func _initialize() -> void:
	var error: Error = _make_crash()
	if error == OK:
		error = _make_hull()
	quit(error)


# Imagen de 32x32 de una nave base, mirando hacia arriba y sin llamas.
func _render_ship(half: Array[String]) -> Image:
	var palette: Dictionary = BaseShips.PALETTE
	var shade_swap: Dictionary = BaseShips.SHADE_SWAP
	var image: Image = Image.create(SHIP_SIZE, SHIP_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SHIP_SIZE:
		for x: int in SHIP_SIZE / 2:
			var key: String = half[y][x]
			if key == ".":
				continue
			image.set_pixel(x, y, palette[key])
			image.set_pixel(SHIP_SIZE - 1 - x, y, palette[shade_swap.get(key, key)])
	return image


# Quita los píxeles que keep() no guarda y pinta el borde del corte: contorno por fuera y metal al aire
# justo dentro, para que se vea arrancado y no recortado.
func _tear(image: Image, keep: Callable) -> void:
	var palette: Dictionary = BaseShips.PALETTE
	var width: int = image.get_width()
	var height: int = image.get_height()
	var cut: PackedByteArray = PackedByteArray()
	cut.resize(width * height)
	for y: int in height:
		for x: int in width:
			if image.get_pixel(x, y).a > 0.0 and not keep.call(x, y):
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				cut[y * width + x] = 1
	var edge: Array[Vector2i] = []
	for y: int in height:
		for x: int in width:
			if image.get_pixel(x, y).a > 0.0 and _touches(cut, width, height, x, y):
				edge.append(Vector2i(x, y))
	for at: Vector2i in edge:
		image.set_pixelv(at, palette["O"])
	var outline: Color = palette["O"]
	for at: Vector2i in edge:
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var inner: Vector2i = at + step
			if not Rect2i(0, 0, width, height).has_point(inner):
				continue
			var color: Color = image.get_pixelv(inner)
			if color.a > 0.0 and color != outline:
				image.set_pixelv(inner, palette["m"] if (inner.x + inner.y) % 3 == 0 else palette["n"])


func _touches(cut: PackedByteArray, width: int, height: int, x: int, y: int) -> bool:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var at: Vector2i = Vector2i(x, y) + step
		if at.x >= 0 and at.y >= 0 and at.x < width and at.y < height and cut[at.y * width + at.x] == 1:
			return true
	return false


# Quemaduras: oscurece los píxeles de casco de la lista (no el contorno ni lo transparente).
func _scorch(image: Image, spots: Array[Vector2i]) -> void:
	var palette: Dictionary = BaseShips.PALETTE
	for at: Vector2i in spots:
		var color: Color = image.get_pixelv(at)
		if color.a > 0.0 and color != palette["O"]:
			image.set_pixelv(at, palette["K"])


func _stamp(image: Image, rows: Array, corner: Vector2i) -> void:
	var palette: Dictionary = BaseShips.PALETTE
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			var key: String = row[x]
			var at: Vector2i = corner + Vector2i(x, y)
			if key != "." and Rect2i(Vector2i.ZERO, image.get_size()).has_point(at):
				image.set_pixelv(at, palette[key])


func _recolor(image: Image, area: Rect2i, from: Color, to: Color) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if image.get_pixel(x, y) == from:
				image.set_pixel(x, y, to)


func _load_atlas(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image != null:
		image.convert(Image.FORMAT_RGBA8)
	return image


func _save_atlas(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("Guardado %s (error %d)" % [path, error])
	return error


# El Cruiser con el ala derecha arrancada y quemado, girado con la proa hacia la derecha (la luz,
# que en las naves viene de la izquierda, queda arriba).
func _crashed_ship() -> Image:
	var ship: Image = _render_ship(BaseShips.CRUISER)
	# Punta del ala derecha arrancada en diagonal
	_tear(ship, func(x: int, y: int) -> bool: return x + JAG[y % JAG.size()] < 49 - y)
	_scorch(ship, [Vector2i(9, 18), Vector2i(10, 19), Vector2i(8, 20), Vector2i(20, 15), Vector2i(21, 16),
			Vector2i(21, 17), Vector2i(22, 16), Vector2i(17, 11), Vector2i(5, 21)])
	ship.rotate_90(CLOCKWISE)
	return ship


func _make_crash() -> Error:
	var atlas: Image = _load_atlas(ANIMATED_PATH)
	var rocks: Image = _load_atlas(ROCKS_PATH)
	if atlas == null or rocks == null:
		push_error("No se pueden leer los atlas del tileset de espacio")
		return ERR_CANT_OPEN
	var size: int = CRASH_TILES * TILE
	var rock: Image = rocks.get_region(Rect2i(CRASH_ROCK_CELL * TILE, Vector2i(2, 2) * TILE))
	var ship: Image = _crashed_ship()
	var palette: Dictionary = BaseShips.PALETTE
	for index: int in CRASH_FRAMES:
		var frame: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		frame.blend_rect(ship, Rect2i(Vector2i.ZERO, ship.get_size()), CRASH_SHIP_AT)
		# La roca tapa la proa: la nave queda clavada
		frame.blend_rect(rock, Rect2i(Vector2i.ZERO, rock.get_size()), CRASH_ROCK_AT)
		for piece: Array in DEBRIS:
			_stamp(frame, piece[0], piece[1])
		_draw_sputter(frame, index)
		# La cabina parpadea: medio ciclo encendida y medio apagada
		if index >= CRASH_FRAMES / 2:
			_recolor(frame, CABIN_AREA, palette["r"], palette["R"])
		_draw_smoke(frame, index)
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), CRASH_CELL * TILE + Vector2i(index * size, 0))
	return _save_atlas(atlas, ANIMATED_PATH)


# Un motor que chisporrotea: una llama corta que sale y se apaga en mitad de la animación.
func _draw_sputter(frame: Image, index: int) -> void:
	var flames: Array[String] = ["", "r", "or", "yor", "r", ""]
	var nozzle: Vector2i = Vector2i(2, 22)
	var palette: Dictionary = BaseShips.PALETTE
	var flame: String = flames[index]
	for i: int in flame.length():
		var at: Vector2i = nozzle + Vector2i(-i, 0)
		if at.x >= 0:
			frame.set_pixelv(at, palette[flame[flame.length() - 1 - i]])


# Tres bocanadas de humo que suben desde el choque, desfasadas dos frames: cada una sube 2 px por frame,
# se va a la izquierda y se aclara hasta deshacerse.
func _draw_smoke(frame: Image, index: int) -> void:
	var palette: Dictionary = BaseShips.PALETTE
	for puff: int in 3:
		var phase: int = (index + puff * 2) % CRASH_FRAMES
		var at: Vector2i = SMOKE_START + Vector2i(-phase / 2 + puff % 2 * 2, -phase * 2)
		var color: Color = palette[SMOKE_SHADES[phase]]
		var side: int = SMOKE_SIZES[phase]
		for y: int in side:
			for x: int in side:
				# La de 3 px es una cruz, sin esquinas
				if side == 3 and x != 1 and y != 1:
					continue
				var pixel: Vector2i = at + Vector2i(x, y)
				if pixel.x >= 0 and pixel.y >= 0:
					frame.set_pixelv(pixel, color)


func _make_hull() -> Error:
	var atlas: Image = _load_atlas(ROCKS_PATH)
	if atlas == null:
		push_error("No se puede leer %s" % ROCKS_PATH)
		return ERR_CANT_OPEN
	var hull: Image = _render_ship(BaseShips.JUGGERNAUT)
	# Partido en diagonal: queda el ala izquierda y el centro, sin la punta de la proa
	_tear(hull, func(x: int, y: int) -> bool:
		return y > 7 + JAG[x % JAG.size()] and x + y / 3 < 27 + JAG[(y + 5) % JAG.size()])
	_scorch(hull, [Vector2i(9, 18), Vector2i(10, 18), Vector2i(10, 19), Vector2i(17, 14), Vector2i(18, 15),
			Vector2i(6, 21), Vector2i(7, 21), Vector2i(13, 21), Vector2i(21, 19)])
	# Centrado en la pieza
	var used: Rect2i = hull.get_used_rect()
	var size: int = HULL_TILES * TILE
	var cell: Rect2i = Rect2i(HULL_CELL * TILE, Vector2i(size, size))
	atlas.fill_rect(cell, Color(0, 0, 0, 0))
	atlas.blit_rect(hull, used, cell.position + (Vector2i(size, size) - used.size) / 2)
	return _save_atlas(atlas, ROCKS_PATH)
