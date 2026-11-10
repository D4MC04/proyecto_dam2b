extends SceneTree
## Genera los sprites del Cañón de asedio (assets/sprites/turrets/turret2_fusion/) y su animación de
## disparo (resources/sprite_frames/rocket_launcher_fusion_cannon.tres).
##
## Uso: godot --headless --path . -s scripts/tools/make_siege_cannon.gd
##
## - t2_base.png: la base que ya hay, con franjas de aviso en las vainas laterales y remaches claros.
## - t2_cannon_sheet.png: dos cañones con pistón hidráulico sobre una recámara común; cada cañón tiene
##   una ventana donde se ve su bala (3x8) y un cerrojo debajo. Un frame por cada estado distinto de
##   la salva: retroceso de cada cañón y bala de cada ventana entrando desde atrás.
## - t2_full_up.png: icono (base y cañón cargado).
## - t2_bullet_sheet.png: la misma bala tumbada (8x3) con halo naranja de 1 px (10x5).
## - t2_trail_sheet.png: llama de cola y brasas (3 frames de 12x5, en bucle).
## - t2_smoke_sheet.png: bocanada de humo gris (4 frames de 7x7, sin bucle).
##
## La animación fire_0 sigue el tiempo de la salva (TurretData.salvo_delay) y de la cadencia
## (attack_cooldown): si cambian en rocket_launcher_fusion.tres, cambiar aquí CADENCE y SALVO_DELAY.

const SIZE: int = 32
const DIR: String = "res://assets/sprites/turrets/turret2_fusion/"
const CANNON_FRAMES_PATH: String = "res://resources/sprite_frames/rocket_launcher_fusion_cannon.tres"
# uid de la animación y de su hoja (no cambian al regenerar)
const CANNON_FRAMES_UID: String = "uid://r6klw4o766eu"
const CANNON_SHEET_UID: String = "uid://detydsd1twi1l"

# Tiempos de la salva, en ticks de 0,01 s (la animación va a 100 fps)
const TICKS_PER_SECOND: int = 100
const CADENCE: int = 210
const SALVO_DELAY: int = 15
# Tras disparar, la ventana queda vacía un momento y luego entra la bala; acaba antes del disparo siguiente.
const RELOAD_DELAY: int = 12
const RELOAD_TIME: int = CADENCE - 45
# Retroceso: 3 px que se recuperan de 1 en 1 cada 0,06 s
const RECOIL: int = 3
const RECOIL_STEP: int = 6
# Recorrido de la bala al entrar en la ventana (empieza fuera, por debajo)
const SHELL_TRAVEL: int = 9

const PALETTE: Dictionary = {
	"A": Color("#0c0e16"), "B": Color("#343a4a"), "F": Color("#606a7c"), "C": Color("#96a2b6"),
	"D": Color("#8c2a14"), "E": Color("#dc461e"), "G": Color("#ffb464"), "H": Color("#ff8c32"),
	"Y": Color("#ffe28c"), "W": Color("#ffffff"),
	"K": Color("#ecb23c"), "L": Color("#96641e"), "M": Color("#ffe082"),
}
# Bala de 3x8 vista desde arriba: punta roja, banda oscura y vaina de latón.
const SHELL: Array[String] = [".E.", "EGE", "EED", "AAA", "KML", "KML", "KML", "LLL"]
# Ventana de cada cañón (x de su columna izquierda) y filas que ocupa
const WINDOW_X: Array[int] = [10, 19]
const WINDOW_TOP: int = 16
const WINDOW_BOTTOM: int = 23
const BOLT_Y: int = 24
const SMOKE_COLOR: Color = Color(0.47, 0.5, 0.57)
const HALO_ALPHA: float = 0.43


func _initialize() -> void:
	var error: Error = OK
	var base: Image = _make_base()
	error = maxi(error, _save(base, DIR + "t2_base.png"))
	var states: Array = _salvo_states()
	var images: Array[Image] = []
	var keys: Array = []
	for state: Array in states:
		if not keys.has(state[0]):
			keys.append(state[0])
			images.append(_make_cannon(state[0]))
	error = maxi(error, _save(_sheet(images), DIR + "t2_cannon_sheet.png"))
	error = maxi(error, _save_cannon_frames(states, keys))
	var icon: Image = base.duplicate()
	icon.blend_rect(images[0], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
	error = maxi(error, _save(icon, DIR + "t2_full_up.png"))
	error = maxi(error, _save(_make_bullet(), DIR + "t2_bullet_sheet.png"))
	error = maxi(error, _save(_sheet(_make_trail()), DIR + "t2_trail_sheet.png"))
	error = maxi(error, _save(_sheet(_make_smoke()), DIR + "t2_smoke_sheet.png"))
	quit(error)


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("No se pudo guardar %s" % path)
	return error


func _sheet(frames: Array[Image]) -> Image:
	var width: int = frames[0].get_width()
	var sheet: Image = Image.create(width * frames.size(), frames[0].get_height(), false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * width, 0))
	return sheet


