extends SceneTree
## Genera los mapas de los niveles a partir de resources/map_data/level_N.txt.
##
## Uso: godot --headless --path . -s scripts/tools/map_generator.gd -- [N ...]
## Sin números genera los 9 niveles.
##
## Los caminos no se dibujan: son pasillos de espacio libre que atraviesan un campo de asteroides
## que llena el resto del mapa. La orilla del pasillo va casi llena y dentro del campo no quedan
## huecos de 3x3, para que ningún claro se confunda con un camino.
##
## La fuente de verdad es el .txt: el .tscn se sobrescribe entero en cada ejecución
## (conserva su uid), así que los retoques hechos en el editor se pierden al regenerar.
##
## Formato del .txt (en casillas; la (0, 0) es la de arriba a la izquierda):
##   seed = 7                    semilla de la decoración
##   station = 5 16              casilla del centro de la estación
##   path = -2,4 11,4 11,10 ...  un camino por línea, con tramos horizontales o verticales;
##                               empieza fuera del mapa y acaba en el centro de la estación
##   planets = 7,6 12,6 ...      casillas de torre (planetas)
##   rocks = grey brown ice      familias de roca del nivel (grey, brown, dark, ore, ice, crystal,
##                               lava); la primera es la principal y cierra el borde del mapa
## Las líneas vacías y las que empiezan por "#" se ignoran.

const MAP_SIZE: Vector2i = Vector2i(43, 33)
const TILE_SIZE: int = 16
const LEVEL_COUNT: int = 9
const DATA_PATH: String = "res://resources/map_data/level_%d.txt"
const SCENE_PATH: String = "res://scenes/maps/levels/Level%d.tscn"
const MAP_SCRIPT: String = "res://scripts/level/Map.gd"
const BACKGROUND_SCENE: String = "res://scenes/maps/SpaceBackground.tscn"
const BASE_SCENE: String = "res://scenes/entities/Base.tscn"
const SPACE_TILESET: String = "res://resources/tilesets/tileset_espacio.tres"
const LOGIC_TILESET: String = "res://resources/tilesets/logic_tileset.tres"

# Fuentes de tileset_espacio.tres
const ROCKS: int = 0
const PLANETS: int = 1
const ANIMATED: int = 2
const GRAVEL: int = 3
# Alternativa de las piezas con algún lado par (2x2, 2x1, 1x2, 3x2): desplazada media casilla
# para que tape casillas enteras en vez de quedar centrada en la de su ancla
const ALIGNED: int = 1
# Las piezas de 1x1 del atlas de rocas tienen las alternativas 1 a 4 desplazadas estos píxeles,
# para que las rocas pequeñas no queden en filas
const JITTER: Array[Vector2i] = [Vector2i.ZERO, Vector2i(3, 2), Vector2i(-3, 3), Vector2i(2, -3), Vector2i(-3, -2)]

# Casillas de logic_tileset.tres (fuente 0)
const LOGIC_SCENERY: Vector2i = Vector2i(0, 0)
const LOGIC_PATH: Vector2i = Vector2i(1, 0)
const LOGIC_SLOT: Vector2i = Vector2i(2, 0)

# Radio (en casillas, distancia de Chebyshev) que tapa la estación de 96x96 px
const STATION_RADIUS: int = 3
# Los caminos acaban a esta distancia (px) del centro de la estación: justo dentro de su borde
const STATION_REACH: float = 40.0
# La decoración llega una casilla más allá del mapa, a las franjas que quedan junto a las barras
const DECOR_MARGIN: int = 1
# El pasillo libre: el camino y una casilla a cada lado. La orilla es la casilla siguiente
const CORRIDOR_RADIUS: int = 1
const SHORE_DISTANCE: int = CORRIDOR_RADIUS + 1

# Densidad del campo: DENSITY_BASE más el ruido por DENSITY_NOISE_WEIGHT (de DENSITY_MIN a 1). Cerca del
# borde del mapa no baja de BORDER_DENSITY, para que el campo cierre el marco. Lejos del pasillo se
# multiplica por 1 + DEPTH_BONUS por cada casilla más allá de la orilla (hasta DEPTH_STEPS), para que
# el campo se espese hacia dentro y ninguna bolsa rodeada de orilla parezca vacía
const DENSITY_BASE: float = 0.9
const DENSITY_NOISE_WEIGHT: float = 0.4
const DENSITY_MIN: float = 0.65
const BORDER_DENSITY: float = 0.9
const BORDER_DEPTH: int = 2
const DEPTH_BONUS: float = 0.25
const DEPTH_STEPS: int = 2

