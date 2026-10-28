extends SceneTree
## Genera los sprites del Orbitador y del Cinturón (su fusión) en assets/sprites/turrets/orbiter/ y
## assets/sprites/turrets/orbiter_fusion/.
##
## Uso: godot --headless --path . -s scripts/tools/make_orbiter.gd
##
## Por carpeta: orbiter_base.png (32x32), orbiter_cannon_idle_sheet.png (4 frames de 32x32, en bucle:
## el remolino de plasma gira), orbiter_cannon_fire_sheet.png (6 frames de 32x32: el núcleo crece,
## destella en el frame 3, cuando sale la carga, y vuelve), orbiter_bullet_sheet.png (4 frames de 10x10,
## en bucle: la bola de plasma que orbita), orbiter_impact_sheet.png (6 frames de 24x24: la bola se abre
## en un anillo que se deshace en chispas) y orbiter_full_up.png (icono con el núcleo encendido).
##
## La base es la plantilla del Cañón doble con las luces en violeta. El emisor no gira: aro de metal
## con abrazaderas que tienen una luz en la punta y una esfera de contención oscura con un remolino de
## plasma y un núcleo claro. El Cinturón añade a la base un aro discontinuo violeta y luces más grandes
## en las esquinas; su emisor es más grande, con cuatro abrazaderas en vez de tres, tres brazos de
## remolino en vez de dos y el núcleo blanco (también en la carga), para no confundirse con la Tormenta.
## Caracteres de la plantilla: "." vacío, "O" contorno, "1" a "4" metal de sombra a luz y "a" a "c"
## violeta de oscuro a claro.

const SIZE: int = 32
const ORB_SIZE: int = 10
const IMPACT_SIZE: int = 24
const IDLE_FRAMES: int = 4
const FIRE_FRAMES: int = 6
const IMPACT_FRAMES: int = 6

const OUTLINE: Color = Color("#0c0e16")
# Metal gris azulado de las torretas, de sombra a luz (ver docs/design/art.md)
const METAL: PackedColorArray = [Color("#343a4a"), Color("#606a7c"), Color("#96a2b6"), Color("#d2dceb")]
# Acento del Orbitador: violeta de oscuro a claro y casi blanco
const VIOLET: PackedColorArray = [Color("#3c2a8a"), Color("#7a5ae6"), Color("#c0aaff"), Color("#f4f0ff")]
# Cristal oscuro de la esfera de contención
const GLASS: Color = Color("#1a1430")
const WHITE: Color = Color("#ffffff")

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

const CENTER: Vector2 = Vector2(15.5, 15.5)
# Radio del núcleo en cada frame de generar: crece, destella (frame 3) y vuelve al reposo.
const FIRE_CORE: Array[float] = [2.2, 3.0, 3.8, 1.2, 1.2, 1.6]
const FLASH_FRAME: int = 3