func _px(image: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, PALETTE[key])


func _rect(image: Image, x0: int, y0: int, x1: int, y1: int, key: String) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			_px(image, x, y, key)


# Pieza con contorno y luz arriba a la izquierda, de metal o del acento rojo.
func _part(image: Image, x0: int, y0: int, x1: int, y1: int, accent: bool = false) -> void:
	var light: String = "G" if accent else "C"
	var mid: String = "E" if accent else "F"
	var dark: String = "D" if accent else "B"
	_rect(image, x0, y0, x1, y1, "A")
	_rect(image, x0 + 1, y0 + 1, x1 - 1, y1 - 1, mid)
	_rect(image, x0 + 1, y0 + 1, x1 - 1, y0 + 1, light)
	_rect(image, x0 + 1, y0 + 1, x0 + 1, y1 - 1, light)
	_rect(image, x1 - 1, y0 + 2, x1 - 1, y1 - 1, dark)
	_rect(image, x0 + 2, y1 - 1, x1 - 1, y1 - 1, dark)


func _make_base() -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(DIR + "t2_base.png"))
	image.convert(Image.FORMAT_RGBA8)
	# Franjas de aviso en diagonal, rojo y casi negro, en las dos vainas.
	for x0: int in [2, 26]:
		for y: int in range(10, 22):
			for x: int in range(x0, x0 + 4):
				_px(image, x, y, "E" if (x + y) % 4 < 2 else "A")
	for pos: Vector2i in [Vector2i(10, 2), Vector2i(21, 2), Vector2i(10, 29), Vector2i(21, 29),
			Vector2i(2, 9), Vector2i(29, 9), Vector2i(2, 22), Vector2i(29, 22)]:
		_px(image, pos.x, pos.y, "C")
	return image


# Estado del cañón: [retroceso izq., retroceso der., bajada de la bala izq., der., cerrojo izq., der.].
func _make_cannon(state: Array) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# Cilindros fijos de los pistones
	_part(image, 3, 14, 7, 24)
	_part(image, 24, 14, 28, 24)
	# Cada cañón retrocede con su vástago y su brazo
	var r: int = state[0]
	_part(image, 4, 8 + r, 6, 15 + r)
	_part(image, 4, 7 + r, 10, 10 + r)
	_part(image, 9, 2 + r, 14, 17 + r)
	_part(image, 8, r, 15, 3 + r, true)
	r = state[1]
	_part(image, 25, 8 + r, 27, 15 + r)
	_part(image, 21, 7 + r, 27, 10 + r)
	_part(image, 17, 2 + r, 22, 17 + r)
	_part(image, 16, r, 23, 3 + r, true)
	# Recámara común
	_part(image, 8, 15, 23, 26)
	_rect(image, 15, 16, 16, 25, "A")
	for side: int in 2:
		var sx: int = WINDOW_X[side]
		_rect(image, sx - 1, 15, sx + 3, 25, "A")
		var top: int = WINDOW_TOP + state[2 + side]
		for j: int in SHELL.size():
			for i: int in 3:
				var key: String = SHELL[j][i]
				if key != "." and top + j <= WINDOW_BOTTOM:
					_px(image, sx + i, top + j, key)
		# Cerrojo: se cierra cuando la bala está dentro.
		_rect(image, sx, BOLT_Y, sx + 2, BOLT_Y, "C" if state[4 + side] else "B")
	return image


func _smooth(q: float) -> float:
	q = clampf(q, 0.0, 1.0)
	return q * q * (3.0 - 2.0 * q)


# Estados de la salva tick a tick, agrupados: [[estado, ticks], ...]. El primero es el disparo del cañón
# izquierdo y el último el cañón cargado del todo (igual que el reposo).
func _salvo_states() -> Array:
	var states: Array = []
	var end: int = SALVO_DELAY + RELOAD_DELAY + RELOAD_TIME
	for tick: int in range(end + 1):
		var state: Array = [0, 0, 0, 0, true, true]
		for side: int in 2:
			var since: int = tick - side * SALVO_DELAY
			if since < 0:
				continue
			state[side] = maxi(0, RECOIL - since / RECOIL_STEP)
			var progress: float = clampf(float(since - RELOAD_DELAY) / RELOAD_TIME, 0.0, 1.0)
			state[2 + side] = roundi((1.0 - _smooth(progress)) * SHELL_TRAVEL)
			state[4 + side] = progress >= 1.0
		if not states.is_empty() and states[-1][0] == state:
			states[-1][1] += 1
		else:
			states.append([state, 1])
	# El reposo es el último estado: que sea el frame 0 de la hoja.
	var rest: Array = states[-1][0]
	states.push_front([rest, 0])
	return states


