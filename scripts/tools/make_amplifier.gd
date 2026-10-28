extends SceneTree
## Genera los sprites del Amplificador y del Amplificador mayor
## (assets/sprites/turrets/amplifier/ y assets/sprites/turrets/amplifier_fusion/) y el icono de stat
## de amplificación (assets/ui/stat_icons/amp.png).
##
## Uso: godot --headless --path . -s scripts/tools/make_amplifier.gd
##
## Por carpeta: amplifier_base.png (32x32), amplifier_cannon_idle_sheet.png (4 frames de 32x32 del
## emisor, en bucle: el cristal late y los segmentos del resonador se encienden por turnos, como un faro)
## y amplifier_full_up.png (icono con base y emisor).
##
## La base es la misma plantilla que la del Cañón doble y la Minigun (octógono de 32 px con hueco
## central), con las luces en ámbar. El emisor no gira: aro de metal con abrazaderas y luces, disco
## resonador de ámbar por segmentos y cristal facetado en el centro (como la placa de la Tesla). El
## mayor añade un aro discontinuo de ámbar a la base, un emisor más grande con más segmentos y luces
## en las abrazaderas.
## Caracteres de las plantillas: "." vacío, "O" contorno, "1" a "4" metal de sombra a luz y "a" a
## "c" ámbar de oscuro a claro, "w" casi blanco.

const SIZE: int = 32
const FRAMES: int = 4
const ICON_SIZE: int = 8

const OUTLINE: Color = Color("#0c0e16")
# Metal gris azulado de las torretas, de sombra a luz (ver docs/design/art.md)
const METAL: PackedColorArray = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6"), Color("#d2dceb")]
# Acento del Amplificador: ámbar de oscuro a claro y núcleo casi blanco
const AMBER: PackedColorArray = [Color("#96641e"), Color("#ecb23c"), Color("#ffe082"), Color("#fff8e6")]

# Base: la misma silueta y luz que la del Cañón doble (t1_base.png), con luces en las esquinas.
const BASE: Array[String] = [
	"................................",
	"..........OOOOOOOOOOOO..........",
	".........O111111111111O.........",
	"........O11333333333211O........",
	".......O1133333333322211O.......",
	"......O113333333332222211O......",
	".....Oba33333333322222221ba.....",
	"....O1aa3333OOOOOOOO22222aaO....",
	"...O1133333OO111111OO2222211O...",
	"..O113333OO1111111111OO222211O..",
	".O1133333O111111111111O2222211O.",
	".O133333O11111111111111O222221O.",
	".O13333OO11111111111111OO22221O.",
	".O13333O1111111111111111O22221O.",
	".O13333O1111111111111111O22211O.",
	".O13333O1111111111111111O22111O.",
	".O13333O1111111111111111O21111O.",
	".O13332O1111111111111111O11111O.",
	".O13322O1111111111111111O11111O.",
	".O13222OO11111111111111OO11111O.",
	".O122222O11111111111111O111111O.",
	".O1122222O111111111111O1111111O.",
	"..O112222OO1111111111OO111111O..",
	"...O1122222OO111111OO1111111O...",
	"....O1122222OOOOOOOO1111111O....",
	".....Oba22222222211111111ba.....",
	"......aa12222222111111111aa.....",
	".......O1122222111111111O.......",
	"........O11222111111111O........",
	".........O111111111111O.........",
	"..........OOOOOOOOOOOO..........",
	"................................",
]

# Icono de stat: dos chevrones hacia arriba, el de abajo más oscuro (contorno en cruz alrededor).
const AMP_ICON: Array[String] = [
	"........",
	"...cc...",
	"..cbbc..",
	".cb..bc.",
	"...bb...",
	"..baab..",
	".ba..ab.",
	"........",
]

const CENTER: Vector2 = Vector2(15.5, 15.5)
# Brillo del cristal en cada frame (índice en AMBER del tono de fuera): sube, llega arriba y baja.
const CORE_LEVELS: Array[int] = [0, 1, 2, 1]

var _image: Image
var _major: bool = false


