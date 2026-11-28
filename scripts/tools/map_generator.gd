extends SceneTree
## Genera los mapas de los niveles a partir de resources/map_data/level_N.txt, los de la vitrina de
## la Navedex a partir de navedex*.txt (navedex_cryo.txt -> scenes/maps/NavedexCryoMap.tscn) y el del
## nivel de emergencia a partir de emergency.txt.
##
## Uso: godot --headless --path . -s scripts/tools/map_generator.gd -- [N | navedex | navedex_cryo | emergency ...]
## Sin argumentos genera los 9 niveles, los de la Navedex y el del nivel de emergencia.
##
## Los caminos no se dibujan: son pasillos de espacio libre que atraviesan un campo de asteroides
## que llena el resto del mapa. La orilla del pasillo va casi llena y dentro del campo no quedan
## huecos de 3x3, para que ningún claro se confunda con un camino.
##
## La fuente de verdad es el .txt: el .tscn se sobrescribe entero en cada ejecución
## (conserva su uid), así que los retoques hechos en el editor se pierden al regenerar.
##
## Formato del .txt (en casillas; la (0, 0) es la de arriba a la izquierda):
##   size = 43 33                tamaño en casillas (opcional; 43 33 si falta)
##   seed = 7                    semilla de la decoración
##   station = 5 16              casilla del centro de la estación (opcional: sin ella el mapa no
##                               lleva estación ni script Map, como el de la Navedex)
##   path = -2,4 11,4 11,10 ...  un camino por línea, con tramos rectos entre sus puntos;
##                               empieza fuera del mapa y acaba en el centro de la estación
##                               (sin estación, acaba en su última casilla). Cada esquina se
##                               redondea con un arco tangente a sus dos tramos; un punto puede
##                               llevar su propio radio de giro (en casillas) con ":", p. ej. 11,10:2
##   radius = 5                  radio de giro de las esquinas, en casillas (opcional; 5 si falta).
##                               Se acorta solo si el tramo no da para tanto: hasta la mitad de un
##                               tramo entre dos esquinas, el tramo entero en el último y el primero
##                               menos 3 casillas, que quedan en recto para la entrada
##   slots = 7,6 12,6 ...        casillas de torreta (un asteroide con plataforma en cada una)
##   rocks = grey brown ice      familias de roca del nivel (grey, brown, dark, ore, ice, crystal,
##                               lava); la primera es la principal y cierra el borde del mapa
##   landmark = ufo 34,18        pieza especial fija (ship, astronaut, ufo o satellite) tapando esa
##                               casilla (opcional, una por línea); las demás se ponen al azar
## Las líneas vacías y las que empiezan por "#" se ignoran.

const DEFAULT_MAP_SIZE: Vector2i = Vector2i(43, 33)
const TILE_SIZE: int = 16
const LEVEL_COUNT: int = 9
const DATA_PATH: String = "res://resources/map_data/level_%d.txt"
const SCENE_PATH: String = "res://scenes/maps/levels/Level%d.tscn"
const SHOWCASE_NAME: String = "navedex"
const SHOWCASE_DATA_PATH: String = "res://resources/map_data/%s.txt"
const SHOWCASE_SCENE_PATH: String = "res://scenes/maps/%sMap.tscn"
# Casilla de estación de un mapa sin estación: tan lejos que no tapa nada
const NO_STATION: Vector2i = Vector2i(-1000, -1000)
# Ninguna casilla (lo que devuelve una búsqueda que no encuentra nada)
const NO_CELL: Vector2i = Vector2i(-1000, -1000)
const EMERGENCY_NAME: String = "emergency"
const EMERGENCY_DATA_PATH: String = "res://resources/map_data/emergency.txt"
const EMERGENCY_SCENE_PATH: String = "res://scenes/maps/levels/Emergency.tscn"
const MAP_SCRIPT: String = "res://scripts/level/Map.gd"
const BACKGROUND_SCENE: String = "res://scenes/maps/SpaceBackground.tscn"
const BASE_SCENE: String = "res://scenes/entities/Base.tscn"
const SPACE_TILESET: String = "res://resources/tilesets/tileset_espacio.tres"
const LOGIC_TILESET: String = "res://resources/tilesets/logic_tileset.tres"

