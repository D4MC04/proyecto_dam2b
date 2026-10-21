extends SceneTree
## Genera espacio_gravilla.png: gravilla de roca para el suelo del campo de asteroides de los mapas.
##
## Uso: godot --headless --path . -s scripts/tools/make_gravel_tiles.gd
##
## La gravilla son granos de 1 px y esquirlas de 2x2 sin contorno, en los tonos oscuros de las
## rocas pequeñas, para que se lea como polvo de roca lejano y no tape nada. Una fila por paleta
## (ver PALETTES); en cada fila, SPARSE_COUNT piezas con poca gravilla y luego DENSE_COUNT con más.
## map_generator.gd la pone en todo lo que no es pasillo.

const TARGET: String = "res://assets/tilesets/espacio/espacio_gravilla.png"
const TILE: int = 16
const SPARSE_COUNT: int = 4
const DENSE_COUNT: int = 4
const RANDOM_SEED: int = 4242

# Por paleta: sombra, medio y luz (los tres tonos más oscuros de la roca pequeña de esa familia)
const PALETTES: Array[PackedColorArray] = [
	# Gris
	[Color("#2c2a38"), Color("#444252"), Color("#625e70")],
	# Marrón
	[Color("#382622"), Color("#583c30"), Color("#7c5842")],
	# Oscura
	[Color("#1c1c28"), Color("#2a2a38"), Color("#3c3c4e")],
]

# Granos y esquirlas de cada pieza: poca gravilla y mucha
const SPARSE_GRAINS: Vector2i = Vector2i(3, 5)
const SPARSE_CHIPS: Vector2i = Vector2i(0, 1)
const DENSE_GRAINS: Vector2i = Vector2i(7, 10)
const DENSE_CHIPS: Vector2i = Vector2i(2, 3)


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RANDOM_SEED
	var columns: int = SPARSE_COUNT + DENSE_COUNT
	var image: Image = Image.create(columns * TILE, PALETTES.size() * TILE, false, Image.FORMAT_RGBA8)
	for row: int in PALETTES.size():
		for column: int in columns:
			var dense: bool = column >= SPARSE_COUNT
			var grains: Vector2i = DENSE_GRAINS if dense else SPARSE_GRAINS
			var chips: Vector2i = DENSE_CHIPS if dense else SPARSE_CHIPS
			_draw_tile(image, Vector2i(column, row) * TILE, PALETTES[row], rng.randi_range(grains.x, grains.y), rng.randi_range(chips.x, chips.y), rng)
	var error: Error = image.save_png(ProjectSettings.globalize_path(TARGET))
	print("Guardado %s (error %d)" % [TARGET, error])
	quit(error)


## Primero las esquirlas y luego los granos, cada uno con un píxel libre alrededor y sin tocar el
## borde de la pieza, para que no se junten con los de las piezas vecinas.
func _draw_tile(image: Image, origin: Vector2i, palette: PackedColorArray, grains: int, chips: int, rng: RandomNumberGenerator) -> void:
	var used: Dictionary[Vector2i, bool] = {}
	for i: int in chips:
		var pixel: Vector2i = _free_spot(used, Vector2i(2, 2), rng)
		if pixel.x < 0:
			continue
		# Luz arriba a la izquierda, sombra abajo a la derecha
		image.set_pixelv(origin + pixel, palette[2])
		image.set_pixelv(origin + pixel + Vector2i(1, 0), palette[1])
		image.set_pixelv(origin + pixel + Vector2i(0, 1), palette[1])
		image.set_pixelv(origin + pixel + Vector2i(1, 1), palette[0])
	for i: int in grains:
		var pixel: Vector2i = _free_spot(used, Vector2i.ONE, rng)
		if pixel.x < 0:
			continue
		image.set_pixelv(origin + pixel, palette[rng.randi_range(1, 2)])


## Esquina de un hueco libre del tamaño dado (con margen de 1 px) y lo marca; (-1, -1) si no hay.
func _free_spot(used: Dictionary[Vector2i, bool], size: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	for attempt: int in 50:
		var corner: Vector2i = Vector2i(rng.randi_range(1, TILE - 1 - size.x), rng.randi_range(1, TILE - 1 - size.y))
		var free: bool = true
		for y: int in range(-1, size.y + 1):
			for x: int in range(-1, size.x + 1):
				if used.has(corner + Vector2i(x, y)):
					free = false
		if not free:
			continue
		for y: int in size.y:
			for x: int in size.x:
				used[corner + Vector2i(x, y)] = true
		return corner
	return Vector2i(-1, -1)