func _initialize() -> void:
	var error: Error = OK
	for major: bool in [false, true]:
		_major = major
		var dir: String = "res://assets/sprites/turrets/%s/" % ("amplifier_fusion" if major else "amplifier")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var base: Image = _make_base()
		var emitters: Array[Image] = []
		for frame: int in FRAMES:
			emitters.append(_make_emitter(frame))
		var icon: Image = base.duplicate()
		# El icono enseña el núcleo encendido.
		icon.blend_rect(emitters[2], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
		error = maxi(error, _save(base, dir + "amplifier_base.png"))
		error = maxi(error, _save(_sheet(emitters), dir + "amplifier_cannon_idle_sheet.png"))
		error = maxi(error, _save(icon, dir + "amplifier_full_up.png"))
	error = maxi(error, _save(_make_stat_icon(), "res://assets/ui/stat_icons/amp.png"))
	quit(error)


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("Guardado %s (error %d)" % [path, error])
	return error


## Une varias imágenes del mismo tamaño en una tira horizontal.
func _sheet(frames: Array[Image]) -> Image:
	var width: int = frames[0].get_width()
	var sheet: Image = Image.create(width * frames.size(), frames[0].get_height(), false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, width, frames[i].get_height()), Vector2i(width * i, 0))
	return sheet


# --- Base ---

func _make_base() -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		_paint_row(0, y, BASE[y])
	# Luces arriba y abajo
	_paint_row(15, 2, "ab")
	_paint_row(15, 29, "aa")
	if _major:
		_draw_major_ring()
	return _image


## El mayor añade un aro discontinuo de ámbar alrededor del hueco y luces más grandes en las esquinas.
func _draw_major_ring() -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var distance: float = offset.length()
			if distance < 9.6 or distance >= 10.6 or _image.get_pixel(x, y).is_equal_approx(OUTLINE):
				continue
			# Ocho tramos con un hueco entre ellos
			var segment: float = fposmod(offset.angle() / TAU * 8.0 + 0.5, 1.0)
			if segment > 0.2:
				_put(x, y, AMBER[1] if offset.x + offset.y < 0.0 else AMBER[0])
	for corner: Vector2i in [Vector2i(6, 6), Vector2i(25, 6), Vector2i(6, 25), Vector2i(25, 25)]:
		_paint_row(corner.x, corner.y, "cb")
		_paint_row(corner.x, corner.y + 1, "ba")


# --- Emisor ---