# Fuentes de tileset_espacio.tres
const ROCKS: int = 0
const TURRET_SLOTS: int = 4
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
# Radio de giro (casillas) de las esquinas si el .txt no da otro (se acorta si el tramo no da para tanto)
const DEFAULT_TURN_RADIUS: float = 5.0
# Casillas del principio de cada camino que quedan en recto antes de la primera curva: ahí están la boca
# del pasillo por donde entran las naves
const ENTRY_STRAIGHT: float = 3.0
# Distancia (casillas) a la que el pasillo aparta lo que hay a los lados: es pasillo toda casilla que
# tenga algún punto a esta distancia o menos de la curva. En un tramo recto sale el camino y una casilla a
# cada lado; en una curva, el pasillo se abre lo justo para que las rocas queden igual de lejos que en
# las rectas (con 1x1 de roca desplazada, a 24 px o más del centro del camino)
const CORRIDOR_CLEARANCE: float = 1.45
# Distancia mínima (casillas) del centro de una casilla de torreta a la curva del camino: la de una
# casilla de torreta junto a la orilla de un tramo recto, para que la torreta no tape las naves
const SLOT_CLEARANCE: float = 2.0
# Las casillas de torreta van centradas en su franja de roca, sin pasar de esta distancia (casillas)
# del camino: en una franja de 3 casillas entre dos pasillos, la del medio; en el campo, a 3 del camino
const SLOT_CENTER: float = 3.0
# Un tramo del camino va por una curva si su dirección se sale del eje más que esta pendiente (~3°)
const BEND_SLOPE: float = 0.05
# Orilla de las curvas (ver _place_bend_edges): piezas variadas cuyo borde sigue la curva. Ningún píxel
# opaco queda a menos de BEND_EDGE_CLEARANCE px del centro del camino (medido al centro del píxel: el
# borde, a 24 px, como en la orilla de un tramo recto) ni ninguna pieza con su centro a menos de
# BEND_EDGE_MIN px. Cada pieza se pone donde lo más cercano queda a como mucho BEND_EDGE_TOLERANCE px
# más (las pequeñas, con el centro a esa holgura de BEND_EDGE_MIN), para que la curva se lea
const BEND_EDGE_CLEARANCE: float = 24.5
const BEND_EDGE_MIN: float = 31.0
const BEND_EDGE_TOLERANCE: float = 5.0
# Si no cabe nada así, se prueba con una roca pequeña con más holgura y más adelante, para que no
# queden huecos grandes (las pequeñas solo pueden ir en su casilla, con poco desplazamiento)
const BEND_EDGE_WIDE_TOLERANCE: float = 8.0
const BEND_EDGE_WIDE_AHEAD: float = 16.0
# Si no cabe nada en un punto de la línea de la orilla, se prueba este trecho (px) más allá
const BEND_EDGE_STEP: float = 4.0
# Una pieza puede empezar desde BEND_EDGE_BEHIND px antes hasta BEND_EDGE_AHEAD px después de donde
# acabó la anterior más el hueco (las piezas van por casillas y no siempre cabe una justo ahí)
const BEND_EDGE_BEHIND: float = 4.0
const BEND_EDGE_AHEAD: float = 12.0
# Las rocas de 2x2 y 3x3 tienen, tras la alternativa sin desplazar, estas otras desplazadas 4 px
# (ver art.md). Solo las usa la orilla de las curvas, para que su borde siga la curva
const LARGE_JITTER_COUNT: int = 8
# Tipos de pieza de la orilla de las curvas y su peso: por fuera, de todo; por dentro, solo rocas de
# 2x2 y pequeñas (y la de 3x3 de la punta, si cabe). Si el elegido no cabe, se prueba el siguiente de
# EDGE_FALLBACK
enum EdgeKind { LARGE, MEDIUM, SMALL, PEBBLE, SCRAP }
const EDGE_OUTER_WEIGHTS: Dictionary[EdgeKind, float] = {
	EdgeKind.LARGE: 0.22, EdgeKind.MEDIUM: 0.42, EdgeKind.SMALL: 0.26, EdgeKind.PEBBLE: 0.04, EdgeKind.SCRAP: 0.06,
}
const EDGE_INNER_WEIGHTS: Dictionary[EdgeKind, float] = {
	EdgeKind.MEDIUM: 0.55, EdgeKind.SMALL: 0.45,
}
# Como mucho tantas piezas de 1x1 seguidas en la orilla de una curva: luego va una roca de 2x2 o, si no
# cabe, un hueco de al menos EDGE_GROUP_GAP px, así que las pequeñas van en grupos y no en fila
const EDGE_SMALL_STREAK: int = 2
const EDGE_GROUP_GAP: float = 8.0
# Una curva es cerrada (la punta de una U) si gira más que esto (rad)
const EDGE_TIGHT_TURN: float = 2.5
# La primera roca de la punta de una U empieza a hasta 1/EDGE_TIGHT_SPREAD de la orilla del medio
const EDGE_TIGHT_SPREAD: int = 5
const EDGE_FALLBACK: Dictionary[EdgeKind, EdgeKind] = {
	EdgeKind.LARGE: EdgeKind.MEDIUM, EdgeKind.MEDIUM: EdgeKind.SMALL, EdgeKind.PEBBLE: EdgeKind.SMALL, EdgeKind.SCRAP: EdgeKind.SMALL,
}
# Hueco (px) entre dos piezas seguidas de la orilla: casi siempre poco (grupos apretados) y a veces
# un hueco pequeño. Cada entrada: probabilidad acumulada, hueco mínimo y máximo
const EDGE_GAPS: Array[Vector3] = [Vector3(0.6, 0.0, 2.0), Vector3(0.9, 2.0, 5.0), Vector3(1.0, 8.0, 12.0)]
# Puntos precalculados (a cada lado) con los que se mira si un punto del camino está en una curva: así
# también cuenta la cima de un arco, donde la dirección vuelve a ir por el eje
const BEND_REACH: int = 3
# Separación (px) entre los puntos precalculados de cada curva: las naves giran poco a poco
const CURVE_BAKE_INTERVAL: float = 2.0
# Paso (px) con el que se recorre la curva para apuntar las casillas por las que pasa
const RASTER_STEP: float = 2.0
# Solo se mide la distancia al camino de las casillas hasta esta distancia (en casillas); las demás
# cuentan como lejanas (más allá de la orilla y de lo que espesa el campo no cambia nada)
const DISTANCE_WINDOW: int = 6
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
# Nombre de cada pieza especial en el .txt (clave landmark), en el orden de _landmarks
const LANDMARK_NAMES: Array[String] = ["ship", "astronaut", "ufo", "satellite"]

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
# Asteroides con plataforma de las casillas de torreta (fuente TURRET_SLOTS, piezas de 2x2): una fila
# por familia de roca y TURRET_SLOT_SHAPES formas por fila (ver make_turret_slot_tiles.gd)
const TURRET_SLOT_ROWS: Dictionary[String, int] = {
	"grey": 0, "brown": 1, "dark": 2, "ore": 3, "ice": 4, "crystal": 5, "lava": 6,
}
const TURRET_SLOT_SHAPES: int = 4
# Casillas de torreta a esta distancia o menos usan formas distintas
const TURRET_SLOT_SPREAD: int = 8


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
	var map_size: Vector2i = DEFAULT_MAP_SIZE
	var random_seed: int = 0
	var station: Vector2i = NO_STATION
	var paths: Array[PackedVector2Array] = []
	# Radio de giro (casillas) de cada punto de cada camino; negativo: el del mapa (turn_radius)
	var radii: Array[PackedFloat32Array] = []
	var turn_radius: float = DEFAULT_TURN_RADIUS
	# Vitrina de la Navedex: sus casillas de torreta se ponen a mano para cada escena
	var showcase: bool = false
	var slots: Array[Vector2i] = []
	var rocks: PackedStringArray = ["grey"]
	# Piezas especiales fijas: casilla que tapan -> índice en _landmarks
	var landmarks: Dictionary[Vector2i, int] = {}


## Dibujo de una pieza puesta con una alternativa: centros de los píxeles opacos de su contorno y
## centro del dibujo, en px desde la esquina de arriba a la izquierda de su primera casilla.
class PieceShape:
	var outline: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2.ZERO


## Sitio para una pieza de la orilla de una curva. back y front: dónde empieza y acaba a lo largo de
## la línea de la orilla (px desde el punto en el que se busca, en el sentido en el que se avanza).
class EdgeFit:
	var piece: Piece
	var top_left: Vector2i
	var alternative: int = 0
	var score: float = INF
	var back: float = 0.0
	var front: float = 0.0


# Catálogo de piezas
var _families: Dictionary[String, RockFamily] = {}
var _pebbles: Array[Piece] = []
var _scrap: Array[Piece] = []
var _wrecks: Array[Piece] = []
var _landmarks: Array[Piece] = []
var _beacon: Piece
# Dibujo de cada pieza con cada alternativa ("fuente:atlas:alternativa"), para la orilla de las curvas
var _shapes: Dictionary[String, PieceShape] = {}
var _textures: Dictionary[String, Image] = {}

# Estado del nivel que se está generando
var _rng: RandomNumberGenerator
var _map_size: Vector2i = DEFAULT_MAP_SIZE
var _density: FastNoiseLite
var _distance: Dictionary[Vector2i, int] = {}
# Distancia (casillas) del centro de cada casilla cercana a la curva de camino más próxima, y si ese
# punto más próximo está en una curva (un arco de esquina o un tramo en diagonal) y no en un tramo recto
var _center_distance: Dictionary[Vector2i, float] = {}
var _near_bend: Dictionary[Vector2i, bool] = {}
# Puntos de todos los caminos por casilla, para medir rápido la distancia al camino más cercano, y
# distancia (px) ya medida del centro de cada píxel
var _path_buckets: Dictionary[Vector2i, PackedVector2Array] = {}
var _pixel_distance: Dictionary[Vector2i, float] = {}
# Casillas de torreta mal puestas en el mapa que se está generando (ver _check_slots); con alguna no se guarda
var _slot_errors: int = 0
# Casillas con algo puesto. _solid, las que tapa algo que se ve bien (todo menos piedrecitas)
var _blocked: Dictionary[Vector2i, bool] = {}
var _solid: Dictionary[Vector2i, bool] = {}
var _zone_points: Array[Vector2] = []
var _zone_families: Array[String] = []
var _main_family: String = ""


func _initialize() -> void:
	_build_catalog()
	var names: Array[String] = []
	names.assign(OS.get_cmdline_user_args())
	if names.is_empty():
		for n: int in range(1, LEVEL_COUNT + 1):
			names.append(str(n))
		for file: String in DirAccess.get_files_at(DATA_PATH.get_base_dir()):
			if file.begins_with(SHOWCASE_NAME):
				names.append(file.get_basename())
		names.append(EMERGENCY_NAME)
	for map_name: String in names:
		if map_name.begins_with(SHOWCASE_NAME):
			_generate(SHOWCASE_DATA_PATH % map_name, SHOWCASE_SCENE_PATH % map_name.to_pascal_case())
		elif map_name == EMERGENCY_NAME:
			_generate(EMERGENCY_DATA_PATH, EMERGENCY_SCENE_PATH)
		else:
			_generate(DATA_PATH % map_name.to_int(), SCENE_PATH % map_name.to_int())
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