# Escribe la animación: default (reposo) y fire_0 con la salva (cada frame dura lo que dura su estado).
func _save_cannon_frames(states: Array, keys: Array) -> Error:
	var text: String = '[gd_resource type="SpriteFrames" format=3 uid="%s"]\n\n' % CANNON_FRAMES_UID
	text += '[ext_resource type="Texture2D" uid="%s" path="%st2_cannon_sheet.png" id="1"]\n\n' % [CANNON_SHEET_UID, DIR]
	for i: int in keys.size():
		text += '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("1")\n' % i
		text += "region = Rect2(%d, 0, %d, %d)\n\n" % [i * SIZE, SIZE, SIZE]
	var fire: PackedStringArray = []
	for state: Array in states.slice(1):
		fire.append('{\n"duration": %d.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % [state[1], keys.find(state[0])])
	text += "[resource]\nanimations = [{\n"
	text += '"frames": [{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_0")\n}],\n'
	text += '"loop": false,\n"name": &"default",\n"speed": 5.0\n}, {\n'
	text += '"frames": [%s],\n' % ", ".join(fire)
	text += '"loop": false,\n"name": &"fire_0",\n"speed": %d.0\n}]\n' % TICKS_PER_SECOND
	var file: FileAccess = FileAccess.open(CANNON_FRAMES_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar %s" % CANNON_FRAMES_PATH)
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK


# La bala de la recámara tumbada (punta a la derecha) con halo naranja de 1 px alrededor.
func _make_bullet() -> Image:
	var image: Image = Image.create(10, 5, false, Image.FORMAT_RGBA8)
	var halo: Color = PALETTE["H"]
	halo.a = HALO_ALPHA
	for j: int in SHELL.size():
		for i: int in 3:
			if SHELL[j][i] == ".":
				continue
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var x: int = 8 - j + dx
					var y: int = 1 + i + dy
					if image.get_pixel(x, y).a == 0.0:
						image.set_pixel(x, y, halo)
	for j: int in SHELL.size():
		for i: int in 3:
			if SHELL[j][i] != ".":
				image.set_pixel(8 - j, 1 + i, PALETTE[SHELL[j][i]])
	return image


# Llama de cola (a la derecha, pegada a la bala) que parpadea y brasas de amarillo a rojo oscuro.
func _make_trail() -> Array[Image]:
	var embers: Array[String] = ["Y", "H", "H", "E", "E", "D", "D", "D"]
	var frames: Array[Image] = []
	for f: int in 3:
		var image: Image = Image.create(12, 5, false, Image.FORMAT_RGBA8)
		for k: int in embers.size():
			var color: Color = PALETTE[embers[k]]
			color.a = 0.9 * (1.0 - float(k) / embers.size())
			var x: int = 9 - k
			image.set_pixel(x, 2, color)
			# Chispas sueltas que saltan arriba o abajo según el frame
			if (k + f) % 3 == 0 and k > 1:
				image.set_pixel(x - 1, 1 if (k + f) % 2 else 3, color)
		var flame: Color = PALETTE["H"]
		flame.a = 0.8
		var big: bool = f != 1
		for y: int in range(1 if big else 2, 4 if big else 3):
			for x: int in range(9 if big else 10, 12):
				image.set_pixel(x, y, flame)
		image.set_pixel(11, 2, PALETTE["W"])
		image.set_pixel(10, 2, PALETTE["Y"])
		frames.append(image)
	return frames


# Bocanada de humo que crece y se desvanece.
func _make_smoke() -> Array[Image]:
	var frames: Array[Image] = []
	for f: int in 4:
		var image: Image = Image.create(7, 7, false, Image.FORMAT_RGBA8)
		var radius: float = 1.2 + f * 0.6
		var color: Color = SMOKE_COLOR
		color.a = 0.6 * (1.0 - f / 4.0)
		for y: int in 7:
			for x: int in 7:
				if Vector2(x - 3, y - 3).length() <= radius:
					image.set_pixel(x, y, color)
		frames.append(image)
	return frames