## Un frame del emisor, de fuera a dentro: aro de metal con cuatro abrazaderas y cuatro luces en
## diagonal, junta oscura, disco resonador de ámbar partido en segmentos por radios oscuros (con
## bandas como las bobinas de la Tesla) y cristal facetado en el centro. Los segmentos se encienden
## por turnos (giran como un faro) y el cristal late con CORE_LEVELS.
func _make_emitter(frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var ring_radius: float = 9.9 if _major else 9.4
	var core_radius: float = 5.0 if _major else 4.4
	var segments: int = 12 if _major else 8
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var distance: float = offset.length()
			if distance >= ring_radius:
				continue
			# Luz arriba a la izquierda: 1 de cara a la luz, -1 en sombra.
			var light: float = -(offset.x + offset.y) / maxf(distance, 0.001) / sqrt(2.0)
			if distance >= ring_radius - 2.0:
				_put(x, y, _metal_lit(light, distance >= ring_radius - 1.0))
			elif distance >= ring_radius - 3.0:
				# Junta oscura entre el aro y el disco
				_put(x, y, OUTLINE)
			else:
				_put(x, y, _resonator_color(offset, distance, segments, frame, light))
	_draw_crystal(frame, core_radius)
	_draw_clamps(ring_radius)
	_draw_ring_lights(ring_radius, frame)
	_close_outline()
	return _image


## Metal del aro: banda de fuera más clara que la de dentro, las dos con luz arriba a la izquierda.
func _metal_lit(light: float, outer: bool) -> Color:
	var level: int = 2 if light > 0.45 else (1 if light > -0.35 else 0)
	return METAL[mini(level + (1 if outer else 0), 3)]


## Disco resonador: radios oscuros entre segmentos, bandas alternas de ámbar y el segmento que toca
## en este frame un tono más claro.
func _resonator_color(offset: Vector2, distance: float, segments: int, frame: int, light: float) -> Color:
	var turn: float = fposmod(offset.angle() / TAU + 0.25, 1.0) * segments
	if fposmod(turn, 1.0) < 0.12 and distance > 3.0:
		return AMBER[0].darkened(0.45)
	var segment: int = int(turn)
	var lit: bool = segment % FRAMES == frame
	# Bandas concéntricas: la de fuera y la del medio más claras, como una bobina
	var band: int = 1 if int(distance) % 2 == 1 else 0
	var level: int = band + (1 if lit else 0) + (1 if light > 0.55 else 0) - (1 if light < -0.55 else 0)
	return AMBER[clampi(level, 0, 3)]


## Cristal de ámbar en rombo con cuatro caras: la de arriba a la izquierda es la más clara.
func _draw_crystal(frame: int, radius: float) -> void:
	var level: int = CORE_LEVELS[frame]
	var size: float = radius - 0.6
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var edge: float = absf(offset.x) + absf(offset.y)
			if edge > size + 1.0:
				continue
			if edge > size:
				# Contorno del cristal sobre el disco
				_put(x, y, OUTLINE)
				continue
			var face: int
			if offset.x < 0.0 and offset.y < 0.0:
				face = 2
			elif offset.x >= 0.0 and offset.y >= 0.0:
				face = 0
			else:
				face = 1
			_put(x, y, AMBER[mini(face + level, 3)])
	# Brillo en la cara de luz
	_put(14, 14, AMBER[3])
	if level >= 2:
		_put(15, 15, AMBER[3])


## Cuatro abrazaderas de metal (arriba, abajo y a los lados) que sujetan el aro a la base, con una
## ranura oscura en medio. En el mayor llevan una luz de ámbar en la punta.
func _draw_clamps(ring_radius: float) -> void:
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		for y: int in SIZE:
			for x: int in SIZE:
				var offset: Vector2 = Vector2(x, y) - CENTER
				var along: float = offset.dot(direction)
				var across: float = offset.x * direction.y - offset.y * direction.x
				if along < ring_radius - 2.0 or along > ring_radius + 2.5 or absf(across) > 1.6:
					continue
				if absf(across) < 0.6 and along > ring_radius + 1.5:
					_put(x, y, AMBER[2] if _major else METAL[2])
				elif absf(across) < 0.6 and along > ring_radius - 1.0:
					# Ranura de la abrazadera
					_put(x, y, OUTLINE)
				else:
					var light: float = -(direction.x + direction.y) - across * (direction.y - direction.x) * 0.5
					_put(x, y, METAL[3] if light > 0.0 else METAL[1])


## Cuatro luces de ámbar en diagonal sobre el aro, que se encienden con los segmentos.
func _draw_ring_lights(ring_radius: float, frame: int) -> void:
	var diagonals: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for i: int in diagonals.size():
		var center: Vector2 = CENTER + diagonals[i].normalized() * (ring_radius - 1.0)
		var lit: bool = i == frame
		_fill_circle(center, 0.9, AMBER[2] if lit else AMBER[0])


# --- Icono de stat ---

func _make_stat_icon() -> Image:
	_image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in ICON_SIZE:
		_paint_row(0, y, AMP_ICON[y])
	_close_outline()
	return _image


# --- Utilidades ---

func _put(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < _image.get_width() and y < _image.get_height():
		_image.set_pixel(x, y, color)


## Pinta un trozo de plantilla desde (x, y) hacia la derecha; "." no pinta nada.
func _paint_row(x: int, y: int, row: String) -> void:
	for i: int in row.length():
		var symbol: String = row[i]
		if symbol != ".":
			_put(x + i, y, _color(symbol))


func _color(symbol: String) -> Color:
	match symbol:
		"O":
			return OUTLINE
		"1", "2", "3", "4":
			return METAL[int(symbol) - 1]
		"a":
			return AMBER[0]
		"b":
			return AMBER[1]
		"c":
			return AMBER[2]
		"w":
			return AMBER[3]
	push_error("Carácter de plantilla desconocido: %s" % symbol)
	return Color.MAGENTA


func _fill_circle(center: Vector2, radius: float, color: Color) -> void:
	for y: int in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if (Vector2(x, y) - center).length_squared() <= radius * radius:
				_put(x, y, color)


## Pinta de contorno los píxeles vacíos que tocan (en cruz) a uno opaco que no sea ya contorno.
func _close_outline() -> void:
	var source: Image = _image.duplicate()
	var width: int = _image.get_width()
	var height: int = _image.get_height()
	for y: int in height:
		for x: int in width:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
					continue
				var color: Color = source.get_pixel(neighbor.x, neighbor.y)
				if color.a > 0.0 and not color.is_equal_approx(OUTLINE):
					_image.set_pixel(x, y, OUTLINE)
					break