func _generate(data_path: String, scene_path: String) -> void:
	var layout: LevelLayout = _parse(FileAccess.get_file_as_string(data_path))
	if layout == null:
		push_error("No se puede leer %s" % data_path)
		return
	layout.showcase = data_path.get_file().begins_with(SHOWCASE_NAME)
	var old_uid: int = _read_scene_uid(scene_path)
	_slot_errors = 0
	var map: Node2D = _build_map(layout)
	if _slot_errors > 0:
		map.free()
		push_error("%s no se guarda: %d casillas de torreta mal puestas" % [scene_path, _slot_errors])
		return
	var packed: PackedScene = PackedScene.new()
	packed.pack(map)
	map.free()
	DirAccess.make_dir_recursive_absolute(scene_path.get_base_dir())
	var error: Error = ResourceSaver.save(packed, scene_path)
	if error != OK:
		push_error("No se puede guardar %s (%s)" % [scene_path, error_string(error)])
		return
	_write_uids(scene_path, old_uid if old_uid != ResourceUID.INVALID_ID else ResourceUID.create_id())
	print("%s -> %s (%d caminos, %d casillas de torreta)" % [data_path, scene_path, layout.paths.size(), layout.slots.size()])


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
			"size":
				var dims: PackedStringArray = value.split(" ", false)
				layout.map_size = Vector2i(dims[0].to_int(), dims[1].to_int())
			"seed":
				layout.random_seed = value.to_int()
			"station":
				var parts: PackedStringArray = value.split(" ", false)
				layout.station = Vector2i(parts[0].to_int(), parts[1].to_int())
			"path":
				var points: PackedVector2Array = []
				var radii: PackedFloat32Array = []
				for token: String in value.split(" ", false):
					var cell: String = token.get_slice(":", 0)
					points.append(Vector2(cell.get_slice(",", 0).to_int(), cell.get_slice(",", 1).to_int()))
					radii.append(token.get_slice(":", 1).to_float() if token.contains(":") else -1.0)
				layout.paths.append(points)
				layout.radii.append(radii)
			"radius":
				layout.turn_radius = value.to_float()
			"slots":
				layout.slots.assign(_parse_cells(value))
			"landmark":
				var parts: PackedStringArray = value.split(" ", false)
				var index: int = LANDMARK_NAMES.find(parts[0])
				if index < 0 or parts.size() < 2:
					push_error("Pieza especial desconocida: %s" % value)
					return null
				layout.landmarks[_parse_cells(parts[1])[0]] = index
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
	_map_size = layout.map_size
	var has_station: bool = layout.station != NO_STATION
	_rng = RandomNumberGenerator.new()
	_rng.seed = layout.random_seed
	_density = _make_noise(layout.random_seed, 0.12)
	_main_family = layout.rocks[0]
	_setup_zones(layout.rocks)
	var space_tileset: TileSet = load(SPACE_TILESET)

	var map: Node2D = Node2D.new()
	map.name = "Map"
	if has_station:
		map.set_script(load(MAP_SCRIPT))
	var background: Node = (load(BACKGROUND_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	background.name = "Background"
	_add(map, background)
	var gravel: TileMapLayer = _add_layer(map, "Gravel", space_tileset)
	var lights: TileMapLayer = _add_layer(map, "Lights", space_tileset)
	var scenery: TileMapLayer = _add_layer(map, "VisualMap", space_tileset)
	var turret_slots: TileMapLayer = _add_layer(map, "TurretSlots", space_tileset)
	var logic: TileMapLayer = _add_layer(map, "LogicMap", load(LOGIC_TILESET))
	logic.visible = false
	logic.modulate = Color(1, 1, 1, 0.39215687)

	# Casillas de camino (también las de fuera del mapa) y su orientación, para las luces
	var curves: Array[Curve2D] = _make_curves(layout)
	var path_cells: Dictionary[Vector2i, int] = {}
	for curve: Curve2D in curves:
		_rasterize(curve, layout.station, path_cells)
	_distance = _distance_to_path(curves, layout.station)
	_check_slots(layout.slots, layout.showcase)
	# Las esquinas de los cruces se redondean como el lado de dentro de una curva: el pasillo se abre
	# hasta el arco de relleno (sin cambiar los caminos ni las casillas de torreta, ya comprobadas)
	var fillets: Array[Curve2D] = _make_fillets(layout)
	if not fillets.is_empty():
		var shore_curves: Array[Curve2D] = curves.duplicate()
		shore_curves.append_array(fillets)
		_distance = _distance_to_path(shore_curves, layout.station)
	_blocked = {}
	_solid = {}
	if has_station:
		_mark(layout.station, STATION_RADIUS)

	_place_turret_slots(turret_slots, layout.slots)
	if has_station:
		_place_entrances(scenery, _find_entrances(curves))
	_place_lights(lights, path_cells, layout.station)
	_place_bend_edges(scenery, curves, fillets)
	_place_landmarks(scenery, layout.landmarks)
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
		path.curve = curves[i]
		paths_node.add_child(path)
		path.owner = map

	if has_station:
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
		_zone_points.append(Vector2(_rng.randf_range(0, _map_size.x), _rng.randf_range(0, _map_size.y)))
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


## Casilla que contiene un punto (px).
func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / TILE_SIZE).floor())