var _image: Image
var _major: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	var error: Error = OK
	for major: bool in [false, true]:
		_major = major
		var dir: String = "res://assets/sprites/turrets/%s/" % ("orbiter_fusion" if major else "orbiter")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var base: Image = _make_base()
		var idle: Array[Image] = []
		for frame: int in IDLE_FRAMES:
			idle.append(_make_emitter(frame, -1))
		var fire: Array[Image] = []
		for frame: int in FIRE_FRAMES:
			fire.append(_make_emitter(0, frame))
		var orbs: Array[Image] = []
		for frame: int in IDLE_FRAMES:
			orbs.append(_make_orb(frame))
		var impacts: Array[Image] = []
		for frame: int in IMPACT_FRAMES:
			impacts.append(_make_impact(frame))
		var icon: Image = base.duplicate()
		# El icono enseña el núcleo cargado.
		icon.blend_rect(fire[2], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
		error = maxi(error, _save(base, dir + "orbiter_base.png"))
		error = maxi(error, _save(_sheet(idle), dir + "orbiter_cannon_idle_sheet.png"))
		error = maxi(error, _save(_sheet(fire), dir + "orbiter_cannon_fire_sheet.png"))
		error = maxi(error, _save(_sheet(orbs), dir + "orbiter_bullet_sheet.png"))
		error = maxi(error, _save(_sheet(impacts), dir + "orbiter_impact_sheet.png"))
		error = maxi(error, _save(icon, dir + "orbiter_full_up.png"))
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


func _new_image(size: int) -> void:
	_image = Image.create(size, size, false, Image.FORMAT_RGBA8)


# --- Base ---

func _make_base() -> Image:
	_new_image(SIZE)
	for y: int in SIZE:
		_paint_row(0, y, BASE[y])
	# Luces arriba y abajo
	_paint_row(15, 2, "ab")
	_paint_row(15, 29, "aa")
	if _major:
		_draw_major_ring()
	return _image


## El Cinturón añade un aro discontinuo violeta alrededor del hueco y luces más grandes en las esquinas.
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
				_put(x, y, VIOLET[1] if offset.x + offset.y < 0.0 else VIOLET[0])
	for corner: Vector2i in [Vector2i(6, 6), Vector2i(25, 6), Vector2i(6, 25), Vector2i(25, 25)]:
		_paint_row(corner.x, corner.y, "cb")
		_paint_row(corner.x, corner.y + 1, "ba")


# --- Emisor ---

## Un frame del emisor. Con fire_frame -1 es el reposo (idle_frame, en bucle); si no, el frame de la
## animación de generar una carga.
func _make_emitter(idle_frame: int, fire_frame: int) -> Image:
	_new_image(SIZE)
	var ring_radius: float = 10.6 if _major else 10.0
	var glass_radius: float = ring_radius - 3.0
	var arms: int = 3 if _major else 2
	var core_radius: float = 2.2 if _major else 1.6
	var flash: bool = fire_frame == FLASH_FRAME
	var spin: float = idle_frame * TAU / IDLE_FRAMES
	if fire_frame >= 0:
		core_radius = FIRE_CORE[fire_frame] + (0.6 if _major else 0.0)
		spin = fire_frame * TAU / IDLE_FRAMES
	for y: int in SIZE:
		for x: int in SIZE:
			var offset: Vector2 = Vector2(x, y) - CENTER
			var distance: float = offset.length()
			if distance >= ring_radius:
				continue
			if distance >= ring_radius - 2.0:
				# Aro de metal: banda de fuera más clara, luz arriba a la izquierda
				_put(x, y, _metal_lit(_light(offset), distance >= ring_radius - 1.0))
			elif distance >= glass_radius:
				# Junta oscura entre el aro y la esfera
				_put(x, y, OUTLINE)
			else:
				_put(x, y, _plasma_color(offset, distance, arms, spin, flash))
	_draw_core(core_radius, fire_frame)
	# Brillo del cristal arriba a la izquierda
	_put(12, 11, METAL[3])
	_put(11, 12, METAL[2])
	_draw_clamps(ring_radius, idle_frame, fire_frame)
	_close_outline()
	return _image


## 1 de cara a la luz (arriba a la izquierda), -1 en sombra.
func _light(offset: Vector2) -> float:
	return -(offset.x + offset.y) / maxf(offset.length(), 0.001) / sqrt(2.0)


func _metal_lit(light: float, outer: bool) -> Color:
	var level: int = 2 if light > 0.45 else (1 if light > -0.35 else 0)
	return METAL[mini(level + (1 if outer else 0), 3)]


## Esfera de contención: cristal oscuro con brazos de remolino (el ángulo avanza con la distancia) que
## giran con spin. En el destello la esfera entera se ilumina.
func _plasma_color(offset: Vector2, distance: float, arms: int, spin: float, flash: bool) -> Color:
	if flash and distance < 6.0:
		return VIOLET[2] if distance > 3.0 else VIOLET[3]
	var arm: float = fposmod(offset.angle() - distance * 0.55 - spin, TAU / arms)
	if arm < 0.55 and distance > 2.0:
		return VIOLET[1] if distance < 5.0 else VIOLET[0]
	return GLASS


## Núcleo de plasma: borde claro y centro casi blanco (blanco puro en el Cinturón).
func _draw_core(radius: float, fire_frame: int) -> void:
	_fill_circle(CENTER, radius, VIOLET[2])
	var center_color: Color = WHITE if _major and fire_frame >= 0 else VIOLET[3]
	_fill_circle(CENTER, maxf(radius - 1.2, 0.5), center_color)


## Abrazaderas de metal (tres, o cuatro en el Cinturón) con una luz violeta en la punta, que en reposo
## parpadea y al generar se enciende mientras se carga y destella.
func _draw_clamps(ring_radius: float, idle_frame: int, fire_frame: int) -> void:
	var count: int = 4 if _major else 3
	var lit: bool = (fire_frame >= 2 and fire_frame <= FLASH_FRAME) or (fire_frame < 0 and idle_frame % 2 == 0)
	for i: int in count:
		var direction: Vector2 = Vector2.from_angle(-PI / 2.0 + i * TAU / count)
		for step: float in [ring_radius - 1.0, ring_radius, ring_radius + 1.0]:
			_fill_circle(CENTER + direction * step, 1.1, METAL[2] if direction.x + direction.y < 0.0 else METAL[1])
		_fill_circle(CENTER + direction * (ring_radius + 1.6), 0.7, VIOLET[2] if lit else VIOLET[0])


# --- Carga en órbita ---

## Bola de plasma sin contorno: halo transparente, bola violeta y un brillo que da vueltas. La del
## Cinturón tiene el centro blanco.
func _make_orb(frame: int) -> Image:
	_new_image(ORB_SIZE)
	var center: Vector2 = Vector2(4.5, 4.5)
	var halo: Color = VIOLET[1]
	halo.a = 0.45
	_fill_circle(center, 4.0, halo)
	_fill_circle(center, 3.0, VIOLET[1])
	_fill_circle(center, 2.0, VIOLET[2])
	var shine: Vector2 = center + Vector2.from_angle(-PI * 0.75 + frame * TAU / IDLE_FRAMES) * 1.2
	_put(roundi(shine.x), roundi(shine.y), VIOLET[3])
	_put(4, 4, VIOLET[3])
	if _major:
		_fill_circle(center, 1.0, WHITE)
	return _image


# --- Impacto ---

## Destello, bola que se abre en un anillo violeta (doble en el Cinturón) y se deshace en chispas.
func _make_impact(frame: int) -> Image:
	_new_image(IMPACT_SIZE)
	_rng.seed = 11 + frame
	var center: Vector2 = Vector2(11.5, 11.5)
	var core: Color = WHITE if _major else VIOLET[3]
	match frame:
		0:
			_fill_circle(center, 4.0, VIOLET[2])
			_fill_circle(center, 2.6, core)
		1:
			_fill_circle(center, 6.5, VIOLET[1])
			_fill_circle(center, 5.0, VIOLET[2])
			_fill_circle(center, 2.5, core)
		2:
			_ring(center, 8.5, 2.0, VIOLET[2], 1.0)
			_ring(center, 6.5, 1.0, VIOLET[1], 1.0)
			_fill_circle(center, 2.0, VIOLET[2])
			if _major:
				_ring(center, 4.5, 1.0, core, 1.0)
		3:
			_ring(center, 10.0, 1.0, VIOLET[2], 1.0)
			_ring(center, 8.5, 1.0, VIOLET[1], 0.8)
			if _major:
				_ring(center, 6.0, 1.0, VIOLET[2], 0.8)
		4:
			_ring(center, 11.0, 1.0, VIOLET[1], 0.7, 0.5)
		5:
			_ring(center, 11.5, 1.0, VIOLET[0], 0.6, 0.25)
	if frame >= 2:
		for i: int in 8 - frame:
			var spark: Vector2 = center + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(3.0, 10.0)
			_put(roundi(spark.x), roundi(spark.y), VIOLET[2])
	return _image


## Anillo de grosor width por dentro de radius. Con density < 1 sale punteado.
func _ring(center: Vector2, radius: float, width: float, color: Color, alpha: float, density: float = 1.0) -> void:
	var tinted: Color = color
	tinted.a = alpha
	var size: int = _image.get_width()
	for y: int in size:
		for x: int in size:
			var distance: float = (Vector2(x, y) - center).length()
			if distance < radius - width or distance >= radius:
				continue
			if density < 1.0 and _rng.randf() > density:
				continue
			_put(x, y, tinted)


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
			return VIOLET[0]
		"b":
			return VIOLET[1]
		"c":
			return VIOLET[2]
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
