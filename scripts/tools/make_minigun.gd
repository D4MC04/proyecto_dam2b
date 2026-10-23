extends SceneTree
## Genera los sprites de la Minigun y de la Minigun pesada
## (assets/sprites/turrets/minigun/ y assets/sprites/turrets/minigun_fusion/).
##
## Uso: godot --headless --path . -s scripts/tools/make_minigun.gd
##
## Por carpeta: minigun_base.png (32x32), minigun_cannon_sheet.png (5 frames de 32x32: reposo,
## fire_0 y fire_1 con las bocas encendidas, los tubos girando y la cinta de munición avanzando),
## minigun_full_up.png (icono con base y cañón), minigun_flash_sheet.png (3 frames de 16x16),
## minigun_bullet_sheet.png (2 frames de 4x8, trazadora) y minigun_impact_sheet.png (4 frames de
## 16x16).
##
## Base y cañón se dibujan con plantillas de texto, un carácter por píxel, con las mismas medidas
## que el Cañón doble: base octogonal de 32 px con hueco central y cañón de la fila 3 a la 25.
## Caracteres: "." vacío, "O" contorno, "1" a "4" metal de sombra a luz, "a" a "c" acento de
## oscuro a claro y "w" núcleo casi blanco. Los efectos no llevan contorno.

const SIZE: int = 32
const EFFECT_SIZE: int = 16
const CANNON_FRAMES: int = 5

const OUTLINE: Color = Color("#0c0e16")
# Metal gris azulado de las torretas, de sombra a luz (ver docs/design/art.md)
const METAL: PackedColorArray = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6"), Color("#d2dceb")]
# Acento de la Minigun: naranja de trazadora, de oscuro a claro, y núcleo casi blanco
const ORANGE: PackedColorArray = [Color("#a8401a"), Color("#ff7326"), Color("#ffc890"), Color("#fff4e0")]
# Acento nuevo de la Minigun pesada: rojo, de oscuro a claro, y núcleo casi blanco
const RED: PackedColorArray = [Color("#961432"), Color("#ff3c5a"), Color("#ffaabe"), Color("#fff0f4")]

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

# Carcasa del cañón (filas 14 a 24, sin el contorno de los lados): rotor redondo con núcleo de acento en el centro,
# junta oscura, franja de acento y rejilla de ventilación atrás.
const HOUSING: Array[String] = [
	"33333333333221",
	"32222OOOO22211",
	"3222O3322O2211",
	"322O32cb21O211",
	"322O22ba11O211",
	"3222O2211O2211",
	"32222OOOO22211",
	"31111111111111",
	"3abbbbbbbbbba1",
	"32O2O2O2O2O211",
	"32222222222211",
]
# Carcasa de la Minigun pesada: más ancha, rotor igual y franjas de aviso atrás.
const HEAVY_HOUSING: Array[String] = [
	"3333333333333221",
	"322222OOOO222211",
	"32222O3322O22211",
	"3222O32cb21O2211",
	"3222O22ba11O2211",
	"32222O2211O22211",
	"322222OOOO222211",
	"3111111111111111",
	"3bbOObbOObbOObb1",
	"3bOObbOObbOObbO1",
	"32O2O2O2O2O2O211",
]
const HOUSING_TOP: int = 14
# Tubos (x 9 a 22, el ancho de la carcasa): separadores de contorno, cuatro tubos de 2 px y el eje
# en el centro (x 15 y 16)
const TUBE_SEPARATORS: Array[int] = [9, 12, 19, 22]
const TUBES: Array[Array] = [[10, 11], [13, 14], [15, 16], [17, 18], [20, 21]]
# Filas bajo las bocas: "T" tubos, "C"/"c" abrazadera con acento, "R"/"r" abrazadera de acento, "M" de metal
const TUBE_ROWS: Array[String] = ["T", "T", "C", "c", "T", "T", "T", "T"]
const HEAVY_TUBE_ROWS: Array[String] = ["T", "T", "R", "r", "T", "T", "M", "T", "T"]
# Sombreado de cada tubo (y el eje) en las dos fases del giro, de izquierda a derecha
const TUBE_SHADES: Array[Array] = [
	["32", "43", "11", "32", "21"],
	["23", "34", "11", "23", "12"],
]
# Bocas de los tubos: en reposo, encendidas al disparar y apagándose
const BORES: Array[Array] = [
	["1O", "1O", "11", "O1", "O1"],
	["bc", "cw", "bb", "wc", "cb"],
	["ab", "ba", "aa", "ab", "ba"],
]
# Ventana de la cinta de munición en las cajas laterales (filas 16 a 22)
const BELT_TOP: int = 16
const BELT_BOTTOM: int = 22