## Apunta las casillas por las que pasa la curva. El valor guarda lo que pasa por la casilla: 1 tramo
## recto horizontal, 2 vertical, 3 curva, tramo en diagonal o varios a la vez (esquinas y cruces).
## Las casillas tapadas por la estación no cuentan.
func _rasterize(curve: Curve2D, station: Vector2i, cells: Dictionary[Vector2i, int]) -> void:
	for i: int in curve.point_count - 1:
		var from: Vector2 = curve.get_point_position(i)
		var to: Vector2 = curve.get_point_position(i + 1)
		var straight: bool = curve.get_point_out(i) == Vector2.ZERO and curve.get_point_in(i + 1) == Vector2.ZERO
		var orientation: int = 3
		if straight and is_equal_approx(from.y, to.y):
			orientation = 1
		elif straight and is_equal_approx(from.x, to.x):
			orientation = 2
		# Un arco mide menos del doble que su cuerda
		var steps: int = ceili(from.distance_to(to) * 2.0 / RASTER_STEP) + 1
		for s: int in steps + 1:
			var cell: Vector2i = _cell_at(curve.sample(i, float(s) / steps))
			if _chebyshev(cell, station) > STATION_RADIUS - 1:
				cells[cell] = cells.get(cell, 0) | orientation


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Distancia de cada casilla cercana (del mapa y de alrededor) a la curva de camino más próxima, en
## pasos: 0 si la curva la cruza, 1 si algún punto de la casilla está a CORRIDOR_CLEARANCE casillas o menos
## de la curva (pasillo), 2 si está a una casilla más (orilla)… Junto a un tramo recto sale lo mismo que
## contando casillas (1 la de al lado, 2 la siguiente…); en una curva el pasillo sigue su forma y se abre
## para dejar el mismo hueco. Las partes del camino tapadas por la estación no cuentan. Las casillas a más
## de DISTANCE_WINDOW no se apuntan. En _center_distance queda la distancia (casillas) del centro de cada
## casilla a la curva, para las casillas de torreta.
func _distance_to_path(curves: Array[Curve2D], station: Vector2i) -> Dictionary[Vector2i, int]:
	var nearest: Dictionary[Vector2i, float] = {}
	_center_distance = {}
	_near_bend = {}
	var area: Rect2i = _decor_rect().grow(3)
	for curve: Curve2D in curves:
		var points: PackedVector2Array = curve.get_baked_points()
		for i: int in points.size():
			var point: Vector2 = points[i]
			var bend: bool = _is_bend(points[maxi(i - BEND_REACH, 0)], point) or _is_bend(point, points[mini(i + BEND_REACH, points.size() - 1)])
			var cell: Vector2i = _cell_at(point)
			if _chebyshev(cell, station) <= STATION_RADIUS - 1:
				continue
			# En casillas, con el centro de cada casilla en sus coordenadas enteras
			var spot: Vector2 = point / TILE_SIZE - Vector2(0.5, 0.5)
			for dy: int in range(-DISTANCE_WINDOW, DISTANCE_WINDOW + 1):
				for dx: int in range(-DISTANCE_WINDOW, DISTANCE_WINDOW + 1):
					var other: Vector2i = cell + Vector2i(dx, dy)
					if not area.has_point(other):
						continue
					var offset: Vector2 = (spot - Vector2(other)).abs()
					# Del punto más cercano de la casilla (un cuadrado de lado 1) a la curva
					var length: float = (offset - Vector2(0.5, 0.5)).max(Vector2.ZERO).length()
					if length < nearest.get(other, INF):
						nearest[other] = length
					var center_length: float = offset.length()
					if center_length < _center_distance.get(other, INF):
						_center_distance[other] = center_length
						_near_bend[other] = bend
	var distance: Dictionary[Vector2i, int] = {}
	for cell: Vector2i in nearest:
		distance[cell] = maxi(ceili(nearest[cell] + 1.0 - CORRIDOR_CLEARANCE - 0.001), 0)
	return distance


## Si el tramo de a a b se sale de los ejes (es parte de una curva o un tramo en diagonal).
func _is_bend(a: Vector2, b: Vector2) -> bool:
	var along: Vector2 = b - a
	return absf(along.x) > BEND_SLOPE * along.length() and absf(along.y) > BEND_SLOPE * along.length()


## Avisa de las casillas de torreta mal puestas:
## - a menos de SLOT_CLEARANCE del camino (la torreta taparía las naves): error;
## - sin centrar en su franja de roca: a menos de SLOT_CENTER del camino teniendo al lado una casilla
##   más lejos de él (en una franja entre dos pasillos, la del medio; en el campo, a SLOT_CENTER), salvo
##   que esa casilla esté fuera del borde del mapa o toque una curva.
## Junto a una curva sí puede ir (dentro de las esquinas cubre los dos tramos): su asteroide hace de
## orilla en lugar de las piezas de _place_bend_edges(), que no se ponen en sus casillas.
## En las vitrinas de la Navedex, con la casilla puesta a mano para cada escena, solo se mira la distancia.
func _check_slots(slots: Array[Vector2i], showcase: bool) -> void:
	for cell: Vector2i in slots:
		var length: float = _center_distance.get(cell, INF)
		if length < SLOT_CLEARANCE - 0.001:
			push_error("Casilla de torreta %s a %.2f casillas del camino (mínimo %.1f)" % [cell, length, SLOT_CLEARANCE])
			_slot_errors += 1
		if showcase:
			continue
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + side
			# Al lado del borde del mapa o de una curva no se puede ir más allá
			if not Rect2i(Vector2i.ONE, _map_size - Vector2i(2, 2)).has_point(next) or _bend_touched(next) != NO_CELL:
				continue
			if minf(_center_distance.get(next, INF), SLOT_CENTER) > minf(length, SLOT_CENTER) + 0.01:
				push_error("Casilla de torreta %s sin centrar en su franja (más lejos del camino en %s)" % [cell, next])
				_slot_errors += 1
				break


## Casilla de la orilla de una curva (o del pasillo junto a ella) que tocaría el asteroide de una casilla
## de torreta puesta aquí (la casilla y las 8 de alrededor), o NO_CELL si no toca ninguna.
func _bend_touched(cell: Vector2i) -> Vector2i:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var near: Vector2i = cell + Vector2i(dx, dy)
			if _distance.get(near, 99) <= SHORE_DISTANCE and _near_bend.get(near, false):
				return near
	return NO_CELL


func _decor_rect() -> Rect2i:
	return Rect2i(Vector2i(-DECOR_MARGIN, -DECOR_MARGIN), _map_size + Vector2i(2, 2) * DECOR_MARGIN)


func _decor_cells() -> Array[Vector2i]:
	var rect: Rect2i = _decor_rect()
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


## 0 en el margen, 1 en la casilla del borde del mapa, 2 en la siguiente…
func _edge_depth(cell: Vector2i) -> int:
	return mini(mini(cell.x, _map_size.x - 1 - cell.x), mini(cell.y, _map_size.y - 1 - cell.y)) + DECOR_MARGIN


func _is_corridor(cell: Vector2i) -> bool:
	return _distance.get(cell, 99) <= CORRIDOR_RADIUS


func _is_shore(cell: Vector2i) -> bool:
	return _distance.get(cell, 99) == SHORE_DISTANCE


## Ni el pasillo ni algo ya puesto (estación, casilla de torreta o decorado).
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


## Tapa el cuadrado de lado radius * 2 + 1 (estación y casillas de torreta): queda ocupado y se ve.
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
## atlas de rocas se desplazan unos píxeles al azar (ver JITTER), salvo que se pase la alternativa.
func _put(layer: TileMapLayer, top_left: Vector2i, piece: Piece, alternative: int = -1) -> Rect2i:
	var anchor: Vector2i = top_left + (piece.size - Vector2i.ONE) / 2
	if alternative < 0:
		alternative = _base_alternative(piece)
		if piece.size == Vector2i.ONE and piece.source == ROCKS:
			alternative = _jitter(top_left)
	layer.set_cell(anchor, piece.source, piece.atlas, alternative)
	var rect: Rect2i = Rect2i(top_left, piece.size)
	_block(rect)
	if not _pebbles.has(piece):
		_make_solid(rect)
	return rect


## Alternativa sin desplazar: la de media casilla (ALIGNED) si tiene algún lado par; si no, la 0.
func _base_alternative(piece: Piece) -> int:
	return ALIGNED if piece.size.x % 2 == 0 or piece.size.y % 2 == 0 else 0


## Alternativa de JITTER al azar, sin las que acercan la pieza al pasillo.
func _jitter(cell: Vector2i) -> int:
	var options: Array[int] = []
	for i: int in JITTER.size():
		var shift: Vector2i = JITTER[i]
		if shift.x != 0 and _is_corridor(cell + Vector2i(signi(shift.x), 0)):
			continue
		if shift.y != 0 and _is_corridor(cell + Vector2i(0, signi(shift.y))):
			continue
		if shift.x != 0 and shift.y != 0 and _is_corridor(cell + shift.sign()):
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


