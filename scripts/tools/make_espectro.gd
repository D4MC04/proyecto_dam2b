extends SceneTree
## Genera los frames del Espectro: caza furtivo en manta raya de 32x32 mirando hacia arriba.
##
## Uso: godot --headless --path . -s scripts/tools/make_espectro.gd
##
## HALF es la mitad izquierda (16 columnas); la derecha es su espejo con las caras en sombra
## (SHADE_SWAP), para que el casco se lea facetado con la luz a la izquierda.
## Los frames solo cambian la luz tenue del ala y las llamas de los motores (FRAME_CHANGES).

const TARGET_DIR: String = "res://assets/sprites/enemies/espectro/"
const SIZE: int = 32

const PALETTE: Dictionary[String, Color] = {
	"O": Color("#0a0810"),
	"K": Color("#140c1e"),
	"D": Color("#221632"),
	"M": Color("#462c62"),
	"H": Color("#785096"),
	"V": Color("#5a468c"),
	"v": Color("#aa82c8"),
	"R": Color("#8c1628"),
	"r": Color("#f0323c"),
	"o": Color("#ff8c5a"),
	"y": Color("#ffdc78"),
	"n": Color("#2c303e"),
	"g": Color("#545c6e"),
	"G": Color("#8c96aa"),
}

# Tono de cada cara del lado izquierdo en el lado derecho, en sombra
const SHADE_SWAP: Dictionary[String, String] = {"H": "M", "M": "D", "D": "K"}

const HALF: Array[String] = [
	"................",
	"................",
	"................",
	"...........O....",
	"..........OHO...",
	"..........OHMO..",
	"..........OHMO.O",
	"..........OHMDOO",
	"..........OHMDOH",
	"...........OHDOH",
	".........OOOHMOV",
	".......OOHHMMMOv",
	".....OOHHMMMMMOM",
	"....OHHMMMOOMMOM",
	"...OHMMMOOMMDDOH",
	"..OHMMOOMMMDDDOH",
	"..OHMOMMMMDDDKOH",
	".OHMOMMMvDDDKKOH",
	".OHOMMMDDDDKKgOH",
	"OHMOMMDDDDKKKgOH",
	"OHOMMDDDDKKOgGOH",
	"ORMMDDDDKKKOgGOH",
	"OROMDDDKKKKOgGOH",
	".OOODDKKKKKOnGOH",
	"...OOOOKKKOOnGOH",
	".......OOO.OnGOH",
	"...........ORrOM",
	"............ry.O",
	"............o...",
	"................",
	"................",
	"................",
]

# Píxeles de la mitad izquierda que cambian en cada frame: luz del ala y llama
const FRAME_CHANGES: Array[Dictionary] = [
	{},
	{Vector2i(8, 17): "V", Vector2i(12, 27): "o", Vector2i(13, 27): "y", Vector2i(12, 28): "y"},
	{Vector2i(13, 27): "o", Vector2i(12, 28): "."},
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
