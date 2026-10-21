extends SceneTree
## Genera los frames de la Divisora (divisora_0.png a divisora_2.png, 32x32, mirando hacia arriba).
##
## Uso: godot --headless --path . -s scripts/tools/make_divisora_sprites.gd
##
## Nave nodriza pequeña de tres módulos: un casco central con cabina y una bodega iluminada,
## y dos vainas laterales sujetas con abrazaderas de metal, cada una con su motor. Solo se
## dibuja la mitad izquierda (16 columnas) y se refleja. Los frames cambian la llama de los
## motores y la luz de la bodega.
##
## También genera los tres trozos en que se parte (fragmento_izquierdo, _central y _derecho,
## 20x20, recortados del mismo dibujo) y divisora_crack.png, el frame agrietado al morir.

const TARGET_DIR: String = "res://assets/sprites/enemies/divisora/"
const SIZE: int = 32

const PALETTE: Dictionary[String, Color] = {
	# Contorno de enemigos
	"0": Color("#0a0810"),
	# Metal gris azulado de enemigos
	"1": Color("#2c303e"),
	"2": Color("#545c6e"),
	"3": Color("#8c96aa"),
	"4": Color("#d2dceb"),
	# Casco naranja, de sombra a luz
	"a": Color("#7a3014"),
	"b": Color("#d2641e"),
	"c": Color("#f59a3c"),
	"d": Color("#ffd08a"),
	# Cristal de la cabina
	"e": Color("#1e244a"),
	"f": Color("#344682"),
	# Motores y luces de enemigos
	"r": Color("#8c1628"),
	"R": Color("#f0323c"),
	"y": Color("#ff8c5a"),
	"Y": Color("#ffdc78"),
	"w": Color("#fffae6"),
}

# Mitad izquierda del casco, filas 0 a 24. "L" es la luz de la bodega, que cambia por frame.
const HULL: Array[String] = [
	"................",
	"...............0",
	"..............0R",
	"..............0c",
	".............0dc",
	"....00.......0cb",
	"...0dc0.....0dcb",
	"...0cb0.....0c0f",
	"..0dcba0...0dc0e",
	"..0cffa0...0cbb0",
	"..0ceea0000cbbbb",
	"..0cbba0340cbbbb",
	"..0cbba0120cbbab",
	"..0cbba0000cb000",
	"..0caaa0..0cb0rL",
	"..0cbba0..0cb0rL",
	"..0cbba0..0cb0rL",
	".00cbba0000cb000",
	"030cbba0340cbbbb",
	"020abba0120cbbab",
	"010aaaa0000a1232",
	"00.0aa0...0aabbb",
	"...0220....0aaaa",
	"...0110.....0122",
	"...0000.....0000",
]

# Luz de la bodega por frame
const CORE_LIGHT: Array[String] = ["Y", "y", "w"]

# Mitad izquierda de las llamas, filas 25 a 31, por frame.
const FLAMES: Array[Array] = [
	[
		"....yY.......yYw",
		"....rY.......yYw",
		".....y.......ryY",
		"..............yY",
		"...............y",
		"................",
		"................",
	],
	[
		"....yY.......yYw",
		"....yY.......yYw",
		"....rY.......yYw",
		".....y.......ryY",
		"..............yY",
		"...............r",
		"................",
	],
	[
		"....yY.......yYw",
		"....rY.......ryY",
		"..............yY",
		"...............y",
		"................",
		"................",
		"................",
	],
]


# Trozos en que se parte al morir: filas y columnas (x, ancho) que se recortan del dibujo
# completo, sin la bodega ni las abrazaderas, y se centran en un frame de FRAGMENT_SIZE.
# Las vainas son el casco de las filas 5-12 y 17-24; el centro, el de las filas 1-12 y 20-24.
# Las tres últimas filas de cada trozo son su llama.
const FRAGMENT_SIZE: int = 20
const POD_ROWS: Array[int] = [5, 6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]
const CENTER_ROWS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 20, 21, 22, 23, 24, 25, 26, 27]
const FRAGMENTS: Dictionary[String, Array] = {
	"fragmento_izquierdo": [POD_ROWS, 0, 8],
	"fragmento_central": [CENTER_ROWS, 10, 12],
	"fragmento_derecho": [POD_ROWS, 24, 8],
}

# Grietas del frame de división: las abrazaderas (columnas 7 a 10 de estas filas) se parten en luz.
const CRACK_ROWS: Array[int] = [11, 12, 18, 19]
const CRACK: String = "YwwY"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for frame: int in FLAMES.size():
		var image: Image = _draw(_rows(frame))
		error = _save(image, "divisora_%d" % frame)
		for fragment: String in FRAGMENTS:
			var cut: Array = FRAGMENTS[fragment]
			error = max(error, _save(_cut(image, cut[0], cut[1], cut[2]), "%s_%d" % [fragment, frame]))
	var crack_rows: Array[String] = _rows(0)
	for y: int in CRACK_ROWS:
		crack_rows[y] = crack_rows[y].substr(0, 7) + CRACK + crack_rows[y].substr(11)
	error = max(error, _save(_draw(crack_rows), "divisora_crack"))
	quit(error)


# Medias filas del frame: casco con la luz de la bodega y llamas.
func _rows(frame: int) -> Array[String]:
	var rows: Array[String] = []
	for row: String in HULL:
		rows.append(row.replace("L", CORE_LIGHT[frame]))
	for row: String in FLAMES[frame]:
		rows.append(row)
	return rows


func _save(image: Image, file_name: String) -> Error:
	var path: String = TARGET_DIR + file_name + ".png"
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("Guardado %s (error %d)" % [path, error])
	return error


# Recorta esas filas y columnas del dibujo completo, una debajo de otra, centradas en el frame.
func _cut(source: Image, rows: Array, x: int, width: int) -> Image:
	var image: Image = Image.create(FRAGMENT_SIZE, FRAGMENT_SIZE, false, Image.FORMAT_RGBA8)
	var offset: Vector2i = Vector2i((FRAGMENT_SIZE - width) / 2, (FRAGMENT_SIZE - rows.size()) / 2)
	for i: int in rows.size():
		image.blit_rect(source, Rect2i(x, rows[i], width, 1), offset + Vector2i(0, i))
	return image


# Pinta cada media fila en su sitio y en espejo.
func _draw(rows: Array[String]) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in rows.size():
		var row: String = rows[y]
		assert(row.length() == SIZE / 2, "Fila %d con %d columnas" % [y, row.length()])
		for x: int in row.length():
			var key: String = row[x]
			if key == ".":
				continue
			image.set_pixel(x, y, PALETTE[key])
			image.set_pixel(SIZE - 1 - x, y, PALETTE[key])
	return image