# Rocas de 3x3 que asoman desde fuera del mapa, en el margen y la casilla del borde
const BORDER_LARGE_CHANCE: float = 0.14
# Probabilidad por casilla, multiplicada por la densidad: rocas de 3x3 y de 2x2 del campo
const LARGE_CHANCE: float = 0.12
const MEDIUM_CHANCE: float = 0.4
# En la orilla, roca de 2x2 (fija), roca pequeña y piedrecita
const SHORE_MEDIUM_CHANCE: float = 0.35
const SHORE_SMALL_CHANCE: float = 0.88
const SHORE_PEBBLE_CHANCE: float = 0.1
# Dentro del campo, roca pequeña y piedrecita (multiplicadas por la densidad)
const FIELD_SMALL_CHANCE: float = 0.55
const FIELD_PEBBLE_CHANCE: float = 0.4
# Rocas sueltas de la familia que acompaña (ver RockFamily.partner)
const MIX_CHANCE: float = 0.3
# Cada cuadrado de 3x3 del campo tiene al menos estas casillas con algo que se ve (ver _fill_holes)
const HOLE_MIN_SOLID: int = 2

# Restos: un resto grande con chatarra pequeña alrededor, por distancia a él (1 a 3)
const WRECK_MIN: int = 1
const WRECK_MAX: int = 3
const WRECK_SPACING: int = 8
const SCRAP_RING: Array[float] = [0.0, 0.3, 0.12, 0.04]

# Piezas especiales, lejos del pasillo y unas de otras
const LANDMARK_MIN: int = 3
const LANDMARK_MAX: int = 4
const LANDMARK_SPACING: int = 10
const LANDMARK_CORRIDOR_DISTANCE: int = 3
const LANDMARK_ATTEMPTS: int = 300

# Zonas de material: cada casilla toma la familia del punto de zona más cercano
const ZONE_COUNT: int = 6
const MAIN_ZONE_CHANCE: float = 0.5

# Gravilla de la capa Gravel (fuente GRAVEL): una fila por paleta y, en cada fila, primero las piezas
# con poca gravilla y luego las de mucha (ver make_gravel_tiles.gd). Cubre todo lo que no es pasillo:
# la orilla, con poca; el resto, con mucha según la densidad
const GRAVEL_ROWS: Dictionary[String, int] = {
	"grey": 0, "brown": 1, "dark": 2, "ore": 0, "ice": 0, "crystal": 2, "lava": 2,
}
const GRAVEL_SPARSE: int = 4
const GRAVEL_DENSE: int = 4
const TWINKLE_CHANCE: float = 0.014
# Estrellas animadas que parpadean (atlas de animados, fila 0)
const TWINKLES: Array[int] = [0, 6, 12]
# Luces de la pista (atlas de animados): las horizontales y las verticales alternan dos piezas
const LIGHTS_HORIZONTAL: Array[Vector2i] = [Vector2i(18, 0), Vector2i(22, 0)]
const LIGHTS_VERTICAL: Array[Vector2i] = [Vector2i(26, 0), Vector2i(0, 1)]
# Planetas (atlas de planetas, 2x2)
const PLANET_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(8, 0), Vector2i(0, 2), Vector2i(8, 2), Vector2i(0, 4),
	Vector2i(8, 4), Vector2i(0, 6), Vector2i(8, 6), Vector2i(0, 8), Vector2i(8, 8),
]


## Pieza del tileset: fuente, casilla del atlas y tamaño en casillas.
class Piece:
	var source: int
	var atlas: Vector2i
	var size: Vector2i

	func _init(piece_source: int, atlas_coords: Vector2i, piece_size: Vector2i = Vector2i.ONE) -> void:
		source = piece_source
		atlas = atlas_coords
		size = piece_size


## Rocas de un mismo material en tres tamaños. partner es la familia que se mezcla en sus grupos.
class RockFamily:
	var small: Array[Piece] = []
	var medium: Array[Piece] = []
	var large: Array[Piece] = []
	var partner: String = ""


class LevelLayout:
	var random_seed: int = 0
	var station: Vector2i = Vector2i.ZERO
	var paths: Array[PackedVector2Array] = []
	var planets: Array[Vector2i] = []
	var rocks: PackedStringArray = ["grey"]


# Catálogo de piezas
var _families: Dictionary[String, RockFamily] = {}
var _pebbles: Array[Piece] = []
var _scrap: Array[Piece] = []
var _wrecks: Array[Piece] = []
var _landmarks: Array[Piece] = []
var _beacon: Piece

# Estado del nivel que se está generando
var _rng: RandomNumberGenerator
var _density: FastNoiseLite
var _distance: Dictionary[Vector2i, int] = {}
# Casillas con algo puesto. _solid, las que tapa algo que se ve bien (todo menos piedrecitas)
var _blocked: Dictionary[Vector2i, bool] = {}
var _solid: Dictionary[Vector2i, bool] = {}
var _zone_points: Array[Vector2] = []
var _zone_families: Array[String] = []
var _main_family: String = ""


func _initialize() -> void:
	_build_catalog()
	var levels: Array[int] = []
	for arg: String in OS.get_cmdline_user_args():
		levels.append(arg.to_int())
	if levels.is_empty():
		for n: int in range(1, LEVEL_COUNT + 1):
			levels.append(n)
	for n: int in levels:
		_generate(n)
	quit()


