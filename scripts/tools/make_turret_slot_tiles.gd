extends SceneTree
## Genera espacio_casillas_torreta.png: los asteroides con plataforma de las casillas de torreta.
##
## Uso: godot --headless --path . -s scripts/tools/make_turret_slot_tiles.gd [-- vista_previa.png]
##
## Cada pieza es de 32x32 (2x2 casillas): una roca redonda e irregular con luz arriba a la
## izquierda y cráteres, una placa de metal octogonal encima y un aro de luces cian entre la placa
## y el borde de la roca. Una fila por familia de roca (ver FAMILIES), con los colores de su roca de
## 2x2 del atlas de rocas, y SHAPES formas distintas por fila. map_generator.gd pone en cada casilla
## de torreta la fila de la familia de su zona.
## Con una ruta de vista previa, guarda también las piezas a escala sobre el fondo del espacio.

const TARGET: String = "res://assets/tilesets/espacio/espacio_casillas_torreta.png"
const ROCKS_ATLAS: String = "res://assets/tilesets/espacio/espacio_rocas.png"
const SIZE: int = 32
const SHAPES: int = 4
const CENTER: Vector2 = Vector2(15.5, 15.5)
const RANDOM_SEED: int = 3232
const PREVIEW_SCALE: int = 3

# Familias en el orden de las filas, con la esquina de su roca de 2x2 en el atlas de rocas (en píxeles)
const FAMILIES: Array[String] = ["grey", "brown", "dark", "ore", "ice", "crystal", "lava"]
const ROCK_REGIONS: Array[Vector2i] = [
	Vector2i(0, 64), Vector2i(64, 64), Vector2i(128, 64), Vector2i(192, 64), Vector2i(224, 64),
	Vector2i(32, 96), Vector2i(64, 96),
]
# Colores más frecuentes de la roca que se usan para sacar su rampa
const RAMP_SOURCE_COLORS: int = 5
# Vetas de las familias con color propio (mineral, cristal, lava)
const VEINS: int = 5
const VEIN_MIN_SATURATION: float = 0.4

const OUTLINE: Color = Color("#0c0e16")
const SPACE: Color = Color("#0a1226")
# Metal gris azulado: sombra, medio, luz y brillo
const METAL: PackedColorArray = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6"), Color("#d2dceb")]
const CYAN: PackedColorArray = [Color("#1c7496"), Color("#40e0f0"), Color("#befaff")]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = RANDOM_SEED
	var image: Image = Image.create(SHAPES * SIZE, FAMILIES.size() * SIZE, false, Image.FORMAT_RGBA8)
	var rocks: Image = Image.load_from_file(ProjectSettings.globalize_path(ROCKS_ATLAS))
	for row: int in FAMILIES.size():
		var ramp: PackedColorArray = _rock_ramp(rocks, ROCK_REGIONS[row])
		var vein: Color = _vein_color(rocks, ROCK_REGIONS[row], ramp)
		for shape: int in SHAPES:
			_draw_piece(image, Vector2i(shape, row) * SIZE, ramp, vein)
	var error: Error = image.save_png(ProjectSettings.globalize_path(TARGET))
	print("Guardado %s (error %d)" % [TARGET, error])
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if error == OK and not args.is_empty():
		error = _save_preview(image, args[0])
	quit(error)


## vein es el color de las vetas (mineral, cristal o lava), o transparente si la familia no tiene.
func _draw_piece(image: Image, origin: Vector2i, ramp: PackedColorArray, vein: Color) -> void:
	# El borde de la roca ondula con dos senos de fase aleatoria: cada forma es distinta
	var phase_a: float = _rng.randf() * TAU
	var phase_b: float = _rng.randf() * TAU
	var rock: Callable = func(p: Vector2i) -> bool:
		var offset: Vector2 = Vector2(p) - CENTER
		var radius: float = minf(14.6 + 0.9 * sin(3.0 * offset.angle() + phase_a) + 0.6 * sin(5.0 * offset.angle() + phase_b), 15.6)
		return offset.length() <= radius
	var plate: Callable = func(p: Vector2i) -> bool: return _cut_square(p, 9, 5)
	var plate_inside: Callable = func(p: Vector2i) -> bool: return _cut_square(p, 11, 5)
	for y: int in SIZE:
		for x: int in SIZE:
			var p: Vector2i = Vector2i(x, y)
			if not rock.call(p):
				continue
			# Luz arriba a la izquierda, más fuerte hacia el borde
			var offset: Vector2 = Vector2(p) - CENTER
			var light: float = offset.normalized().dot(Vector2(-0.707, -0.707)) * offset.length() / 14.6
			var tone: int = 3 if light > 0.55 else (2 if light > -0.3 else (1 if light > -0.75 else 0))
			image.set_pixelv(origin + p, ramp[tone])
	_outline(image, origin, rock, OUTLINE)
	# Cráteres en la parte de roca que queda fuera de la placa
	for i: int in 3:
		var angle: float = _rng.randf() * TAU
		var p: Vector2i = Vector2i((CENTER + Vector2.from_angle(angle) * 9.0).floor())
		if rock.call(p + Vector2i(2, 2)) and rock.call(p - Vector2i(1, 1)) and not plate.call(p) and not plate.call(p + Vector2i.ONE):
			image.fill_rect(Rect2i(origin + p, Vector2i(2, 2)), ramp[0])
			image.set_pixelv(origin + p + Vector2i.ONE, ramp[2])
	# Vetas de 2 px, en horizontal o en vertical, en la roca de fuera de la placa
	if vein.a > 0.0:
		for i: int in VEINS:
			var p: Vector2i = Vector2i((CENTER + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(9.0, 12.0)).floor())
			var step: Vector2i = Vector2i.RIGHT if _rng.randf() < 0.5 else Vector2i.DOWN
			for q: Vector2i in [p, p + step]:
				if _distance(q) < 12.0 and rock.call(q) and not plate.call(q) and image.get_pixelv(origin + q) != OUTLINE:
					image.set_pixelv(origin + q, vein)
	# Aro de luces: 8 trazos en un anillo entre la placa y el borde
	_fill(image, origin, func(p: Vector2i) -> bool: return _distance(p) >= 12.0 and _distance(p) <= 12.9 \
		and rock.call(p) and posmod(int(floor((Vector2(p) - CENTER).angle() / TAU * 16.0)), 2) == 0, CYAN[1])
	_fill(image, origin, plate, METAL[1])
	_fill(image, origin, func(p: Vector2i) -> bool: return plate.call(p) and not plate_inside.call(p), METAL[0])
	_fill(image, origin, func(p: Vector2i) -> bool: return plate.call(p) and not plate_inside.call(p) and _lit(p), METAL[2])
	_outline(image, origin, plate, OUTLINE)
	_fill(image, origin, func(p: Vector2i) -> bool: return _distance(p) <= 2.5, CYAN[0])
	_fill(image, origin, func(p: Vector2i) -> bool: return _distance(p) <= 1.5, CYAN[1])


