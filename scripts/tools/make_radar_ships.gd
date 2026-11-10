extends SceneTree
## Genera los iconos de las naves del radar de sectores (assets/sprites/enemies/radar/).
##
## Uso: godot --headless --path . -s scripts/tools/make_radar_ships.gd
##
## Cuatro naves de 16x16 sacadas de las plantillas de texto de abajo (un carácter por píxel):
## X = casco, o = ojo. El casco va en grises (luz arriba, sombra abajo) con contorno, para teñirlo
## con `modulate` según el estado del contacto; los ojos son un hueco oscuro en el casco. Cada nave
## tiene además un `_eyes.png` con solo los ojos en blanco, que el radar pinta encima en rojo y hace
## parpadear.

const TARGET_DIR: String = "res://assets/sprites/enemies/radar/"
const SIZE: int = 16

const OUTLINE: Color = Color("#0a0810")
# Casco en grises para teñir: borde de arriba, cuerpo y borde de abajo
const HULL_LIGHT: Color = Color("#ffffff")
const HULL_MID: Color = Color("#d0d0d0")
const HULL_SHADOW: Color = Color("#8c8c8c")
const EYE: Color = Color("#ffffff")

# Nombre del archivo -> plantilla (mismo orden que LevelData.RadarShip)
const PATTERNS: Dictionary[String, Array] = {
	# Incursor: alas en punta y pinzas
	"raider": [
		"X.........X",
		"XX.......XX",
		".XX.XXX.XX.",
		"..XXXXXXX..",
		".XXXoXoXXX.",
		"XXXXXXXXXXX",
		"X.XX.X.XX.X",
		"X..X...X..X",
		"...X...X...",
	],
	# Colmillo: rápido, con mandíbulas
	"fang": [
		"..X.....X..",
		".XXX...XXX.",
		"XX.XXXXX.XX",
		"X.XXoXoXX.X",
		"..XXXXXXX..",
		".X.X.X.X.X.",
		"X...X.X...X",
	],
	# Triturador: blindado y ancho
	"crusher": [
		".XXX...XXX.",
		"XXXXXXXXXXX",
		"XXoXXXXXoXX",
		"XXXXXXXXXXX",
		".X.XXXXX.X.",
		"XX.......XX",
		"X.X.....X.X",
	],
	# Espectro: cabeza grande y tentáculos
	"specter": [
		"....XXX....",
		"..XXXXXXX..",
		".XXoXXXoXX.",
		"XXXXXXXXXXX",
		"X.XX.X.XX.X",
		"X.X..X..X.X",
		"..X.....X..",
	],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET_DIR))
	var error: Error = OK
	for ship: String in PATTERNS:
		var pattern: Array = PATTERNS[ship]
		error = _save(_draw_hull(pattern), "radar_%s.png" % ship)
		if error != OK:
			break
		error = _save(_draw_eyes(pattern), "radar_%s_eyes.png" % ship)
		if error != OK:
			break
	quit(error)


func _save(image: Image, file_name: String) -> Error:
	var path: String = TARGET_DIR + file_name
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("Guardado %s (error %d)" % [path, error])
	return error


# Esquina de arriba a la izquierda de la plantilla, centrada en el lienzo.
@warning_ignore("integer_division")
func _origin(pattern: Array) -> Vector2i:
	var width: int = (pattern[0] as String).length()
	return Vector2i((SIZE - width) / 2, (SIZE - pattern.size()) / 2)


func _cell(pattern: Array, x: int, y: int) -> String:
	if y < 0 or y >= pattern.size():
		return "."
	var row: String = pattern[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


func _draw_hull(pattern: Array) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var origin: Vector2i = _origin(pattern)
	for y: int in pattern.size():
		for x: int in (pattern[y] as String).length():
			var cell: String = _cell(pattern, x, y)
			if cell == ".":
				continue
			var color: Color = HULL_MID
			if cell == "o":
				color = OUTLINE
			elif _cell(pattern, x, y + 1) == ".":
				color = HULL_SHADOW
			elif _cell(pattern, x, y - 1) == ".":
				color = HULL_LIGHT
			image.set_pixelv(origin + Vector2i(x, y), color)
	# Contorno: los huecos que tocan el casco por un lado
	var outline: Array[Vector2i] = []
	for y: int in SIZE:
		for x: int in SIZE:
			if image.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if Rect2i(0, 0, SIZE, SIZE).has_point(neighbor) and image.get_pixelv(neighbor).a > 0.0:
					outline.append(Vector2i(x, y))
					break
	for point: Vector2i in outline:
		image.set_pixelv(point, OUTLINE)
	return image


func _draw_eyes(pattern: Array) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var origin: Vector2i = _origin(pattern)
	for y: int in pattern.size():
		for x: int in (pattern[y] as String).length():
			if _cell(pattern, x, y) == "o":
				image.set_pixelv(origin + Vector2i(x, y), EYE)
	return image