## Cada casilla de torreta lleva un asteroide de la familia de su zona, con una forma distinta de la
## de las casillas cercanas.
func _place_turret_slots(layer: TileMapLayer, cells: Array[Vector2i]) -> void:
	var used: Dictionary[Vector2i, int] = {}
	for cell: Vector2i in cells:
		var options: Array[int] = []
		options.assign(range(TURRET_SLOT_SHAPES))
		for other: Vector2i in used:
			if _chebyshev(cell, other) <= TURRET_SLOT_SPREAD:
				options.erase(used[other])
		if options.is_empty():
			options.assign(range(TURRET_SLOT_SHAPES))
		var shape: int = options[_rng.randi_range(0, options.size() - 1)]
		used[cell] = shape
		layer.set_cell(cell, TURRET_SLOTS, Vector2i(shape, TURRET_SLOT_ROWS[_family_at(cell)]) * 2)
		_mark(cell, 1)


## Primera casilla de cada camino dentro del mapa y su dirección de avance (por el eje en el que más
## avanza), sin repetir.
func _find_entrances(curves: Array[Curve2D]) -> Dictionary[Vector2i, Vector2i]:
	var entrances: Dictionary[Vector2i, Vector2i] = {}
	var map_rect: Rect2i = Rect2i(Vector2i.ZERO, _map_size)
	for curve: Curve2D in curves:
		var points: PackedVector2Array = curve.get_baked_points()
		for i: int in points.size() - 1:
			var cell: Vector2i = _cell_at(points[i])
			if not map_rect.has_point(cell):
				continue
			var direction: Vector2 = points[i + 1] - points[i]
			if absf(direction.x) >= absf(direction.y):
				entrances[cell] = Vector2i(int(signf(direction.x)), 0)
			else:
				entrances[cell] = Vector2i(0, int(signf(direction.y)))
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
	var map_rect: Rect2i = Rect2i(Vector2i.ZERO, _map_size)
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


## Orilla de cada curva del camino, a los dos lados: piezas variadas (rocas de 2x2, de 3x3 por fuera,
## pequeñas, piedrecitas y algo de chatarra) cuyo borde sigue la curva a BEND_EDGE_CLEARANCE px del
## camino, así que la curva se ve con su forma y con el mismo margen que un tramo recto. Un tramo de
## curva que comparten varios caminos se hace una sola vez. En los arcos de relleno de las esquinas de
## los cruces (fillets, ver _make_fillets) solo se pone el lado de dentro: el de fuera es pasillo.
func _place_bend_edges(layer: TileMapLayer, curves: Array[Curve2D], fillets: Array[Curve2D]) -> void:
	_path_buckets = {}
	_pixel_distance = {}
	var all_curves: Array[Curve2D] = curves.duplicate()
	all_curves.append_array(fillets)
	for curve: Curve2D in all_curves:
		for point: Vector2 in curve.get_baked_points():
			var cell: Vector2i = _cell_at(point)
			if not _path_buckets.has(cell):
				_path_buckets[cell] = PackedVector2Array()
			_path_buckets[cell].append(point)
	var done: Dictionary[Vector2i, bool] = {}
	for curve: Curve2D in curves:
		var points: PackedVector2Array = curve.get_baked_points()
		var bends: Array[bool] = []
		bends.resize(points.size())
		for i: int in range(1, points.size() - 1):
			bends[i] = _is_bend(points[maxi(i - BEND_REACH, 0)], points[i]) or _is_bend(points[i], points[mini(i + BEND_REACH, points.size() - 1)])
		# En la punta de una U cerrada, donde se juntan sus dos giros, quedan unos pocos puntos por el
		# eje: se cuentan como curva, para que la U sea un solo tramo (y su punta, cerrada)
		var last_bend: int = -1
		for i: int in range(1, points.size() - 1):
			if not bends[i]:
				continue
			if last_bend >= 0 and i - last_bend - 1 <= BEND_REACH * 2:
				for j: int in range(last_bend + 1, i):
					bends[j] = true
			last_bend = i
		var first: int = -1
		for i: int in range(1, points.size() - 1):
			var bend: bool = bends[i]
			if bend and first < 0:
				first = i
			if first >= 0 and (not bend or i == points.size() - 2):
				_place_bend_run(layer, points, first, i if bend else i - 1, done)
				first = -1
	for fillet: Curve2D in fillets:
		var points: PackedVector2Array = fillet.get_baked_points()
		var own: Dictionary[Vector2i, bool] = {}
		_place_bend_run(layer, points, 0, points.size() - 1, own, true)


## Las dos orillas (o solo la de dentro, con inner_only) del tramo de curva de los puntos first a last,
## si no se han hecho ya con otro camino (si más de la mitad de sus puntos caen en casillas de un tramo
## ya hecho).
func _place_bend_run(layer: TileMapLayer, points: PackedVector2Array, first: int, last: int, done: Dictionary[Vector2i, bool], inner_only: bool = false) -> void:
	var shared: int = 0
	var turn: float = 0.0
	for i: int in range(first, last + 1):
		if done.has(_cell_at(points[i])):
			shared += 1
		turn += _tangent(points, i).cross(_tangent(points, i + 1))
	if shared * 2 > last - first + 1:
		return
	for i: int in range(first, last + 1):
		done[_cell_at(points[i])] = true
	for side: float in [1.0, -1.0]:
		var line: PackedVector2Array = PackedVector2Array()
		var normals: PackedVector2Array = PackedVector2Array()
		for i: int in range(first, last + 1):
			var tangent: Vector2 = _tangent(points, i)
			var normal: Vector2 = Vector2(-tangent.y, tangent.x) * side
			line.append(points[i] + normal * BEND_EDGE_CLEARANCE)
			normals.append(normal)
		# El centro de la curva queda hacia donde gira el camino: ese es el lado de dentro
		var inner: bool = side * turn > 0.0
		if inner_only and not inner:
			continue
		_place_edge_side(layer, line, normals, inner, inner and absf(turn) > EDGE_TIGHT_TURN)


