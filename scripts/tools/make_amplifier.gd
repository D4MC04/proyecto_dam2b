extends SceneTree
## Genera los sprites del Amplificador y del Amplificador mayor
## (assets/sprites/turrets/amplifier/ y assets/sprites/turrets/amplifier_fusion/) y el icono de stat
## de amplificación (assets/ui/stat_icons/amp.png).
##
## Uso: godot --headless --path . -s scripts/tools/make_amplifier.gd
##
## Por carpeta: amplifier_base.png (32x32), amplifier_cannon_idle_sheet.png (4 frames de 32x32 del
## emisor, en bucle: el núcleo late y las luces de los brazos se encienden por turnos, como un faro)
## y amplifier_full_up.png (icono con base y emisor).
##
## La base es la misma plantilla que la del Cañón doble y la Minigun (octógono de 32 px con hueco
## central), con las luces en ámbar. El emisor no gira: es una cúpula de metal con un núcleo de ámbar
## y cuatro brazos en diagonal acabados en una luz. El mayor añade un aro discontinuo de ámbar a la
## base, cuatro luces pequeñas más (arriba, abajo y a los lados) y una cúpula más grande.
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
# Luces de los brazos en diagonal (en el orden de las agujas del reloj) y, en el mayor, las pequeñas.
const ARM_LIGHTS: Array[Vector2] = [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
const SMALL_LIGHTS: Array[Vector2] = [Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)]
# Brillo del núcleo en cada frame (índice en AMBER del tono de fuera): sube, llega arriba y baja.
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

## Un frame del emisor: brazos en diagonal con su luz, cúpula de metal y núcleo de ámbar.
## Las luces de los brazos se encienden de una en una en el sentido de las agujas del reloj.
func _make_emitter(frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var dome_radius: float = 7.6 if _major else 7.0
	# Brazos: barras de metal de 2 px desde la cúpula hasta cada luz, con luz arriba a la izquierda.
	for light: Vector2 in ARM_LIGHTS:
		_draw_arm(light)
	# Luces de los brazos
	for i: int in ARM_LIGHTS.size():
		var lit: bool = i == frame
		_fill_circle(CENTER + ARM_LIGHTS[i], 1.6, AMBER[2] if lit else AMBER[0])
		_put(int(CENTER.x + ARM_LIGHTS[i].x), int(CENTER.y + ARM_LIGHTS[i].y), AMBER[3] if lit else AMBER[1])
	if _major:
		# Luces pequeñas sobre el aro de la base, entre los brazos: se encienden con la del brazo anterior.
		for i: int in SMALL_LIGHTS.size():
			var lit: bool = i == frame
			_fill_circle(CENTER + SMALL_LIGHTS[i], 1.0, AMBER[2] if lit else AMBER[0])
	# Cúpula: aro de metal de 2 px con luz arriba a la izquierda, junta oscura y núcleo dentro
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var distance: float = offset.length()
			if distance >= dome_radius:
				continue
			var light: float = -(offset.x + offset.y) / distance if distance > 0.0 else 0.0
			if distance > dome_radius - 1.0:
				_put(x, y, METAL[3] if light > 0.5 else (METAL[2] if light > -0.3 else METAL[1]))
			elif distance > dome_radius - 2.0:
				_put(x, y, METAL[2] if light > 0.5 else (METAL[1] if light > -0.3 else METAL[0]))
			else:
				# Junta oscura entre el aro y el núcleo
				_put(x, y, OUTLINE)
	_draw_core(frame, dome_radius - 3.0)
	_close_outline()
	return _image


## Barra de 2 px de grueso desde el centro hasta `light` (posición de su luz respecto al centro).
func _draw_arm(light: Vector2) -> void:
	var direction: Vector2 = light.normalized()
	var length: float = light.length()
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var along: float = offset.dot(direction)
			var across: float = offset.x * direction.y - offset.y * direction.x
			if along < 0.0 or along > length or absf(across) > 1.0:
				continue
			# El lado que mira arriba a la izquierda recibe la luz.
			var lit_side: bool = across * (direction.y - direction.x) <= 0.0
			_put(x, y, METAL[2] if lit_side else METAL[1])


## Núcleo de ámbar de radio `radius`: late con CORE_LEVELS y tiene un brillo arriba a la izquierda.
func _draw_core(frame: int, radius: float) -> void:
	var level: int = CORE_LEVELS[frame]
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var distance: float = offset.length()
			if distance >= radius:
				continue
			# Anillos de fuera a dentro, cada uno un tono más claro
			var ring: int = 0 if distance >= radius - 1.2 else (1 if distance >= radius - 2.4 else 2)
			_put(x, y, AMBER[mini(level + ring, 3)])
	# Brillo arriba a la izquierda, más fuerte con el núcleo encendido
	_put(14, 14, AMBER[3] if level > 0 else AMBER[2])
	_put(15, 13, AMBER[3] if level > 1 else AMBER[2])


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