func _build_catalog() -> void:
	_families["grey"] = _family([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [Vector2i(0, 4), Vector2i(2, 4)], [Vector2i(0, 8)], "dark")
	_families["brown"] = _family([Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)], [Vector2i(4, 4), Vector2i(6, 4)], [Vector2i(3, 8)], "dark")
	_families["dark"] = _family([Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0)], [Vector2i(8, 4), Vector2i(10, 4)], [Vector2i(6, 8)], "grey")
	_families["ore"] = _family([Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0)], [Vector2i(12, 4)], [], "grey")
	_families["ice"] = _family([Vector2i(12, 0), Vector2i(13, 0), Vector2i(14, 0)], [Vector2i(14, 4), Vector2i(0, 6)], [], "grey")
	_families["crystal"] = _family([Vector2i(15, 0), Vector2i(0, 1), Vector2i(1, 1)], [Vector2i(2, 6)], [], "dark")
	_families["lava"] = _family([Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)], [Vector2i(4, 6)], [], "dark")
	# Rocas de 2x2 animadas: el cristal que brilla y la lava que late
	_families["crystal"].medium.append(Piece.new(ANIMATED, Vector2i(16, 2), Vector2i(2, 2)))
	_families["lava"].medium.append(Piece.new(ANIMATED, Vector2i(8, 2), Vector2i(2, 2)))
	# Piedrecitas
	for x: int in [0, 1, 2, 3, 8, 9, 10]:
		_pebbles.append(Piece.new(ROCKS, Vector2i(x, 2)))
	# Chatarra pequeña: panel solar, placa, cables, tubo y cajas
	for coords: Vector2i in [Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2), Vector2i(15, 2), Vector2i(0, 3)]:
		_scrap.append(Piece.new(ROCKS, coords))
	# Restos grandes: casco roto, contenedores, depósito, viga y antena. El satélite (0, 11) no,
	# que ya sale el animado entre las piezas especiales
	_wrecks.append(Piece.new(ROCKS, Vector2i(6, 6), Vector2i(2, 2)))
	for x: int in [2, 4, 6, 8]:
		_wrecks.append(Piece.new(ROCKS, Vector2i(x, 11), Vector2i(2, 1)))
	_wrecks.append(Piece.new(ROCKS, Vector2i(9, 8), Vector2i(1, 2)))
	# Piezas especiales animadas: nave estrellada, satélite con astronauta, roca con ovni y satélite
	_landmarks.append(Piece.new(ANIMATED, Vector2i(0, 8), Vector2i(3, 3)))
	_landmarks.append(Piece.new(ANIMATED, Vector2i(0, 6), Vector2i(3, 2)))
	_landmarks.append(Piece.new(ANIMATED, Vector2i(0, 4), Vector2i(2, 2)))
	_landmarks.append(Piece.new(ANIMATED, Vector2i(0, 2), Vector2i(2, 1)))
	# Baliza con luz roja que parpadea, a los lados de las entradas
	_beacon = Piece.new(ANIMATED, Vector2i(4, 1))


func _family(small: Array[Vector2i], medium: Array[Vector2i], large: Array[Vector2i], partner: String) -> RockFamily:
	var family: RockFamily = RockFamily.new()
	for coords: Vector2i in small:
		family.small.append(Piece.new(ROCKS, coords))
	for coords: Vector2i in medium:
		family.medium.append(Piece.new(ROCKS, coords, Vector2i(2, 2)))
	for coords: Vector2i in large:
		family.large.append(Piece.new(ROCKS, coords, Vector2i(3, 3)))
	family.partner = partner
	return family


func _generate(n: int) -> void:
	var layout: LevelLayout = _parse(FileAccess.get_file_as_string(DATA_PATH % n))
	if layout == null:
		push_error("No se puede leer %s" % (DATA_PATH % n))
		return
	var scene_path: String = SCENE_PATH % n
	var old_uid: int = _read_scene_uid(scene_path)
	var map: Node2D = _build_map(layout)
	var packed: PackedScene = PackedScene.new()
	packed.pack(map)
	map.free()
	DirAccess.make_dir_recursive_absolute(scene_path.get_base_dir())
	var error: Error = ResourceSaver.save(packed, scene_path)
	if error != OK:
		push_error("No se puede guardar %s (%s)" % [scene_path, error_string(error)])
		return
	_write_uids(scene_path, old_uid if old_uid != ResourceUID.INVALID_ID else ResourceUID.create_id())
	print("%s -> %s (%d caminos, %d planetas)" % [DATA_PATH % n, scene_path, layout.paths.size(), layout.planets.size()])


## Uid escrito en la cabecera del .tscn, o INVALID_ID si el archivo no existe o no lo tiene.
func _read_scene_uid(scene_path: String) -> int:
	if not FileAccess.file_exists(scene_path):
		return ResourceUID.INVALID_ID
	var header: String = FileAccess.get_file_as_string(scene_path).get_slice("\n", 0)
	if not header.contains(" uid=\""):
		return ResourceUID.INVALID_ID
	return ResourceUID.text_to_id(header.get_slice(" uid=\"", 1).get_slice("\"", 0))


