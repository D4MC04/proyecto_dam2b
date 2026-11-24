extends SceneTree
## Genera los sprites de las naves base (Dart, Wasp, Streak, Vanguard, Corsair, Frigate, Cruiser y
## Juggernaut) y sus SpriteFrames, todas mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_base_ships.gd
##
## Cada nave es una plantilla de texto de su mitad izquierda (un carácter por píxel); la derecha es su
## espejo con las caras en sombra (SHADE_SWAP), así que la luz viene de la izquierda. Estética común:
## casco morado oscuro, franjas y piezas en granate, cabina y luces rojas, y un acento por nicho
## (naranja en las rápidas, rojo en las estándar y metal en las pesadas). Corsair, Frigate y Cruiser
## son la misma nave con mejoras. Los 3 frames solo cambian la llama de los motores (FLAMES).
##
## Escribe assets/sprites/enemies/<carpeta>/<carpeta>_<frame>.png y resources/sprite_frames/<frames>.tres.

const SPRITE_DIR: String = "res://assets/sprites/enemies/"
const FRAMES_DIR: String = "res://resources/sprite_frames/"
const FRAME_COUNT: int = 3
const ANIMATION_SPEED: float = 8.0
const ANIMATIONS: Array[String] = ["down", "left", "right", "up"]

const PALETTE: Dictionary[String, Color] = {
	"O": Color("#0a0810"),
	"K": Color("#140c1e"),
	"D": Color("#221632"),
	"M": Color("#462c62"),
	"H": Color("#785096"),
	"L": Color("#a882c8"),
	"g": Color("#2a0a1a"),
	"G": Color("#561428"),
	"B": Color("#8a2238"),
	"b": Color("#c0384e"),
	"R": Color("#8c1628"),
	"r": Color("#f0323c"),
	"o": Color("#ff8c5a"),
	"y": Color("#ffdc78"),
	"n": Color("#2c303e"),
	"m": Color("#545c6e"),
	"s": Color("#8c96aa"),
	"w": Color("#d2dceb"),
}

# Tono de cada cara del lado izquierdo en el lado derecho, en sombra
const SHADE_SWAP: Dictionary[String, String] = {"L": "H", "H": "M", "M": "D", "D": "K", "b": "B", "B": "G", "G": "g", "w": "s", "s": "m", "m": "n"}

# Llama de cada motor por frame, desde la tobera hacia atrás (la estela larga es la de la Streak)
const FLAMES: Array[String] = ["yor", "yyor", "yo"]
const LONG_FLAMES: Array[String] = ["yyoor", "yyyoor", "yyor"]

