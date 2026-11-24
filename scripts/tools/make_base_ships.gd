extends SceneTree
## Genera los sprites de las 10 naves base (Dart, Wasp, Streak, Vanguard, Corsair, Frigate, Cruiser, Ram,
## Juggernaut y Mothership) y sus SpriteFrames, todas mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_base_ships.gd
##
## Cada nave es una plantilla de texto de su mitad izquierda (un carácter por píxel); la derecha es su
## espejo con las caras en sombra (SHADE_SWAP), así que la luz viene de la izquierda. Estética común:
## casco morado oscuro, franjas y piezas en granate, cabina y luces rojas, y un acento por nicho
## (naranja en las rápidas, rojo en las estándar y metal en las pesadas). Corsair, Frigate y Cruiser
## son la misma nave con mejoras. Los 3 frames solo cambian la llama de los motores.
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
	"W": Color("#fff4dc"),
	"n": Color("#2c303e"),
	"m": Color("#545c6e"),
	"s": Color("#8c96aa"),
	"w": Color("#d2dceb"),
}

# Tono de cada cara del lado izquierdo en el lado derecho, en sombra
const SHADE_SWAP: Dictionary[String, String] = {"L": "H", "H": "M", "M": "D", "D": "K", "b": "B", "B": "G", "G": "g", "w": "s", "s": "m", "m": "n"}

# Llamas de un motor en cada frame, desde la tobera hacia atrás
const FLAMES: Array[String] = ["yor", "yyor", "yo"]
const SHORT_FLAMES: Array[String] = ["yo", "yor", "y"]
# Estela larga (Streak)
const LONG_FLAMES: Array[String] = ["yyoor", "yyyoor", "yyor"]
# Con el núcleo casi blanco: motores calientes y centro de los chorros anchos
const HOT_FLAMES: Array[String] = ["Wyor", "Wyyor", "Wyo"]
const CORE_FLAMES: Array[String] = ["Wyyoor", "WWyyoor", "Wyyor"]

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
	"......OswHMMMDBG",
	".....OswHMMbBMDG",
	"....OswHMMbBBGDG",
	"...OswHMMDbBBGDG",
	"..OswHMMDDbBBGDG",
	"..OsHMMDDKbBBGDG",
	"..OmMMDDKOmssmDG",
	"..OoODDKOOnrynOO",
	"...O.OOO..O..O..",
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
const RAM: Array[String] = [
	"...............O",
	"...............O",
	"..............Or",
	"..............Ob",
	"..........OOOObb",
	"........OOwwssHM",
	"......OOwwHMMMMM",
	".....OwwGMMMMMMM",
	"....OwwMGMMMMMMM",
	"...OwMMMGMMMMMMM",
	"..OwwMMMGMMMMMMD",
	"..OwMMMMGMMDDDDG",
	".OmMMMMMOOOHMMBG",
	".OmMDDOO...OMMBG",
	".ODDDO.....OMMBG",
	".ODDO......Orrrr",
	".OGBO......OKKKK",
	".ObBGO.....Orrrr",
	".ObBGO.....OMMBG",
	".ObBGO.....OMMBG",
	".ObBGO.....OMMBG",
	".ObBGO......OMBG",
	"..OBGO......Ommm",
	"..OsO........OOO",
	"..OsO...........",
	"...O............",
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
const MOTHERSHIP: Array[String] = [
	"................",
	"............OOOO",
	".........OOOboBB",
	".......OOobKKrro",
	".....OOgKKHHHHHM",
	"....ObbKHHrHMMMM",
	"...OooKGGMMLLLMM",
	"...ObKMMMGLMMMMM",
	"..OgKMrMMLGMMMMM",
	"..OBKMMMLMMMMMMM",
	".OBKMMMLMMMMMMMM",
	".OBKMMMHMMMMMMDD",
	".OBKMMMHMMMDDDDD",
	".OBKMrMMDDDDDDDK",
	".OgKMDDMDGDDDKKs",
	".OgKGGGGDDDDRwso",
	"..OGKDDDMDDDRsoy",
	"..OGKDDDDMDRsoyW",
	"...OGKDDDDMRmoyW",
	"...OGGKDOOOORmoy",
	"...ObBGO....Owmo",
	"...ObBGO.....OOm",
	"...ObBGO.......O",
	"...ObBGO........",
	"...ObBGO........",
	"....OsO.........",
	"....OOO.........",
	"................",
	"................",
	"................",
	"................",
	"................",
]

# Por nave: carpeta (y nombre de los PNG), SpriteFrames, tamaño, plantilla y motores: dónde empieza la llama
# (columna y fila de la mitad izquierda) y qué llamas usa.
const SHIPS: Array[Dictionary] = [
	{"folder": "dart", "frames": "dart_rojo", "size": 24, "half": DART,
		"engines": [[Vector2i(11, 18), FLAMES]]},
	{"folder": "wasp", "frames": "wasp", "size": 24, "half": WASP,
		"engines": [[Vector2i(3, 18), FLAMES]]},
	{"folder": "streak", "frames": "streak", "size": 24, "half": STREAK,
		"engines": [[Vector2i(11, 18), LONG_FLAMES]]},
	{"folder": "vanguard", "frames": "vanguard", "size": 32, "half": VANGUARD,
		"engines": [[Vector2i(11, 22), FLAMES], [Vector2i(12, 22), CORE_FLAMES]]},
	{"folder": "nave_normal", "frames": "nave_normal", "size": 32, "half": CORSAIR,
		"engines": [[Vector2i(13, 23), FLAMES]]},
	{"folder": "nave_agresiva", "frames": "nave_agresiva", "size": 32, "half": FRIGATE,
		"engines": [[Vector2i(7, 24), FLAMES], [Vector2i(8, 24), FLAMES], [Vector2i(13, 23), FLAMES]]},
	{"folder": "cruiser", "frames": "cruiser", "size": 32, "half": CRUISER,
		"engines": [[Vector2i(6, 24), FLAMES], [Vector2i(7, 24), FLAMES], [Vector2i(13, 24), FLAMES], [Vector2i(14, 24), FLAMES]]},
	{"folder": "ariete", "frames": "ariete", "size": 32, "half": RAM,
		"engines": [[Vector2i(3, 25), HOT_FLAMES], [Vector2i(14, 24), LONG_FLAMES], [Vector2i(15, 24), CORE_FLAMES]]},
	{"folder": "acorazado", "frames": "acorazado", "size": 32, "half": JUGGERNAUT,
		"engines": [[Vector2i(3, 26), FLAMES], [Vector2i(14, 26), FLAMES]]},
	{"folder": "nodriza", "frames": "nodriza", "size": 32, "half": MOTHERSHIP,
		"engines": [[Vector2i(5, 27), FLAMES], [Vector2i(14, 22), SHORT_FLAMES], [Vector2i(15, 22), HOT_FLAMES]]},
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
	for engine: Array in ship["engines"]:
		var at: Vector2i = engine[0]
		var flames: Array[String] = engine[1]
		var flame: String = flames[index]
		for i: int in flame.length():
			if at.y + i < size:
				# Los String se copian: se cambia la copia y se vuelve a guardar en la fila
				var row: String = rows[at.y + i]
				row[at.x] = flame[i]
				rows[at.y + i] = row
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size / 2:
			var key: String = rows[y][x]
			if key == ".":
				continue
			image.set_pixel(x, y, PALETTE[key])
			image.set_pixel(size - 1 - x, y, PALETTE[SHADE_SWAP.get(key, key)])
	return image


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
		frames.append("{
\"duration\": 1.0,
\"texture\": ExtResource(\"%s\")
}" % ids[i])
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
