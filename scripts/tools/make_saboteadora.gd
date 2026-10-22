extends SceneTree
## Genera los frames de la Saboteadora (nave enemiga de guerra electrónica), mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_saboteadora.gd
##
## El dibujo es simétrico: SHAPE guarda la mitad izquierda (16 columnas) y se refleja.
## Dos antenas delante, dos bobinas a los lados, un núcleo que brilla en el centro y dos motores.
## Los caracteres de ANIMATED cambian de color en cada frame (núcleo, chispas de las antenas y llamas).

const TARGET_DIR: String = "res://assets/sprites/enemies/saboteadora/"
const SIZE: int = 32

# Contorno y metal de los enemigos, azul eléctrico y motores (ver docs/design/art.md)
const PALETTE: Dictionary[String, Color] = {
	"O": Color("#0a0810"),
	"1": Color("#2c303e"),
	"2": Color("#545c6e"),
	"3": Color("#8c96aa"),
	"4": Color("#d2dceb"),
	"b": Color("#16307a"),
	"B": Color("#2a6ae6"),
	"L": Color("#78bcff"),
	"W": Color("#e6f6ff"),
	"r": Color("#8c1628"),
	"R": Color("#f0323c"),
	"y": Color("#ff8c5a"),
	"Y": Color("#ffdc78"),
}

# Por frame: C núcleo, G anillo del núcleo, T punta de antena, F y f llama de fuera y de dentro
const ANIMATED: Array[Dictionary] = [
	{"C": "B", "G": "b", "T": "L", "F": "R", "f": "y"},
	{"C": "L", "G": "B", "T": "W", "F": "y", "f": "Y"},
	{"C": "L", "G": "L", "T": "B", "F": "R", "f": "Y"},
]

const SHAPE: Array[String] = [
	"................",
	"..........T.....",
	".........OTO....",
	".........O4O....",
	".........O3O..OO",
	".........O3O.O3b",
	".........O2OO43B",
	"..T......O2O432L",
	".OTO.....O1O432L",
	".O4O......OO432B",
	".O3O.....O22321b",
	"OL3bO...O233211O",
	"O432O..O233211OO",
	"O321OOOO23321OGG",
	"OLBbO3322211OGCC",
	"O321O2221111OGCW",
	"O321O1121111OGCW",
	"OLBbOOO12111OGCC",
	"O321O.O221111OGG",
	"O321O.O2221111OO",
	"OLBbO.OO22221112",
	"O321O..O12221111",
	".O1O...OO1222111",
	".O2O....O1111OO1",
	"..O.....OO1OrRO1",
	".........OOrRROO",
	"..........OFfFO.",
	"...........FfF..",
	"............F...",
	"................",
	"................",
	"................",
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for frame: int in ANIMATED.size():
		var path: String = TARGET_DIR + "saboteadora_%d.png" % frame
		error = _draw_frame(ANIMATED[frame]).save_png(ProjectSettings.globalize_path(path))
		print("Guardado %s (error %d)" % [path, error])
		if error != OK:
			break
	quit(error)


func _draw_frame(animated: Dictionary) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		var half: String = SHAPE[y]
		var row: String = half + half.reverse()
		for x: int in SIZE:
			var key: String = animated.get(row[x], row[x])
			if PALETTE.has(key):
				image.set_pixel(x, y, PALETTE[key])
	return image