## Desde un script (-s) Godot guarda la escena sin uid propio ni en los ext_resource.
## Se añaden a mano: la escena conserva el suyo y cada ext_resource lleva el de su archivo.
func _write_uids(scene_path: String, scene_uid: int) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(scene_path).split("\n")
	for i: int in lines.size():
		var line: String = lines[i]
		if line.begins_with("[gd_scene") and not line.contains(" uid="):
			lines[i] = line.trim_suffix("]") + " uid=\"%s\"]" % ResourceUID.id_to_text(scene_uid)
		elif line.begins_with("[ext_resource") and not line.contains(" uid="):
			var path: String = line.get_slice("path=\"", 1).get_slice("\"", 0)
			var uid: int = ResourceLoader.get_resource_uid(path)
			if uid != ResourceUID.INVALID_ID:
				lines[i] = line.replace(" path=\"", " uid=\"%s\" path=\"" % ResourceUID.id_to_text(uid))
	var file: FileAccess = FileAccess.open(scene_path, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()


func _parse(text: String) -> LevelLayout:
	if text.is_empty():
		return null
	var layout: LevelLayout = LevelLayout.new()
	for raw_line: String in text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#") or not line.contains("="):
			continue
		var key: String = line.get_slice("=", 0).strip_edges()
		var value: String = line.get_slice("=", 1).strip_edges()
		match key:
			"seed":
				layout.random_seed = value.to_int()
			"station":
				var parts: PackedStringArray = value.split(" ", false)
				layout.station = Vector2i(parts[0].to_int(), parts[1].to_int())
			"path":
				var points: PackedVector2Array = []
				for cell: Vector2i in _parse_cells(value):
					points.append(Vector2(cell))
				layout.paths.append(points)
			"planets":
				layout.planets.assign(_parse_cells(value))
			"rocks":
				layout.rocks = value.split(" ", false)
				for family: String in layout.rocks:
					if not _families.has(family):
						push_error("Familia de roca desconocida: %s" % family)
						return null
			_:
				push_error("Clave desconocida: %s" % key)
	return layout


func _parse_cells(value: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for pair: String in value.split(" ", false):
		cells.append(Vector2i(pair.get_slice(",", 0).to_int(), pair.get_slice(",", 1).to_int()))
	return cells


func _build_map(layout: LevelLayout) -> Node2D:
	_rng = RandomNumberGenerator.new()
	_rng.seed = layout.random_seed
	_density = _make_noise(layout.random_seed, 0.12)
	_main_family = layout.rocks[0]
	_setup_zones(layout.rocks)
	var space_tileset: TileSet = load(SPACE_TILESET)

	var map: Node2D = Node2D.new()
	map.name = "Map"
	map.set_script(load(MAP_SCRIPT))
	var background: Node = (load(BACKGROUND_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	background.name = "Background"
	_add(map, background)
	var gravel: TileMapLayer = _add_layer(map, "Gravel", space_tileset)
	var lights: TileMapLayer = _add_layer(map, "Lights", space_tileset)
	var scenery: TileMapLayer = _add_layer(map, "VisualMap", space_tileset)
	var planets: TileMapLayer = _add_layer(map, "Planets", space_tileset)
	var logic: TileMapLayer = _add_layer(map, "LogicMap", load(LOGIC_TILESET))
	logic.visible = false
	logic.modulate = Color(1, 1, 1, 0.39215687)

	# Casillas de camino (también las de fuera del mapa) y su orientación, para las luces
	var path_cells: Dictionary[Vector2i, int] = {}
	for points: PackedVector2Array in layout.paths:
		_rasterize(points, layout.station, path_cells)
	_distance = _distance_to_path(path_cells)
	_blocked = {}
	_solid = {}
	_mark(layout.station, STATION_RADIUS)

	_place_planets(planets, layout.planets)
	_place_entrances(scenery, _find_entrances(layout))
	_place_lights(lights, path_cells, layout.station)
	_place_landmarks(scenery)
	_place_wrecks(scenery)
	_place_large(scenery)
	_place_medium(scenery)
	_place_small(scenery)
	_fill_holes(scenery)
	_place_gravel(gravel)
	_fill_logic(logic, path_cells, layout)

	var paths_node: Node2D = Node2D.new()
	paths_node.name = "Paths"
	_add(map, paths_node)
	for i: int in layout.paths.size():
		var path: Path2D = Path2D.new()
		path.name = str(i)
		path.curve = _make_curve(layout.paths[i], layout.station)
		paths_node.add_child(path)
		path.owner = map

	var station: Node2D = (load(BASE_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	station.name = "SpaceStation"
	station.position = _cell_center(layout.station)
	_add(map, station)
	return map


func _make_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return noise


## Reparte las familias del nivel en zonas: cada una sale al menos una vez y la principal, más.
func _setup_zones(rocks: PackedStringArray) -> void:
	_zone_points.clear()
	_zone_families.clear()
	for i: int in ZONE_COUNT:
		_zone_points.append(Vector2(_rng.randf_range(0, MAP_SIZE.x), _rng.randf_range(0, MAP_SIZE.y)))
		var family: String = rocks[0]
		if i < rocks.size():
			family = rocks[i]
		elif _rng.randf() > MAIN_ZONE_CHANCE:
			family = rocks[_rng.randi_range(0, rocks.size() - 1)]
		_zone_families.append(family)


func _family_at(cell: Vector2i) -> String:
	var best: int = 0
	for i: int in _zone_points.size():
		if _zone_points[i].distance_squared_to(Vector2(cell)) < _zone_points[best].distance_squared_to(Vector2(cell)):
			best = i
	return _zone_families[best]


## Familia de una roca suelta de un grupo: casi siempre la suya y a veces la que la acompaña.
func _mix(family_name: String) -> String:
	return _families[family_name].partner if _rng.randf() < MIX_CHANCE else family_name


func _add(map: Node2D, child: Node) -> void:
	map.add_child(child)
	child.owner = map


func _add_layer(map: Node2D, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_add(map, layer)
	return layer


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


## Apunta las casillas de cada tramo. El valor guarda las orientaciones que pasan por la casilla:
## 1 horizontal, 2 vertical (3 en esquinas y cruces). Las casillas tapadas por la estación no cuentan.
func _rasterize(points: PackedVector2Array, station: Vector2i, cells: Dictionary[Vector2i, int]) -> void:
	for i: int in points.size() - 1:
		var from: Vector2i = Vector2i(points[i])
		var to: Vector2i = Vector2i(points[i + 1])
		if from.x != to.x and from.y != to.y:
			push_error("Tramo en diagonal: %s -> %s" % [from, to])
			continue
		var step: Vector2i = (to - from).sign()
		var orientation: int = 1 if step.y == 0 else 2
		var cell: Vector2i = from
		while true:
			if _chebyshev(cell, station) > STATION_RADIUS - 1:
				cells[cell] = cells.get(cell, 0) | orientation
			if cell == to:
				break
			cell += step


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Distancia de Chebyshev de cada casilla (del mapa y de alrededor) al camino más cercano.
func _distance_to_path(path_cells: Dictionary[Vector2i, int]) -> Dictionary[Vector2i, int]:
	var distance: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in path_cells:
		distance[cell] = 0
		queue.append(cell)
	var head: int = 0
	var area: Rect2i = _decor_rect().grow(3)
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var next: Vector2i = cell + Vector2i(dx, dy)
				if not distance.has(next) and area.has_point(next):
					distance[next] = distance[cell] + 1
					queue.append(next)
	return distance


func _decor_rect() -> Rect2i:
	return Rect2i(Vector2i(-DECOR_MARGIN, -DECOR_MARGIN), MAP_SIZE + Vector2i(2, 2) * DECOR_MARGIN)


func _decor_cells() -> Array[Vector2i]:
	var rect: Rect2i = _decor_rect()
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


## 0 en el margen, 1 en la casilla del borde del mapa, 2 en la siguiente…
func _edge_depth(cell: Vector2i) -> int:
	return mini(mini(cell.x, MAP_SIZE.x - 1 - cell.x), mini(cell.y, MAP_SIZE.y - 1 - cell.y)) + DECOR_MARGIN


func _is_corridor(cell: Vector2i) -> bool:
	return _distance.get(cell, 99) <= CORRIDOR_RADIUS


func _is_shore(cell: Vector2i) -> bool:
	return _distance.get(cell, 99) == SHORE_DISTANCE


## Ni el pasillo ni algo ya puesto (estación, planeta o decorado).
func _is_free(cell: Vector2i) -> bool:
	return not _blocked.has(cell) and not _is_corridor(cell)


## Casillas libres del campo (del mapa y del margen), en orden al azar.
func _shuffled_free_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _decor_cells():
		if _is_free(cell):
			cells.append(cell)
	_shuffle(cells)
	return cells


## Densidad del campo en la casilla, de DENSITY_MIN a 1 + DEPTH_BONUS * DEPTH_STEPS.
func _density_at(cell: Vector2i) -> float:
	var density: float = clampf(DENSITY_BASE + _density.get_noise_2dv(Vector2(cell)) * DENSITY_NOISE_WEIGHT, DENSITY_MIN, 1.0)
	if _edge_depth(cell) <= BORDER_DEPTH:
		density = maxf(density, BORDER_DENSITY)
	var depth: int = clampi(_distance.get(cell, 99) - SHORE_DISTANCE, 0, DEPTH_STEPS)
	return density * (1.0 + DEPTH_BONUS * depth)


## Tapa el cuadrado de lado radius * 2 + 1 (estación y planetas): queda ocupado y se ve.
func _mark(center: Vector2i, radius: int) -> void:
	var rect: Rect2i = Rect2i(center - Vector2i.ONE * radius, Vector2i.ONE * (radius * 2 + 1))
	_block(rect)
	_make_solid(rect)


func _make_solid(rect: Rect2i) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_solid[Vector2i(x, y)] = true


func _block(rect: Rect2i) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_blocked[Vector2i(x, y)] = true


func _fits(top_left: Vector2i, size: Vector2i) -> bool:
	for y: int in size.y:
		for x: int in size.x:
			if not _is_free(top_left + Vector2i(x, y)):
				return false
	return true


## Pone la pieza tapando las casillas que empiezan en top_left y devuelve su rectángulo.
## Las piezas de lado impar se anclan en su casilla central; las de lado par usan la alternativa
## ALIGNED, desplazada media casilla, anclada en la primera casilla de ese lado. Las de 1x1 del
## atlas de rocas se desplazan unos píxeles al azar (ver JITTER).
func _put(layer: TileMapLayer, top_left: Vector2i, piece: Piece) -> Rect2i:
	var anchor: Vector2i = top_left + (piece.size - Vector2i.ONE) / 2
	var alternative: int = 0
	if piece.size.x % 2 == 0 or piece.size.y % 2 == 0:
		alternative = ALIGNED
	elif piece.size == Vector2i.ONE and piece.source == ROCKS:
		alternative = _jitter(top_left)
	layer.set_cell(anchor, piece.source, piece.atlas, alternative)
	var rect: Rect2i = Rect2i(top_left, piece.size)
	_block(rect)
	if not _pebbles.has(piece):
		_make_solid(rect)
	return rect


## Alternativa de JITTER al azar, sin las que acercan la pieza al pasillo.
func _jitter(cell: Vector2i) -> int:
	var options: Array[int] = []
	for i: int in JITTER.size():
		var shift: Vector2i = JITTER[i]
		if shift.x != 0 and _is_corridor(cell + Vector2i(signi(shift.x), 0)):
			continue
		if shift.y != 0 and _is_corridor(cell + Vector2i(0, signi(shift.y))):
			continue
		options.append(i)
	return options[_rng.randi_range(0, options.size() - 1)]


## Pone la pieza si cabe en top_left; si no, devuelve un Rect2i vacío.
func _try_put(layer: TileMapLayer, top_left: Vector2i, piece: Piece) -> Rect2i:
	if _fits(top_left, piece.size):
		return _put(layer, top_left, piece)
	return Rect2i()


## Pone la pieza tapando la casilla, en la primera posición en la que quepa; si no, Rect2i vacío.
func _try_put_over(layer: TileMapLayer, cell: Vector2i, piece: Piece) -> Rect2i:
	var offsets: Array[Vector2i] = []
	for y: int in piece.size.y:
		for x: int in piece.size.x:
			offsets.append(Vector2i(x, y))
	_shuffle(offsets)
	for offset: Vector2i in offsets:
		var rect: Rect2i = _try_put(layer, cell - offset, piece)
		if rect.has_area():
			return rect
	return Rect2i()


func _choose(pieces: Array[Piece]) -> Piece:
	return pieces[_rng.randi_range(0, pieces.size() - 1)]


func _shuffle(values: Array) -> void:
	for i: int in range(values.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: Variant = values[i]
		values[i] = values[j]
		values[j] = swap


func _near_any(cell: Vector2i, others: Array[Vector2i], spacing: int) -> bool:
	for other: Vector2i in others:
		if _chebyshev(cell, other) < spacing:
			return true
	return false


## Distancia de Chebyshev de la casilla al rectángulo (0 si está dentro).
func _rect_distance(cell: Vector2i, rect: Rect2i) -> int:
	var dx: int = maxi(maxi(rect.position.x - cell.x, cell.x - (rect.end.x - 1)), 0)
	var dy: int = maxi(maxi(rect.position.y - cell.y, cell.y - (rect.end.y - 1)), 0)
	return maxi(dx, dy)


## Cada planeta usa una pieza distinta de la de los planetas cercanos.
func _place_planets(layer: TileMapLayer, cells: Array[Vector2i]) -> void:
	var used: Dictionary[Vector2i, Vector2i] = {}
	for cell: Vector2i in cells:
		var options: Array[Vector2i] = PLANET_TILES.duplicate()
		for other: Vector2i in used:
			if _chebyshev(cell, other) <= 8:
				options.erase(used[other])
		if options.is_empty():
			options = PLANET_TILES.duplicate()
		var tile: Vector2i = options[_rng.randi_range(0, options.size() - 1)]
		used[cell] = tile
		layer.set_cell(cell, PLANETS, tile)
		_mark(cell, 1)


## Primera casilla de cada camino dentro del mapa y su dirección de avance, sin repetir.
func _find_entrances(layout: LevelLayout) -> Dictionary[Vector2i, Vector2i]:
	var entrances: Dictionary[Vector2i, Vector2i] = {}
	var map_rect: Rect2i = Rect2i(Vector2i.ZERO, MAP_SIZE)
	for points: PackedVector2Array in layout.paths:
		var found: bool = false
		for i: int in points.size() - 1:
			var to: Vector2i = Vector2i(points[i + 1])
			var step: Vector2i = (to - Vector2i(points[i])).sign()
			var cell: Vector2i = Vector2i(points[i])
			while not found:
				if map_rect.has_point(cell):
					entrances[cell] = step
					found = true
				if cell == to:
					break
				cell += step
			if found:
				break
	return entrances


## Una baliza a cada lado de la boca de cada pasillo, en la casilla del borde del mapa.
func _place_entrances(layer: TileMapLayer, entrances: Dictionary[Vector2i, Vector2i]) -> void:
	for cell: Vector2i in entrances:
		var step: Vector2i = entrances[cell]
		var side: Vector2i = Vector2i(step.y, step.x) * SHORE_DISTANCE
		for flank: Vector2i in [cell + side, cell - side]:
			if _is_free(flank):
				_put(layer, flank, _beacon)


## Una luz cada 2 casillas en los tramos rectos; nada en esquinas, cruces ni junto a ellos.
func _place_lights(layer: TileMapLayer, path_cells: Dictionary[Vector2i, int], station: Vector2i) -> void:
	var map_rect: Rect2i = Rect2i(Vector2i.ZERO, MAP_SIZE)
	for cell: Vector2i in path_cells:
		var orientation: int = path_cells[cell]
		if not map_rect.has_point(cell) or orientation == 3 or _chebyshev(cell, station) <= STATION_RADIUS:
			continue
		var along: Vector2i = Vector2i(1, 0) if orientation == 1 else Vector2i(0, 1)
		var neighbors_straight: bool = path_cells.get(cell + along, 0) == orientation and path_cells.get(cell - along, 0) == orientation
		if not neighbors_straight:
			continue
		var position_along: int = cell.x if orientation == 1 else cell.y
		if position_along % 2 != 0:
			continue
		var lights: Array[Vector2i] = LIGHTS_HORIZONTAL if orientation == 1 else LIGHTS_VERTICAL
		layer.set_cell(cell, ANIMATED, lights[int(position_along / 2.0) % 2])


## Unas pocas piezas especiales dentro del campo, lejos del pasillo, del borde y unas de otras, con
## un hueco libre alrededor.
func _place_landmarks(layer: TileMapLayer) -> void:
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in _shuffled_free_cells():
		if _distance.get(cell, 99) >= LANDMARK_CORRIDOR_DISTANCE and _edge_depth(cell) > BORDER_DEPTH:
			candidates.append(cell)
	if candidates.is_empty():
		return
	var pieces: Array[Piece] = _landmarks.duplicate()
	_shuffle(pieces)
	pieces.resize(mini(pieces.size(), _rng.randi_range(LANDMARK_MIN, LANDMARK_MAX)))
	var placed: Array[Vector2i] = []
	for piece: Piece in pieces:
		for attempt: int in LANDMARK_ATTEMPTS:
			var cell: Vector2i = candidates[_rng.randi_range(0, candidates.size() - 1)]
			if _near_any(cell, placed, LANDMARK_SPACING):
				continue
			var rect: Rect2i = _try_put_over(layer, cell, piece)
			if rect.has_area():
				placed.append(cell)
				_block(rect.grow(1))
				break


## Unos pocos restos grandes (casco, contenedor, depósito…) con chatarra pequeña alrededor, cada vez
## menos al alejarse de ellos.
func _place_wrecks(layer: TileMapLayer) -> void:
	var count: int = _rng.randi_range(WRECK_MIN, WRECK_MAX)
	var placed: Array[Vector2i] = []
	for cell: Vector2i in _shuffled_free_cells():
		if placed.size() >= count:
			return
		if _distance.get(cell, 99) <= SHORE_DISTANCE or _edge_depth(cell) <= BORDER_DEPTH or _near_any(cell, placed, WRECK_SPACING):
			continue
		var core: Rect2i = _try_put_over(layer, cell, _choose(_wrecks))
		if not core.has_area():
			continue
		placed.append(cell)
		var area: Rect2i = core.grow(SCRAP_RING.size() - 1)
		for y: int in range(area.position.y, area.end.y):
			for x: int in range(area.position.x, area.end.x):
				var scrap_cell: Vector2i = Vector2i(x, y)
				if _is_free(scrap_cell) and _rng.randf() < SCRAP_RING[_rect_distance(scrap_cell, core)]:
					_put(layer, scrap_cell, _choose(_scrap))


## Rocas de 3x3: en el borde, de la familia principal y asomando desde fuera del mapa; dentro, de la
## familia de la zona y más cuanto más denso es el campo.
func _place_large(layer: TileMapLayer) -> void:
	for cell: Vector2i in _shuffled_free_cells():
		if not _is_free(cell):
			continue
		if _edge_depth(cell) <= 1:
			var border_pieces: Array[Piece] = _large_pieces(_mix(_main_family))
			if not border_pieces.is_empty() and _rng.randf() < BORDER_LARGE_CHANCE:
				_try_put(layer, cell - Vector2i.ONE, _choose(border_pieces))
		elif _rng.randf() < LARGE_CHANCE * _density_at(cell):
			var pieces: Array[Piece] = _large_pieces(_mix(_family_at(cell)))
			if not pieces.is_empty():
				_try_put_over(layer, cell, _choose(pieces))


## Rocas de 3x3 de la familia o, si no tiene, de la que la acompaña.
func _large_pieces(family_name: String) -> Array[Piece]:
	var family: RockFamily = _families[family_name]
	return family.large if not family.large.is_empty() else _families[family.partner].large


## Rocas de 2x2 de la familia de la zona: en la orilla, con probabilidad fija, para que el pasillo
## no quede bordeado solo de piedras pequeñas; dentro, según la densidad.
func _place_medium(layer: TileMapLayer) -> void:
	for cell: Vector2i in _shuffled_free_cells():
		if not _is_free(cell):
			continue
		var chance: float = SHORE_MEDIUM_CHANCE if _is_shore(cell) else MEDIUM_CHANCE * _density_at(cell)
		if _rng.randf() < chance:
			_try_put_over(layer, cell, _choose(_families[_family_at(cell)].medium))


## Rocas pequeñas y piedrecitas: la orilla casi llena, y el resto del campo según la densidad.
func _place_small(layer: TileMapLayer) -> void:
	for cell: Vector2i in _shuffled_free_cells():
		var small_chance: float = SHORE_SMALL_CHANCE
		var pebble_chance: float = SHORE_PEBBLE_CHANCE
		if not _is_shore(cell):
			var density: float = _density_at(cell)
			small_chance = FIELD_SMALL_CHANCE * density
			pebble_chance = FIELD_PEBBLE_CHANCE * density
		var roll: float = _rng.randf()
		if roll < small_chance:
			_put(layer, cell, _choose(_families[_mix(_family_at(cell))].small))
		elif roll < small_chance + pebble_chance:
			_put(layer, cell, _choose(_pebbles))


## En cada cuadrado de 3x3 del campo en el que casi no se ve nada pone rocas pequeñas, para que
## ningún claro parezca un pasillo. Basta una pasada: cada cuadrado se mira una vez y lo puesto
## después solo puede llenarlo más.
func _fill_holes(layer: TileMapLayer) -> void:
	var centers: Array[Vector2i] = []
	for cell: Vector2i in _decor_cells():
		if not _is_corridor(cell):
			centers.append(cell)
	_shuffle(centers)
	for center: Vector2i in centers:
		while _is_hole(center):
			var options: Array[Vector2i] = []
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if _is_free(center + Vector2i(dx, dy)):
						options.append(center + Vector2i(dx, dy))
			if options.is_empty():
				break
			var cell: Vector2i = center if options.has(center) else options[_rng.randi_range(0, options.size() - 1)]
			_put(layer, cell, _choose(_families[_mix(_family_at(cell))].small))


## El cuadrado de 3x3 está entero dentro de la decoración, no tiene pasillo y tiene menos de
## HOLE_MIN_SOLID casillas con algo que se vea bien.
func _is_hole(center: Vector2i) -> bool:
	var rect: Rect2i = _decor_rect()
	var solid: int = 0
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var cell: Vector2i = center + Vector2i(dx, dy)
			if not rect.has_point(cell) or _is_corridor(cell):
				return false
			if _solid.has(cell):
				solid += 1
	return solid < HOLE_MIN_SOLID


## Gravilla de la familia de la zona por todo el campo y alguna estrella que parpadea; el pasillo
## queda limpio.
func _place_gravel(layer: TileMapLayer) -> void:
	for cell: Vector2i in _decor_cells():
		if _is_corridor(cell):
			continue
		if _rng.randf() < TWINKLE_CHANCE:
			layer.set_cell(cell, ANIMATED, Vector2i(TWINKLES[_rng.randi_range(0, TWINKLES.size() - 1)], 0))
			continue
		var column: int = _rng.randi_range(0, GRAVEL_SPARSE - 1)
		if not _is_shore(cell) and _rng.randf() < _density_at(cell):
			column = GRAVEL_SPARSE + _rng.randi_range(0, GRAVEL_DENSE - 1)
		layer.set_cell(cell, GRAVEL, Vector2i(column, GRAVEL_ROWS[_family_at(cell)]))


## Toda la cuadrícula: camino, hueco de torre o decorado.
func _fill_logic(layer: TileMapLayer, path_cells: Dictionary[Vector2i, int], layout: LevelLayout) -> void:
	for y: int in MAP_SIZE.y:
		for x: int in MAP_SIZE.x:
			var cell: Vector2i = Vector2i(x, y)
			var kind: Vector2i = LOGIC_SCENERY
			if layout.planets.has(cell):
				kind = LOGIC_SLOT
			elif path_cells.has(cell):
				kind = LOGIC_PATH
			layer.set_cell(cell, 0, kind)


## Puntos en el centro de las casillas; el último, en el borde de la estación.
func _make_curve(points: PackedVector2Array, station: Vector2i) -> Curve2D:
	var curve: Curve2D = Curve2D.new()
	for i: int in points.size() - 1:
		curve.add_point(_cell_center(Vector2i(points[i])))
	var last: Vector2 = _cell_center(Vector2i(points[points.size() - 2]))
	var target: Vector2 = _cell_center(station)
	curve.add_point(target - (target - last).normalized() * STATION_REACH)
	return curve
