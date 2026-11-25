extends SceneTree
## Genera los frames de la Specter: ala volante furtiva de 32x32 mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_espectro.gd
##
## HALF es la mitad izquierda (16 columnas); la derecha es su espejo con las caras en sombra
## (SHADE_SWAP), con la luz a la izquierda como las naves base (make_base_ships.gd), de las que toma la
## paleta: casco morado, granate y visor rojo. Su acento es el violeta de la disolución del camuflaje
## (cloak_dissolve.gdshader): borde de ataque y emisores en las puntas de las alas. Silueta de
## bombardero furtivo: ala ancha en flecha, borde de salida en dientes de sierra, joroba central con
## visor estrecho y toberas ocultas con una llama pequeña.
## Los frames cambian un brillo que recorre el borde de ataque de la punta al ala y la llama (FRAME_CHANGES).

const TARGET_DIR: String = "res://assets/sprites/enemies/espectro/"
const SIZE: int = 32

const PALETTE: Dictionary[String, Color] = {
	"O": Color("#0a0810"),
	"K": Color("#140c1e"),
	"D": Color("#221632"),
	"M": Color("#462c62"),
	"H": Color("#785096"),
	"L": Color("#a882c8"),
	"G": Color("#561428"),
	"B": Color("#8a2238"),
	"b": Color("#c0384e"),
	"g": Color("#2a0a1a"),
	"R": Color("#8c1628"),
	"r": Color("#f0323c"),
	"o": Color("#ff8c5a"),
	"y": Color("#ffdc78"),
	"n": Color("#2c303e"),
	"m": Color("#545c6e"),
	"u": Color("#3c2a8a"),
	"v": Color("#7a5ae6"),
	"c": Color("#c0aaff"),
	"e": Color("#f4f0ff"),
}

# Tono de cada cara del lado izquierdo en el lado derecho, en sombra
const SHADE_SWAP: Dictionary[String, String] = {"L": "H", "H": "M", "M": "D", "D": "K", "b": "B", "B": "G", "G": "g", "m": "n", "c": "v", "v": "u"}

const HALF: Array[String] = [
	"................",
	"................",
	"................",
	"................",
	"...............O",
	"..............Ob",
	".............ObB",
	".............OHB",
	"............OHMG",
	"...........OvHOO",
	"..........OvHOKr",
	".........OvHMOKR",
	"........OvHMMMOO",
	".......OvHMMMDGL",
	"......OvHMMMDDGH",
	".....OvHMMMDDDGH",
	"....OvHMMMDHDDGB",
	"...OvHMMMDHDDDGB",
	"..OvHMMMDHDDDDGB",
	".OcHMMMDHDDDDDGG",
	"OcevMMDHDDDDDDGG",
	".OvKDDHDDDDDDDGO",
	"..OOKDDOKDDDDGOm",
	"....OKDO.OKDDOOn",
	".....OO...OKDOyO",
	"...........OOO..",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]

# Píxeles de la mitad izquierda que cambian en cada frame: brillo del borde de ataque y llama
const FRAME_CHANGES: Array[Dictionary] = [
	{Vector2i(11, 10): "c", Vector2i(10, 11): "c"},
	{Vector2i(8, 13): "c", Vector2i(7, 14): "c", Vector2i(14, 25): "o"},
	{Vector2i(5, 16): "c", Vector2i(4, 17): "c", Vector2i(14, 24): "o"},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for index: int in FRAME_CHANGES.size():
		var path: String = TARGET_DIR + "espectro_%d.png" % index
		error = _draw_frame(FRAME_CHANGES[index]).save_png(ProjectSettings.globalize_path(path))
		print("Guardado %s (error %d)" % [path, error])
		if error != OK:
			break
	quit(error)


func _draw_frame(changes: Dictionary) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE / 2:
			var key: String = changes.get(Vector2i(x, y), HALF[y][x])
			if key == ".":
				continue
			image.set_pixel(x, y, PALETTE[key])
			image.set_pixel(SIZE - 1 - x, y, PALETTE[SHADE_SWAP.get(key, key)])
	return image