## Dirección del camino en el punto i.
func _tangent(points: PackedVector2Array, i: int) -> Vector2:
	return (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()


## Una orilla de un tramo de curva, a lo largo de line (los puntos a BEND_EDGE_CLEARANCE px del
## camino; normals, hacia fuera de él). Empieza por el medio y sigue hacia los dos extremos. En el lado
## de dentro de una curva cerrada (tight, la punta de la franja de una U) empieza con la roca más
## grande que quepa, para que la punta acabe redondeada y no en una cadena de piedras. Las casillas
## de la línea que quedan libres (los huecos entre piezas) se reservan.
func _place_edge_side(layer: TileMapLayer, line: PackedVector2Array, normals: PackedVector2Array, inner: bool, tight: bool) -> void:
	if line.size() < 3:
		return
	var lengths: PackedFloat32Array = PackedFloat32Array([0.0])
	for k: int in range(1, line.size()):
		lengths.append(lengths[k - 1] + line[k].distance_to(line[k - 1]))
	var middle: int = int(line.size() / 2.0)
	# En la punta de una U, la primera roca va un poco hacia un lado u otro al azar, para que cada punta
	# quede distinta (y quepa algo pequeño al otro lado)
	if tight:
		var spread: int = int(line.size() / float(EDGE_TIGHT_SPREAD))
		middle += _rng.randi_range(-spread, spread)
	var forward: float = lengths[middle]
	var backward: float = lengths[middle]
	var fit: EdgeFit = _edge_fit(line, normals, middle, 0.0, EdgeKind.LARGE if tight else _edge_kind(inner))
	if fit != null:
		_put(layer, fit.top_left, fit.piece, fit.alternative)
		forward += fit.front + _edge_gap()
		backward += fit.back - _edge_gap()
	_walk_edge(layer, line, normals, lengths, forward, 1.0, inner)
	_walk_edge(layer, line, normals, lengths, backward, -1.0, inner)
	# Los huecos entre piezas se quedan como huecos: el campo no los llena de piedras
	for k: int in line.size():
		var cell: Vector2i = _cell_at(line[k] + normals[k] * TILE_SIZE / 2.0)
		if _is_free(cell):
			_block(Rect2i(cell, Vector2i.ONE))


## Pone piezas a lo largo de la línea de la orilla desde position (px a lo largo de ella), hacia
## delante (direction 1) o hacia atrás (-1), hasta salirse. Tras EDGE_SMALL_STREAK piezas de 1x1
## seguidas solo pone una roca de 2x2 o, si no cabe, deja un hueco (ver EDGE_GROUP_GAP), para que no
## se forme una fila de piedras.
func _walk_edge(layer: TileMapLayer, line: PackedVector2Array, normals: PackedVector2Array, lengths: PackedFloat32Array, position: float, direction: float, inner: bool) -> void:
	var small_streak: int = 0
	var skipped: float = 0.0
	while position >= 0.0 and position <= lengths[lengths.size() - 1]:
		var k: int = _line_index(lengths, position)
		var kind: EdgeKind = _edge_kind(inner)
		var grouped: bool = small_streak >= EDGE_SMALL_STREAK
		if grouped:
			kind = EdgeKind.MEDIUM
		var fit: EdgeFit = _edge_fit(line, normals, k, direction, kind, not grouped)
		if fit == null:
			position += direction * BEND_EDGE_STEP
			skipped += BEND_EDGE_STEP
			if skipped >= EDGE_GROUP_GAP:
				small_streak = 0
			continue
		_put(layer, fit.top_left, fit.piece, fit.alternative)
		small_streak = small_streak + 1 if fit.piece.size == Vector2i.ONE else 0
		skipped = 0.0
		position = lengths[k] + direction * maxf(fit.front + _edge_gap(), BEND_EDGE_STEP)


## Punto de la línea más cercano a position (px a lo largo de ella).
func _line_index(lengths: PackedFloat32Array, position: float) -> int:
	var best: int = 0
	for k: int in lengths.size():
		if absf(lengths[k] - position) < absf(lengths[best] - position):
			best = k
	return best


## Tipo de pieza al azar para la orilla de una curva, por el lado de dentro o el de fuera.
func _edge_kind(inner: bool) -> EdgeKind:
	var weights: Dictionary[EdgeKind, float] = EDGE_INNER_WEIGHTS if inner else EDGE_OUTER_WEIGHTS
	var roll: float = _rng.randf()
	for kind: EdgeKind in weights:
		roll -= weights[kind]
		if roll < 0.0:
			return kind
	return EdgeKind.SMALL


## Hueco al azar entre dos piezas seguidas de la orilla de una curva (ver EDGE_GAPS).
func _edge_gap() -> float:
	var roll: float = _rng.randf()
	for gap: Vector3 in EDGE_GAPS:
		if roll < gap.x:
			return _rng.randf_range(gap.y, gap.z)
	return 0.0


## Piezas del tipo kind para la orilla, de la familia de la zona o de su pareja.
func _edge_pieces(kind: EdgeKind, family: String) -> Array[Piece]:
	match kind:
		EdgeKind.LARGE:
			return _large_pieces(_mix(family))
		EdgeKind.MEDIUM:
			return _families[_mix(family)].medium
		EdgeKind.SMALL:
			return _families[_mix(family)].small
		EdgeKind.PEBBLE:
			return _pebbles
	return _scrap


## El mejor sitio junto al punto k de la línea de la orilla para una pieza del tipo kind (o, si no cabe
## ninguna, del siguiente de EDGE_FALLBACK, y al final una pequeña con BEND_EDGE_WIDE_TOLERANCE), o null.
## Sin allow_small no llega a probar las pequeñas. Con direction 1 o -1 la pieza empieza en el punto
## y sigue en ese sentido; con 0, queda centrada en él.
func _edge_fit(line: PackedVector2Array, normals: PackedVector2Array, k: int, direction: float, kind: EdgeKind, allow_small: bool = true) -> EdgeFit:
	var tangent: Vector2 = (line[mini(k + 1, line.size() - 1)] - line[maxi(k - 1, 0)]).normalized()
	if direction < 0.0:
		tangent = -tangent
	var family: String = _family_at(_cell_at(line[k]))
	var tolerance: float = BEND_EDGE_TOLERANCE
	var ahead: float = BEND_EDGE_AHEAD
	while true:
		if kind == EdgeKind.SMALL and not allow_small:
			return null
		var best: EdgeFit = null
		for piece: Piece in _edge_pieces(kind, family):
			var size: Vector2 = Vector2(piece.size * TILE_SIZE)
			# Casilla de arriba a la izquierda si la pieza tocara la línea con su centro hacia fuera
			var guess: Vector2i = _cell_at(line[k] + normals[k] * size.x / 2.0 - size / 2.0 + Vector2.ONE * TILE_SIZE / 2.0)
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var top_left: Vector2i = guess + Vector2i(dx, dy)
					if not _edge_cells_free(top_left, piece.size):
						continue
					for alternative: int in _edge_alternatives(piece):
						var fit: EdgeFit = _score_edge(piece, top_left, alternative, line[k], tangent, direction, tolerance, ahead)
						if fit != null and (best == null or fit.score < best.score):
							best = fit
		if best == null and kind == EdgeKind.SMALL and tolerance == BEND_EDGE_TOLERANCE:
			tolerance = BEND_EDGE_WIDE_TOLERANCE
			ahead = BEND_EDGE_WIDE_AHEAD
			continue
		if best != null or not EDGE_FALLBACK.has(kind):
			return best
		kind = EDGE_FALLBACK[kind]
	return null


## Las casillas de la pieza están dentro de la decoración y libres; pueden ser del pasillo (lo que
## cuenta es lo opaco, ver _score_edge).
func _edge_cells_free(top_left: Vector2i, size: Vector2i) -> bool:
	for y: int in size.y:
		for x: int in size.x:
			var cell: Vector2i = top_left + Vector2i(x, y)
			if _blocked.has(cell) or not _decor_rect().has_point(cell):
				return false
	return true


## Alternativas con las que puede ir la pieza: sin desplazar o con cualquiera de sus desplazamientos
## (JITTER en las de 1x1 del atlas de rocas, LARGE_JITTER_COUNT en las rocas de 2x2 y 3x3).
func _edge_alternatives(piece: Piece) -> Array[int]:
	var alternatives: Array[int] = []
	if piece.size == Vector2i.ONE:
		alternatives.assign(range(JITTER.size()) if piece.source == ROCKS else [0])
	else:
		alternatives.assign(range(_base_alternative(piece), _base_alternative(piece) + LARGE_JITTER_COUNT + 1))
	return alternatives


## Sitio para la pieza en top_left con esa alternativa junto al punto spot de la línea de la orilla, o
## null si algo opaco queda a menos de BEND_EDGE_CLEARANCE del camino o su centro a menos de
## BEND_EDGE_MIN, si queda a más de tolerance de eso (no seguiría la curva) o si empieza lejos del
## punto (de BEND_EDGE_BEHIND antes a ahead después; si se busca centrada, centrada). Cuanto más pegada a la línea y al punto, mejor (menos score).
func _score_edge(piece: Piece, top_left: Vector2i, alternative: int, spot: Vector2, tangent: Vector2, direction: float, tolerance: float, ahead: float) -> EdgeFit:
	var shape: PieceShape = _shape(piece, alternative)
	var corner: Vector2 = Vector2(top_left * TILE_SIZE)
	var center_gap: float = _distance_at_pixel(corner + shape.center) - BEND_EDGE_MIN
	if center_gap < 0.0:
		return null
	var clearance: float = INF
	var back: float = INF
	var front: float = -INF
	for offset: Vector2 in shape.outline:
		var pixel: Vector2 = corner + offset
		clearance = minf(clearance, _distance_at_pixel(pixel))
		if clearance < BEND_EDGE_CLEARANCE:
			return null
		var along: float = (pixel - spot).dot(tangent)
		back = minf(back, along)
		front = maxf(front, along)
	# Las pequeñas se miden por el centro, como en la orilla de un tramo recto
	var error: float = center_gap if piece.size == Vector2i.ONE else clearance - BEND_EDGE_CLEARANCE
	var shift: float = back if direction != 0.0 else (back + front) / 2.0
	if error > tolerance or shift < -BEND_EDGE_BEHIND or shift > ahead:
		return null
	var fit: EdgeFit = EdgeFit.new()
	fit.piece = piece
	fit.top_left = top_left
	fit.alternative = alternative
	fit.score = error + absf(shift) * 0.5
	fit.back = back
	fit.front = front
	return fit


## Dibujo de la pieza con esa alternativa, sacado de su textura (en las animadas, el de todos sus
## fotogramas juntos).
func _shape(piece: Piece, alternative: int) -> PieceShape:
	var key: String = "%d:%s:%d" % [piece.source, piece.atlas, alternative]
	if _shapes.has(key):
		return _shapes[key]
	var source: TileSetAtlasSource = (load(SPACE_TILESET) as TileSet).get_source(piece.source)
	var path: String = source.texture.resource_path
	if not _textures.has(path):
		_textures[path] = Image.load_from_file(ProjectSettings.globalize_path(path))
	var image: Image = _textures[path]
	var region: Rect2i = source.get_tile_texture_region(piece.atlas)
	var opaque: Dictionary[Vector2i, bool] = {}
	for frame: int in source.get_tile_animation_frames_count(piece.atlas):
		var frame_region: Rect2i = source.get_tile_texture_region(piece.atlas, frame)
		for y: int in region.size.y:
			for x: int in region.size.x:
				if image.get_pixel(frame_region.position.x + x, frame_region.position.y + y).a > 0.0:
					opaque[Vector2i(x, y)] = true
	var origin: Vector2i = source.get_tile_data(piece.atlas, alternative).texture_origin
	var anchor: Vector2i = (piece.size - Vector2i.ONE) / 2
	var shape: PieceShape = PieceShape.new()
	# Se dibuja centrada en su casilla de anclaje, movida -texture_origin
	shape.center = Vector2(anchor * TILE_SIZE) + Vector2.ONE * TILE_SIZE / 2.0 - Vector2(origin)
	var corner: Vector2 = shape.center - Vector2(region.size) / 2.0
	for pixel: Vector2i in opaque:
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not opaque.has(pixel + side):
				shape.outline.append(corner + Vector2(pixel) + Vector2(0.5, 0.5))
				break
	_shapes[key] = shape
	return shape


## Distancia (px) de un punto (el centro de un píxel) al camino más cercano, medida una vez por píxel.
func _distance_at_pixel(point: Vector2) -> float:
	var key: Vector2i = Vector2i(point.floor())
	if not _pixel_distance.has(key):
		_pixel_distance[key] = _path_distance(point)
	return _pixel_distance[key]


## Distancia (px) de un punto al camino más cercano; exacta hasta 48 px (3 casillas), y más si no.
func _path_distance(point: Vector2) -> float:
	var center: Vector2i = _cell_at(point)
	var best: float = INF
	for dy: int in range(-3, 4):
		for dx: int in range(-3, 4):
			for other: Vector2 in _path_buckets.get(center + Vector2i(dx, dy), PackedVector2Array()):
				best = minf(best, point.distance_squared_to(other))
	return sqrt(best)


## Unas pocas piezas especiales dentro del campo, lejos del pasillo, del borde y unas de otras, con
## un hueco libre alrededor. Primero las fijas del .txt (fixed: casilla -> índice en _landmarks), que
## cuentan en el total y no se repiten.
func _place_landmarks(layer: TileMapLayer, fixed: Dictionary[Vector2i, int]) -> void:
	var placed: Array[Vector2i] = []
	var pieces: Array[Piece] = _landmarks.duplicate()
	for cell: Vector2i in fixed:
		var piece: Piece = _landmarks[fixed[cell]]
		var rect: Rect2i = _try_put_over(layer, cell, piece)
		if not rect.has_area():
			push_error("La pieza especial %s no cabe en %s" % [LANDMARK_NAMES[fixed[cell]], cell])
			continue
		placed.append(cell)
		pieces.erase(piece)
		_block(rect.grow(1))
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in _shuffled_free_cells():
		if _distance.get(cell, 99) >= LANDMARK_CORRIDOR_DISTANCE and _edge_depth(cell) > BORDER_DEPTH:
			candidates.append(cell)
	if candidates.is_empty():
		return
	_shuffle(pieces)
	pieces.resize(clampi(_rng.randi_range(LANDMARK_MIN, LANDMARK_MAX) - placed.size(), 0, pieces.size()))
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
		# Dentro de una curva cerrada (la punta de la franja de una U) la casilla del medio es orilla por
		# cerca que pasa la curva de su esquina, pero su centro queda tan lejos del camino como el medio
		# de la franja: lleva la misma gravilla, para que la franja no se apague antes de la punta
		var inner_middle: bool = _center_distance.get(cell, INF) >= SLOT_CENTER - 0.5
		if (not _is_shore(cell) or inner_middle) and _rng.randf() < _density_at(cell):
			column = GRAVEL_SPARSE + _rng.randi_range(0, GRAVEL_DENSE - 1)
		layer.set_cell(cell, GRAVEL, Vector2i(column, GRAVEL_ROWS[_family_at(cell)]))


## Toda la cuadrícula: camino, hueco de torreta o decorado.
func _fill_logic(layer: TileMapLayer, path_cells: Dictionary[Vector2i, int], layout: LevelLayout) -> void:
	for y: int in _map_size.y:
		for x: int in _map_size.x:
			var cell: Vector2i = Vector2i(x, y)
			var kind: Vector2i = LOGIC_SCENERY
			if layout.slots.has(cell):
				kind = LOGIC_SLOT
			elif path_cells.has(cell):
				kind = LOGIC_PATH
			layer.set_cell(cell, 0, kind)


## Curvas de los caminos: tramos rectos entre los puntos del .txt (del centro de sus casillas; el último,
## en el borde de la estación) y, en cada esquina, un arco de circunferencia tangente a los dos tramos
## (una Bézier cúbica), así que las naves giran poco a poco. Un mismo giro (mismo punto y mismas
## direcciones de entrada y de salida) se hace igual en todos los caminos que lo tienen, con el menor
## de sus radios: los caminos que comparten tramo pasan por los mismos puntos.
func _make_curves(layout: LevelLayout) -> Array[Curve2D]:
	var polylines: Array[PackedVector2Array] = []
	var radii: Array[PackedFloat32Array] = []
	for i: int in layout.paths.size():
		var cells: PackedVector2Array = layout.paths[i]
		var points: PackedVector2Array = []
		var point_radii: PackedFloat32Array = []
		for j: int in cells.size():
			var point: Vector2 = _cell_center(Vector2i(cells[j]))
			if j == cells.size() - 1 and layout.station != NO_STATION:
				point -= (point - _cell_center(Vector2i(cells[j - 1]))).normalized() * STATION_REACH
			if not points.is_empty() and point.is_equal_approx(points[points.size() - 1]):
				continue
			# Un punto en mitad de un tramo recto no es una esquina: se quita
			if points.size() >= 2 and absf(_turn_angle(points[points.size() - 2], points[points.size() - 1], point)) < 0.001:
				points.remove_at(points.size() - 1)
				point_radii.remove_at(point_radii.size() - 1)
			points.append(point)
			var radius: float = layout.radii[i][j]
			point_radii.append(radius if radius >= 0.0 else layout.turn_radius)
		polylines.append(points)
		radii.append(point_radii)

	# Distancia (px) de cada esquina a los puntos donde empieza y acaba su arco
	var reaches: Dictionary[String, float] = {}
	for i: int in polylines.size():
		var points: PackedVector2Array = polylines[i]
		for j: int in range(1, points.size() - 1):
			var key: String = _corner_key(points, j)
			reaches[key] = minf(reaches.get(key, INF), _corner_reach(points, j, radii[i][j]))

	var curves: Array[Curve2D] = []
	for points: PackedVector2Array in polylines:
		var curve: Curve2D = Curve2D.new()
		curve.bake_interval = CURVE_BAKE_INTERVAL
		curve.add_point(points[0])
		for j: int in range(1, points.size() - 1):
			var reach: float = reaches[_corner_key(points, j)]
			if reach <= 0.0:
				curve.add_point(points[j])
				continue
			var into: Vector2 = (points[j] - points[j - 1]).normalized()
			var out: Vector2 = (points[j + 1] - points[j]).normalized()
			var angle: float = absf(into.angle_to(out))
			# Tirador de la Bézier que mejor imita un arco de ese ángulo y de radio reach / tan(angle / 2)
			var handle: float = 4.0 / 3.0 * tan(angle / 4.0) * reach / tan(angle / 2.0)
			var start: Vector2 = points[j] - into * reach
			var last: int = curve.point_count - 1
			if curve.get_point_position(last).is_equal_approx(start):
				curve.set_point_out(last, into * handle)
			else:
				curve.add_point(start, Vector2.ZERO, into * handle)
			curve.add_point(points[j] + out * reach, -out * handle)
		var end: Vector2 = points[points.size() - 1]
		if not curve.get_point_position(curve.point_count - 1).is_equal_approx(end):
			curve.add_point(end)
		curves.append(curve)
	return curves


## Ángulo (radianes, con signo) que gira el camino en b al ir de a a c.
func _turn_angle(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b - a).angle_to(c - b)


## Identifica una esquina por su punto y sus direcciones de entrada y de salida.
func _corner_key(points: PackedVector2Array, j: int) -> String:
	var into: Vector2 = (points[j] - points[j - 1]).normalized().snapped(Vector2(0.001, 0.001))
	var out: Vector2 = (points[j + 1] - points[j]).normalized().snapped(Vector2(0.001, 0.001))
	return "%s %s %s" % [points[j].snapped(Vector2(0.01, 0.01)), into, out]


## Distancia (px) de la esquina j a donde empieza y acaba su arco con ese radio (casillas), recortada
## para que quepa: hasta la mitad de un tramo entre dos esquinas, el tramo entero en el último y, en el
## primero, el tramo menos ENTRY_STRAIGHT casillas, que quedan en recto para la boca.
func _corner_reach(points: PackedVector2Array, j: int, radius: float) -> float:
	var into: Vector2 = points[j] - points[j - 1]
	var out: Vector2 = points[j + 1] - points[j]
	var angle: float = absf(into.angle_to(out))
	if angle > PI - 0.01:
		push_error("Esquina que da la vuelta del todo en %s" % (points[j] / TILE_SIZE).floor())
		return 0.0
	var room_in: float = maxf(into.length() - ENTRY_STRAIGHT * TILE_SIZE, 0.0) if j == 1 else into.length() / 2.0
	var room_out: float = out.length() if j == points.size() - 2 else out.length() / 2.0
	return minf(radius * TILE_SIZE * tan(angle / 2.0), minf(room_in, room_out))


## Arcos de relleno de las esquinas de roca de los cruces: donde dos tramos rectos (de uno o de varios
## caminos) salen de un mismo punto en direcciones perpendiculares y ningún camino gira entre ellos (en
## una bifurcación, un cruce o una unión), un arco tangente a los dos del radio de giro del mapa (o
## menos, si un tramo es más corto). No es camino: solo abre el pasillo y lleva la orilla de dentro de
## una curva, para que la esquina se vea curva como las de las curvas.
func _make_fillets(layout: LevelLayout) -> Array[Curve2D]:
	var segments: Array[PackedVector2Array] = []
	var corners: Dictionary[Vector2, bool] = {}
	var rounded: Dictionary[String, bool] = {}
	for cells: PackedVector2Array in layout.paths:
		for j: int in cells.size():
			corners[cells[j]] = true
			if j > 0 and (cells[j].x == cells[j - 1].x or cells[j].y == cells[j - 1].y):
				segments.append(PackedVector2Array([cells[j - 1], cells[j]]))
			if j > 0 and j < cells.size() - 1:
				var back: Vector2 = (cells[j - 1] - cells[j]).normalized()
				var ahead: Vector2 = (cells[j + 1] - cells[j]).normalized()
				rounded[_quadrant_key(cells[j], back, ahead)] = true
	# Los cruces de dos tramos sin punto en común también cuentan
	for a: PackedVector2Array in segments:
		for b: PackedVector2Array in segments:
			if a[0].x == a[1].x and b[0].y == b[1].y:
				var crossing: Vector2 = Vector2(a[0].x, b[0].y)
				if _on_segment(crossing, a) and _on_segment(crossing, b):
					corners[crossing] = true
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var fillets: Array[Curve2D] = []
	for corner: Vector2 in corners:
		# Largo (casillas) del tramo recto que sale del punto en cada dirección
		var legs: Dictionary[Vector2, float] = {}
		for segment: PackedVector2Array in segments:
			if not _on_segment(corner, segment):
				continue
			for end: Vector2 in segment:
				if end != corner:
					var direction: Vector2 = (end - corner).normalized()
					legs[direction] = maxf(legs.get(direction, 0.0), corner.distance_to(end))
		for k: int in directions.size():
			var first: Vector2 = directions[k]
			var second: Vector2 = directions[(k + 1) % directions.size()]
			if not legs.has(first) or not legs.has(second) or rounded.has(_quadrant_key(corner, first, second)):
				continue
			var radius: float = minf(layout.turn_radius, minf(legs[first], legs[second])) * TILE_SIZE
			var center: Vector2 = _cell_center(Vector2i(corner))
			var handle: float = 4.0 / 3.0 * tan(PI / 8.0) * radius
			var fillet: Curve2D = Curve2D.new()
			fillet.bake_interval = CURVE_BAKE_INTERVAL
			fillet.add_point(center + first * radius, Vector2.ZERO, -first * handle)
			fillet.add_point(center + second * radius, -second * handle)
			fillets.append(fillet)
	return fillets


## Identifica el cuarto alrededor de un punto que queda entre dos direcciones perpendiculares.
func _quadrant_key(point: Vector2, first: Vector2, second: Vector2) -> String:
	return "%s %s" % [point, (first + second).snapped(Vector2(0.001, 0.001))]


## Si el punto está en el tramo recto (horizontal o vertical) de segment[0] a segment[1].
func _on_segment(point: Vector2, segment: PackedVector2Array) -> bool:
	var low: Vector2 = segment[0].min(segment[1])
	var high: Vector2 = segment[0].max(segment[1])
	return point.x >= low.x and point.x <= high.x and point.y >= low.y and point.y <= high.y