var _image: Image
var _heavy: bool = false
var _accent: PackedColorArray = ORANGE


func _initialize() -> void:
	var error: Error = OK
	for heavy: bool in [false, true]:
		_heavy = heavy
		_accent = RED if heavy else ORANGE
		var dir: String = "res://assets/sprites/turrets/%s/" % ("minigun_fusion" if heavy else "minigun")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var base: Image = _make_base()
		var cannons: Array[Image] = []
		for frame: int in CANNON_FRAMES:
			cannons.append(_make_cannon(frame))
		var icon: Image = base.duplicate()
		icon.blend_rect(cannons[0], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
		error = maxi(error, _save(base, dir + "minigun_base.png"))
		error = maxi(error, _save(_sheet(cannons), dir + "minigun_cannon_sheet.png"))
		error = maxi(error, _save(icon, dir + "minigun_full_up.png"))
		error = maxi(error, _save(_sheet(_make_frames(3, _draw_flash, EFFECT_SIZE)), dir + "minigun_flash_sheet.png"))
		error = maxi(error, _save(_sheet(_make_frames(2, _draw_bullet, 0)), dir + "minigun_bullet_sheet.png"))
		error = maxi(error, _save(_sheet(_make_frames(4, _draw_impact, EFFECT_SIZE)), dir + "minigun_impact_sheet.png"))
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


## Crea `count` frames de efecto llamando a `draw(frame)`. `size` 0 es la bala (4x8).
func _make_frames(count: int, draw: Callable, size: int) -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in count:
		_image = Image.create(4 if size == 0 else size, 8 if size == 0 else size, false, Image.FORMAT_RGBA8)
		draw.call(frame)
		frames.append(_image)
	return frames


# --- Base ---

func _make_base() -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		_paint_row(0, y, BASE[y])
	# Ranuras de ventilación a los lados del anillo
	for y: int in [13, 15, 17]:
		_paint_row(3, y, "22")
		_paint_row(26, y, "11")
	# Luces arriba y abajo
	_paint_row(15, 2, "ab")
	_paint_row(15, 29, "aa")
	if _heavy:
		_draw_heavy_base()
	return _image


## La pesada añade un aro discontinuo de acento alrededor del hueco y luces más grandes en las esquinas.
func _draw_heavy_base() -> void:
	var center: Vector2 = Vector2(15.5, 15.5)
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - center
			var distance: float = offset.length()
			if distance < 9.6 or distance >= 10.6 or _image.get_pixel(x, y).is_equal_approx(OUTLINE):
				continue
			# Ocho tramos con un hueco entre ellos
			var segment: float = fposmod(offset.angle() / TAU * 8.0 + 0.5, 1.0)
			if segment > 0.2:
				_put(x, y, _accent[1] if offset.x + offset.y < 0.0 else _accent[0])
	# Luces de las esquinas más grandes y brillantes
	for corner: Vector2i in [Vector2i(6, 6), Vector2i(25, 6), Vector2i(6, 25), Vector2i(25, 25)]:
		_paint_row(corner.x, corner.y, "cb")
		_paint_row(corner.x, corner.y + 1, "ba")


# --- Cañón ---

## Frame 0: reposo. 1 y 2: fire_0. 3 y 4: fire_1. El primer frame de cada disparo enciende las bocas,
## el segundo las apaga; los tubos alternan su sombreado y la cinta de munición avanza un paso.
func _make_cannon(frame: int) -> Image:
	_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var bore: int = [0, 1, 2, 1, 2][frame]
	var spin: int = [0, 1, 0, 1, 0][frame]
	var belt: int = [0, 1, 0, 1, 0][frame]
	var housing: Array[String] = HEAVY_HOUSING if _heavy else HOUSING
	var half_width: int = housing[0].length() / 2
	var housing_left: int = 16 - half_width
	var housing_right: int = 15 + half_width
	# Cajas de munición a los lados, con la cinta asomando por una ventana
	for side: int in [-1, 1]:
		var pod_x: int = housing_left - 3 if side < 0 else housing_right + 2
		for y: int in range(HOUSING_TOP + 1, HOUSING_TOP + housing.size() - 1):
			if y < BELT_TOP or y > BELT_BOTTOM:
				_paint_row(pod_x, y, "32" if side < 0 else "21")
			elif (y + belt) % 2 == 0:
				_paint_row(pod_x, y, "cb" if side < 0 else "bc")
			else:
				_paint_row(pod_x, y, "aO" if side < 0 else "Oa")
		if _heavy:
			# Remaches en las cajas
			_paint_row(pod_x, HOUSING_TOP + 2, "4O" if side < 0 else "O3")
			_paint_row(pod_x, HOUSING_TOP + housing.size() - 3, "4O" if side < 0 else "O3")
	# Carcasa con contorno propio
	_paint_row(housing_left - 1, HOUSING_TOP - 1, "O".repeat(housing[0].length() + 2))
	for i: int in housing.size():
		_paint_row(housing_left - 1, HOUSING_TOP + i, "O" + housing[i] + "O")
	_paint_row(housing_left - 1, HOUSING_TOP + housing.size(), "O".repeat(housing[0].length() + 2))
	# Tubos: filas de cañón, abrazaderas y bocas
	var top: int = 3 if _heavy else 4
	var rows: Array[String] = HEAVY_TUBE_ROWS if _heavy else TUBE_ROWS
	_draw_tube_row(top, BORES[bore])
	for i: int in rows.size():
		var y: int = top + 1 + i
		match rows[i]:
			"T":
				_draw_tube_row(y, TUBE_SHADES[spin])
			"C":
				_paint_row(9, y, "333333bb222211")
			"c":
				_paint_row(9, y, "222222aa111111")
			"R":
				_paint_row(9, y, "3cbbbbbbbbbba1")
			"r":
				_paint_row(9, y, "2aaaaaaaaaaaa1")
			"M":
				_paint_row(9, y, "33333333222211")
	_close_outline()
	return _image


## Una fila de los tubos y el eje con sus separadores; `shades` da los colores de cada tubo.
func _draw_tube_row(y: int, shades: Array) -> void:
	for x: int in TUBE_SEPARATORS:
		_put(x, y, OUTLINE)
	for tube: int in TUBES.size():
		_paint_row(TUBES[tube][0], y, shades[tube])


# --- Efectos (sin contorno) ---

## Fogonazo hacia arriba: grande, mediano y unas chispas.
func _draw_flash(frame: int) -> void:
	var length: int = [6, 4, 2][frame]
	var cx: int = 7
	for i: int in length:
		var y: int = 10 - i
		var color: Color = _accent[3] if i < length / 2 else _accent[2]
		_put(cx, y, color)
		_put(cx + 1, y, color)
		if i < length - 1 and frame < 2:
			_put(cx - 1, y, _accent[1])
			_put(cx + 2, y, _accent[1])
	if frame == 0:
		for pixel: Vector2i in [Vector2i(4, 9), Vector2i(11, 9), Vector2i(5, 7), Vector2i(10, 7)]:
			_put(pixel.x, pixel.y, _accent[1])
	elif frame == 2:
		for pixel: Vector2i in [Vector2i(5, 8), Vector2i(10, 8), Vector2i(7, 6)]:
			_put(pixel.x, pixel.y, Color(_accent[0], 0.7))


## Trazadora corta: punta clara arriba y cola que se apaga.
func _draw_bullet(frame: int) -> void:
	var tail: PackedColorArray = [_accent[3], _accent[2], _accent[1], _accent[1], _accent[0], Color(_accent[0], 0.5)]
	for i: int in tail.size():
		var y: int = 1 + i
		var color: Color = tail[i]
		if frame == 1 and i == 1:
			color = _accent[3]
		_put(1, y, color)
		_put(2, y, color if i < 2 else Color(color, color.a * 0.6))


## Impacto: chispazo central que se abre en un anillo de chispas.
func _draw_impact(frame: int) -> void:
	var center: Vector2 = Vector2(7.5, 7.5)
	if frame == 0:
		_fill_circle(center, 2.5, _accent[3])
		for pixel: Vector2i in [Vector2i(7, 3), Vector2i(8, 12), Vector2i(3, 8), Vector2i(12, 7)]:
			_put(pixel.x, pixel.y, _accent[2])
		return
	var radius: float = 2.0 + frame * 2.0
	var alpha: float = 1.0 - (frame - 1) * 0.3
	for i: int in 8:
		var angle: float = TAU * i / 8.0 + frame * 0.3
		var pixel: Vector2i = Vector2i((center + Vector2.from_angle(angle) * radius).round())
		_put(pixel.x, pixel.y, Color(_accent[1] if frame < 3 else _accent[0], alpha))
	if frame == 1:
		_fill_circle(center, 1.5, _accent[2])


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
			return _accent[0]
		"b":
			return _accent[1]
		"c":
			return _accent[2]
		"w":
			return _accent[3]
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
	for y: int in SIZE:
		for x: int in SIZE:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= SIZE or neighbor.y >= SIZE:
					continue
				var color: Color = source.get_pixel(neighbor.x, neighbor.y)
				if color.a > 0.0 and not color.is_equal_approx(OUTLINE):
					_image.set_pixel(x, y, OUTLINE)
					break
