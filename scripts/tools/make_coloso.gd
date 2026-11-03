extends SceneTree
## Genera los frames del Coloso: acorazado jefe de 48x48 mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_coloso.gd
##
## HALF es la mitad izquierda (24 columnas); la derecha es su espejo con las caras en sombra
## (SHADE_SWAP), para que el casco se lea con la luz a la izquierda.
## Casco morado con placas de blindaje de metal: espolón delante, puente con visor rojo, dos
## hangares a los lados (de donde salen las naves que suelta) y cuatro motores detrás.
## Los frames solo cambian las luces de los hangares y las llamas (FRAME_CHANGES).

const TARGET_DIR: String = "res://assets/sprites/enemies/coloso/"
const SIZE: int = 48

const PALETTE: Dictionary[String, Color] = {
	"O": Color("#0a0810"),
	"K": Color("#140c1e"),
	"D": Color("#221632"),
	"M": Color("#462c62"),
	"H": Color("#785096"),
	"n": Color("#2c303e"),
	"g": Color("#545c6e"),
	"G": Color("#8c96aa"),
	"W": Color("#d2dceb"),
	"R": Color("#8c1628"),
	"r": Color("#f0323c"),
	"o": Color("#ff8c5a"),
	"y": Color("#ffdc78"),
}

# Tono de cada cara del lado izquierdo en el lado derecho, en sombra
const SHADE_SWAP: Dictionary[String, String] = {
	"H": "M", "M": "D", "D": "K", "W": "G", "G": "g", "g": "n",
}

const HALF: Array[String] = [
	"........................",
	"........................",
	"...................OOOOO",
	"..................OWWWWW",
	"..................OGGGGG",
	"..................OgGGGG",
	".................OOOOOOO",
	".................OHHHMMM",
	"................OHHMMMMM",
	"................OHMMMMMM",
	"...............OHMMMOOOO",
	"...............OHMMOGGGG",
	"..............OHMMMOGrrr",
	"..............OHMMMOGRRR",
	".........OOOOOHMMMMOGGGG",
	"........OGWWGOHMMMMOgggg",
	".......OGGGGgOHMMMMOOOOO",
	"......OGGggggOHMMMMMMMMM",
	".....OOOOOOOOOHMMMMDDMMM",
	"....OHHHHHHHHOHMMMDDDMMM",
	"...OHMMMMMMMMOHMMMMMMMMM",
	"..OOOOOOMMMMMOOOOOOOOOOO",
	"..OKKKKOMMMMMOGWWGGGGGGG",
	"..OKrKKOMMMMMOGGGGGGGGGG",
	"..OKKKKOMMMMMOgGGGGGGGGG",
	"..OKrKKOMMMMMOgggggggggg",
	"..OKKKKOMMMMMOOOOOOOOOOO",
	"..OOOOOOMMMMMOHMMMMMMMMM",
	"...OHMMMMMMMMOHMMMDDMMMM",
	"...OHMMMMMDDDOHMMDDDDMMM",
	"...OHMMMMDDDDOHMMMDDMMMM",
	"...OOOOOOOOOOOHMMMMMMMMM",
	"...OGWGGGGGgnOHMMMMMMMMM",
	"...OGGGGGGggnOOOOOOOOOOO",
	"...OgggggggnnOGWWGGGGGGG",
	"....OOOOOOOOOOGGGGGGGGGG",
	".....OHMMMDDKOgggggggggg",
	".....OHMMDDDKOOOOOOOOOOO",
	"......OOOOOOOOHMMMMMDDDD",
	".......OOOOOOOHMMMMDDDKK",
	".......OOOOOOOOOOOOOOOOO",
	"........OnGGgO.OnGGgO...",
	"........OnGGgO.OnGGgO...",
	"........ORrrRO.ORrrRO...",
	".........ryyr...ryyr....",
	".........oyyo...oyyo....",
	"..........oo.....oo.....",
	"........................",
]

# Píxeles de la mitad izquierda que cambian en cada frame: luces de los hangares y llamas
const FRAME_CHANGES: Array[Dictionary] = [
	{},
	{
		Vector2i(4, 23): "o", Vector2i(4, 25): "y",
		Vector2i(10, 46): "y", Vector2i(11, 46): "y", Vector2i(10, 47): "o", Vector2i(11, 47): "o",
		Vector2i(17, 46): "y", Vector2i(18, 46): "y", Vector2i(17, 47): "o", Vector2i(18, 47): "o",
	},
	{
		Vector2i(4, 23): "R", Vector2i(4, 25): "R",
		Vector2i(10, 46): ".", Vector2i(11, 46): ".", Vector2i(17, 46): ".", Vector2i(18, 46): ".",
		Vector2i(9, 45): "r", Vector2i(12, 45): "r", Vector2i(16, 45): "r", Vector2i(19, 45): "r",
	},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for index: int in FRAME_CHANGES.size():
		var path: String = TARGET_DIR + "coloso_%d.png" % index
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