## Rampa de 4 tonos de la roca de 2x2 de una familia: sus colores más frecuentes ordenados por
## luminancia, sin el más oscuro (el contorno). Así las motas de mineral o cristal no cuentan.
func _rock_ramp(rocks: Image, region: Vector2i) -> PackedColorArray:
	var counts: Dictionary[Color, int] = {}
	for y: int in SIZE:
		for x: int in SIZE:
			var color: Color = rocks.get_pixel(region.x + x, region.y + y)
			if color.a > 0.99:
				counts[color] = counts.get(color, 0) + 1
	var colors: Array[Color] = []
	colors.assign(counts.keys())
	colors.sort_custom(func(a: Color, b: Color) -> bool: return counts[a] > counts[b])
	colors.resize(mini(colors.size(), RAMP_SOURCE_COLORS))
	colors.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	colors.remove_at(0)
	var ramp: PackedColorArray = []
	for i: int in 4:
		ramp.append(colors[roundi(i * (colors.size() - 1) / 3.0)])
	return ramp


## Color de las vetas de la roca: el más vivo (saturado y claro) de los que salen varias veces, si es bastante
## saturado y no está ya en la rampa (en el hielo o la roca marrón el color es la propia roca).
func _vein_color(rocks: Image, region: Vector2i, ramp: PackedColorArray) -> Color:
	var counts: Dictionary[Color, int] = {}
	for y: int in SIZE:
		for x: int in SIZE:
			var color: Color = rocks.get_pixel(region.x + x, region.y + y)
			if color.a > 0.99:
				counts[color] = counts.get(color, 0) + 1
	var best: Color = Color.TRANSPARENT
	for color: Color in counts:
		if counts[color] >= 2 and color.s * color.v > best.s * best.v:
			best = color
	if best.s < VEIN_MIN_SATURATION or ramp.has(best):
		return Color.TRANSPARENT
	return best


## Vista previa a escala: el atlas sobre el fondo del espacio, con un hueco entre piezas.
func _save_preview(atlas: Image, path: String) -> Error:
	var cell: int = SIZE + 8
	var preview: Image = Image.create(SHAPES * cell, FAMILIES.size() * cell, false, Image.FORMAT_RGBA8)
	preview.fill(SPACE)
	for row: int in FAMILIES.size():
		for shape: int in SHAPES:
			preview.blend_rect(atlas, Rect2i(Vector2i(shape, row) * SIZE, Vector2i(SIZE, SIZE)), Vector2i(shape, row) * cell + Vector2i(4, 4))
	preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	var error: Error = preview.save_png(path)
	print("Vista previa %s (error %d)" % [path, error])
	return error


func _fill(image: Image, origin: Vector2i, inside: Callable, color: Color) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			if inside.call(Vector2i(x, y)):
				image.set_pixelv(origin + Vector2i(x, y), color)


## Pinta los píxeles de la forma que tienen algún vecino en cruz fuera de ella.
func _outline(image: Image, origin: Vector2i, inside: Callable, color: Color) -> void:
	_fill(image, origin, func(p: Vector2i) -> bool:
		if not inside.call(p):
			return false
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + step
			if q.x < 0 or q.y < 0 or q.x >= SIZE or q.y >= SIZE or not inside.call(q):
				return true
		return false, color)


## Cuadrado con un margen de inset píxeles y las esquinas biseladas cut píxeles en diagonal.
func _cut_square(p: Vector2i, inset: int, cut: int) -> bool:
	var high: int = SIZE - 1 - inset
	if p.x < inset or p.y < inset or p.x > high or p.y > high:
		return false
	return mini(p.x - inset, high - p.x) + mini(p.y - inset, high - p.y) >= cut


func _distance(p: Vector2i) -> float:
	return (Vector2(p) - CENTER).length()


## Mitad de arriba a la izquierda de la pieza (la que recibe la luz).
func _lit(p: Vector2i) -> bool:
	return p.x + p.y < SIZE - 1