const DART: Array[String] = [
	"............",
	"...........O",
	"..........Ob",
	"...O......Ob",
	"..ObO....ObB",
	"..OBO....ObB",
	"..OBO....OBr",
	"..OBGO..OHBr",
	"..OBGO.OHMBy",
	".OBGHMOOHMBG",
	".OBHMMMHMMBG",
	".OGHMMMMMMBG",
	".OGMMMMMMDBG",
	".OGMMMMMDDGG",
	"..OMMMMDDDGG",
	"..OOMMDDDOGG",
	"....OOOOOOmG",
	"..........On",
	"............",
	"............",
	"............",
	"............",
	"............",
	"............",
]
const WASP: Array[String] = [
	"............",
	"............",
	"...........O",
	"..........OL",
	"..O.......OH",
	".ObO.....OHM",
	".OBO.....OHM",
	".OBO....OHMr",
	".OBbO...OHro",
	".OBbOO.OHMMM",
	".OBbBHOHHMMM",
	".OBbBMHHMMMM",
	".OBGBMMMMMMB",
	".OBGBMMMMMMB",
	".OBGBOOMMMMB",
	".OsmsO.OMMDG",
	".OmnmO..ODDG",
	"..ORO....OOO",
	"............",
	"............",
	"............",
	"............",
	"............",
	"............",
]
const STREAK: Array[String] = [
	"...........O",
	"..........Ob",
	"..........Ob",
	"..........OB",
	"..........OB",
	".........ObB",
	".........OHr",
	".........OHo",
	".........OHr",
	".........OHB",
	".......OHHMB",
	"......OHMMMB",
	".....OHMDDMB",
	"....OHMDOOMB",
	"...OHMDO.OMG",
	"..OHMDO..OBG",
	"..OoDO...OBm",
	"..OoO....OBn",
	"...O......O.",
	"............",
	"............",
	"............",
	"............",
	"............",
]
const VANGUARD: Array[String] = [
	"................",
	"...............O",
	"..............Os",
	"..............Ow",
	".............Osw",
	".............Osm",
	"............OsmB",
	"............OHBr",
	"...........OHMBo",
	"...........OHMBr",
	"..........OHMMBB",
	".........OHMMMBG",
	"........OsHMMMBG",
	".......OswHMMDBG",
	"......OswHOOOOOG",
	".....OswHMOBbBOG",
	"....OswHMMOBbBOG",
	"...OswHMMDOBbBOG",
	"..OswHMMDDOBGBOG",
	"..OsHMMDDKOBGBOO",
	"..OmMMDDKOOmsmO.",
	"..OoODDKO.OmnmO.",
	"...O.OOO...OOO..",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const CORSAIR: Array[String] = [
	"................",
	"................",
	"...............O",
	"..............OB",
	"..............Ob",
	".............ObB",
	".............OBG",
	".............OHr",
	"............OHMr",
	"............OHMy",
	"............OHMr",
	"...........OHMMM",
	"..........OHHMMG",
	".........OHbMMMB",
	"........OHMBMMDB",
	".......OHMMMBDDB",
	"......OHMMMMDBGB",
	".....OHMMMMDDGBB",
	"....OHbMMDDDGGOB",
	"...OHMMBDDDGGOmB",
	"..OLMDDDBGGGOmsG",
	"..ObDDDGGGOOOmsG",
	"..OrGGOOO...OnmG",
	"...O...........O",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const FRIGATE: Array[String] = [
	"................",
	"................",
	"...............O",
	"..............OB",
	"..............Ob",
	".............ObB",
	".............OBG",
	"..........O..OHr",
	"..........ObOHMr",
	"..........OBBHMy",
	"...........OOHMr",
	"...........OHMMM",
	"..........OHHMMG",
	".........OHbMMMB",
	"........OsMBMMDB",
	".......OswMMBDDB",
	"......OswMMMDBGB",
	".....OswMMMDDGBB",
	"....OswbMMDDDGOB",
	"...OHMMMBDDDGOmB",
	"..OLMDDDDBGGOmsG",
	"..ObDDOmsOGGOmsG",
	"..OBGGOmsOOOOnmG",
	"..ObO.OnmO...OOO",
	"..OrO..........O",
	"...O............",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const CRUISER: Array[String] = [
	"................",
	"................",
	".............OOO",
	"............OBbb",
	"............OBbb",
	"...........OBBbB",
	"...........OGBBG",
	"...........OsHrr",
	"..........OswHro",
	"..........OswHrr",
	"..........OsmHMM",
	"..........OsmHMM",
	".........OOsmMMG",
	"........OHOsmMMB",
	".......OHMOsmMDB",
	"......OHbMOmnMDB",
	".....OHMMBOmnDGB",
	"....OHMMMMBODDGB",
	"...OHbMMMDDBOGGB",
	"..OHMMBMDDDGGOGB",
	".OLMDDDDBGGGOmsG",
	".ObDDOmsOGGGOmsG",
	".OBGGOmsOGGOOmsG",
	".ObO.OnmOOO.OnmG",
	".OrO............",
	"..O.............",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const JUGGERNAUT: Array[String] = [
	"................",
	"................",
	"..............OO",
	".............Osw",
	"............Oswm",
	"...........OswmB",
	"..........OswmBb",
	".........OswmOBb",
	"........OswmOHBB",
	".......OswmOHMBG",
	"......OswmOHMMBr",
	".....OswmOHMMMBr",
	"....OswmOHMMMDBy",
	"...OswmOHMMMDDBr",
	"..OswmOHMMMDDDBr",
	"..OsmOHHMMMDDDGB",
	".OsmnOHMMMDDDKGB",
	".OmnOOHMMMDDKKGB",
	".OOOHHMMMDDDKKGB",
	".OHHMMMMDDDKKOOO",
	".OHMMMMDDDKKOmss",
	".OHMMMDDDKKKOmww",
	".OMMMDDDKKKKOmss",
	".OOmsmOOOOOOOnmm",
	"..OmnmO.....OOnn",
	"...ORO.......ORR",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]

# Por nave: carpeta (y nombre de los PNG), SpriteFrames, tamaño, plantilla, motores [fila, columna] de la
# mitad izquierda donde empieza cada llama, y si la estela es larga.
const SHIPS: Array[Dictionary] = [
	{"folder": "dart", "frames": "dart_rojo", "size": 24, "half": DART, "engines": [Vector2i(11, 18)], "long": false},
	{"folder": "wasp", "frames": "wasp", "size": 24, "half": WASP, "engines": [Vector2i(3, 18)], "long": false},
	{"folder": "streak", "frames": "streak", "size": 24, "half": STREAK, "engines": [Vector2i(11, 18)], "long": true},
	{"folder": "vanguard", "frames": "vanguard", "size": 32, "half": VANGUARD, "engines": [Vector2i(11, 23), Vector2i(12, 23), Vector2i(13, 23)], "long": false},
	{"folder": "nave_normal", "frames": "nave_normal", "size": 32, "half": CORSAIR, "engines": [Vector2i(13, 23)], "long": false},
	{"folder": "nave_agresiva", "frames": "nave_agresiva", "size": 32, "half": FRIGATE, "engines": [Vector2i(7, 24), Vector2i(8, 24), Vector2i(13, 23)], "long": false},
	{"folder": "cruiser", "frames": "cruiser", "size": 32, "half": CRUISER, "engines": [Vector2i(6, 24), Vector2i(7, 24), Vector2i(13, 24), Vector2i(14, 24)], "long": false},
	{"folder": "acorazado", "frames": "acorazado", "size": 32, "half": JUGGERNAUT, "engines": [Vector2i(3, 26), Vector2i(14, 26)], "long": false},
]


func _initialize() -> void:
	var error: Error = OK
	for ship: Dictionary in SHIPS:
		error = _make_ship(ship)
		if error != OK:
			break
	quit(error)


func _make_ship(ship: Dictionary) -> Error:
	var folder: String = SPRITE_DIR + ship["folder"] + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var paths: Array[String] = []
	for index: int in FRAME_COUNT:
		var path: String = folder + "%s_%d.png" % [ship["folder"], index]
		var error: Error = _draw_frame(ship, index).save_png(ProjectSettings.globalize_path(path))
		print("Guardado %s (error %d)" % [path, error])
		if error != OK:
			return error
		paths.append(path)
	return _write_frames(FRAMES_DIR + ship["frames"] + ".tres", paths)


func _draw_frame(ship: Dictionary, index: int) -> Image:
	var size: int = ship["size"]
	var half: Array[String] = ship["half"]
	var rows: Array[String] = half.duplicate()
	var flame: String = (LONG_FLAMES if ship["long"] else FLAMES)[index]
	for engine: Vector2i in ship["engines"]:
		for i: int in flame.length():
			if engine.y + i < size:
				var row: String = rows[engine.y + i]
				row[engine.x] = flame[i]
				rows[engine.y + i] = row
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size / 2:
			var key: String = rows[y][x]
			if key == ".":
				continue
			image.set_pixel(x, y, PALETTE[key])
			image.set_pixel(size - 1 - x, y, PALETTE[SHADE_SWAP.get(key, key)])
	return image


# SpriteFrames con las cuatro animaciones (el giro lo hace Enemy), escrito como el resto de enemigos.
func _write_frames(path: String, textures: Array[String]) -> Error:
	var lines: PackedStringArray = ["[gd_resource type=\"SpriteFrames\" format=3]", ""]
	for i: int in textures.size():
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d_f\"]" % [textures[i], i + 1])
	lines.append("")
	var frames: PackedStringArray = []
	for i: int in textures.size():
		frames.append("{
\"duration\": 1.0,
\"texture\": ExtResource(\"%d_f\")
}" % (i + 1))
	var animations: PackedStringArray = []
	for animation: String in ANIMATIONS:
		animations.append("{
\"frames\": [%s],
\"loop\": true,
\"name\": &\"%s\",
\"speed\": %.1f
}" % [
				", ".join(frames), animation, ANIMATION_SPEED])
	lines.append("[resource]")
	lines.append("animations = [%s]" % ", ".join(animations))
	lines.append("")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string("
".join(lines))
	file.close()
	print("Guardado %s" % path)
	return OK
