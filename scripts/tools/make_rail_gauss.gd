extends SceneTree
## Genera los sprites de la Rail Gauss (assets/sprites/turrets/rail_fusion/) y su animación de cañón
## (resources/sprite_frames/rail_fusion_cannon.tres).
##
## Uso: godot --headless --path . -s scripts/tools/make_rail_gauss.gd
##
## - rail_base.png: la base de antes sin los dos cuadrados de las esquinas delanteras, con el borde del
##   octógono cerrado como en la base del Cañón doble.
## - rail_cannon_*_sheet.png: riel doble blindado (dos rieles gruesos con placas de blindaje y un canal
##   ancho entre ellos) con dos condensadores detrás, cada uno con un medidor de 4 celdas.
##   idle (4 frames): las celdas parpadean en cian una tras otra. charge (8): el canal pasa de apagado a
##   dorado y las celdas se encienden de 1 a 4. fire (1): canal blanco-dorado, celdas vacías y 1 px de
##   retroceso. recover (2): canal naranja y luego marrón.
## - rail_full_up.png: icono (base y cañón en reposo).
##
## fire_0 va a 10 fps: la carga dura 1,6 s (8 frames de 0,2 s) para que el disparo caiga en el frame 8
## (BeamData.fire_frame de resources/beam_data/rail_fusion.tres). Si cambia, cambiar aquí CHARGE_FRAMES.

const SIZE: int = 32
const HALF: int = 16
const DIR: String = "res://assets/sprites/turrets/rail_fusion/"
const CANNON_FRAMES_PATH: String = "res://resources/sprite_frames/rail_fusion_cannon.tres"
# uid de la animación y de sus hojas (no cambian al regenerar)
const CANNON_FRAMES_UID: String = "uid://ufviqe64sn3b"
const SHEET_UIDS: Dictionary = {
	"idle": "uid://cv6ah2jn6ebol", "charge": "uid://dmkcbvagip5kb",
	"fire": "uid://cjjthbbhsmmx8", "recover": "uid://cfn4furfd87w6",
}

# Tiempos de fire_0, en ticks de 0,1 s
const TICKS_PER_SECOND: int = 10
const CHARGE_FRAMES: int = 8
const CHARGE_TICKS: int = 2
const FIRE_TICKS: int = 3
const HOT_TICKS: int = 5
const WARM_TICKS: int = 5
const IDLE_SPEED: float = 6.7

# Mitad izquierda del cañón (columnas 0-15); la derecha es su reflejo con la luz cambiada.
# O contorno, 1-4 metal de sombra a luz, c cian apagado, g canal, h punta del canal,
# p q r s celdas de los condensadores (de abajo arriba).
const TWIN_RAIL: Array[String] = [
	"................",
	".........OOOOO..",
	".........O433O..",
	".........O433Ohh",
	".........O433Ogg",
	"........OO433Ogg",
	".......O4O4p3Ogg",
	".......O3O433Ogg",
	".......O2O433Ogg",
	"........OO433Ogg",
	".........O433Ogg",
	"........OO433Ogg",
	".......O4O4q3Ogg",
	".......O3O433Ogg",
	".......O2O433Ogg",
	"........OO433Ogg",
	"....OOOOOO433Ogg",
	"...O4444O43333Og",
	"...O3cc3O4OOOOOO",
	"...O3ss3O3333333",
	"...O3rr3O3OcOcO3",
	"...O3qq3O3222222",
	"...O3pp3O3OOOOOO",
	"...O2222O3211111",
	"...O1111O3222222",
	"....OOOOO3111111",
	".........OOOOOOO",
]
# Al reflejar, la luz viene de la izquierda: el lado derecho es un tono más oscuro.
const MIRROR: Dictionary = {"4": "3", "3": "2"}
const CELLS: String = "pqrs"

const OUTLINE: Color = Color8(12, 14, 22)
const METAL: Dictionary = {
	"1": Color8(52, 58, 74), "2": Color8(96, 106, 124), "3": Color8(150, 162, 182), "4": Color8(210, 220, 235),
}
const CYAN_OFF: Color = Color8(28, 116, 150)
const CYAN_ON: Color = Color8(64, 224, 240)
const CYAN_FLASH: Color = Color8(190, 250, 255)
# Brillo del canal: 0 apagado, 1-4 carga, 5 disparo (blanco-dorado)
const GOLD: Array[Color] = [
	Color8(52, 58, 74), Color8(150, 100, 30), Color8(236, 178, 60), Color8(255, 224, 130),
	Color8(255, 248, 230), Color8(250, 252, 255),
]
const HOT: Color = Color8(255, 140, 50)
const WARM: Color = Color8(140, 70, 40)
const NO_HEAT: Color = Color(0, 0, 0, 0)


func _initialize() -> void:
	var error: Error = OK
	var base: Image = _make_base()
	error = maxi(error, _save(base, DIR + "rail_base.png"))
	var idle: Array[Image] = []
	for light: int in 4:
		idle.append(_make_cannon(0, 0, NO_HEAT, light, 0))
	# Carga: canal 0 → 4 y celdas 1 → 4, un paso cada 0,4 s.
	var charge: Array[Image] = []
	for k: int in CHARGE_FRAMES:
		charge.append(_make_cannon(floori((k + 1) / 2.0), floori(k / 2.0) + 1, NO_HEAT, -1, 0))
	var fire: Array[Image] = [_make_cannon(5, 0, NO_HEAT, -1, 1)]
	var recover: Array[Image] = [_make_cannon(0, 0, HOT, -1, 0), _make_cannon(0, 0, WARM, -1, 0)]
	error = maxi(error, _save(_sheet(idle), DIR + "rail_cannon_idle_sheet.png"))
	error = maxi(error, _save(_sheet(charge), DIR + "rail_cannon_charge_sheet.png"))
	error = maxi(error, _save(_sheet(fire), DIR + "rail_cannon_fire_sheet.png"))
	error = maxi(error, _save(_sheet(recover), DIR + "rail_cannon_recover_sheet.png"))
	error = maxi(error, _save_cannon_frames(charge.size(), recover.size()))
	var icon: Image = base.duplicate()
	icon.blend_rect(idle[0], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
	error = maxi(error, _save(icon, DIR + "rail_full_up.png"))
	quit(error)


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("No se pudo guardar %s" % path)
	return error


func _sheet(frames: Array[Image]) -> Image:
	var sheet: Image = Image.create(SIZE * frames.size(), SIZE, false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, SIZE, SIZE), Vector2i(i * SIZE, 0))
	return sheet


# La base de antes sin los cuadrados de las esquinas delanteras (filas y columnas 3-6 y 25-28).
func _make_base() -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(DIR + "rail_base.png"))
	image.convert(Image.FORMAT_RGBA8)
	for y: int in range(3, 7):
		for x: int in range(3, 7):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
			image.set_pixel(SIZE - 1 - x, y, Color(0, 0, 0, 0))
	# Cierra el borde del octógono donde estaban.
	image.set_pixel(6, 5, OUTLINE)
	image.set_pixel(25, 5, OUTLINE)
	image.set_pixel(5, 6, OUTLINE)
	image.set_pixel(26, 6, OUTLINE)
	image.set_pixel(6, 6, METAL["3"])
	image.set_pixel(25, 6, METAL["2"])
	return image


# Fila completa (32 px) de la plantilla: la mitad izquierda y su reflejo.
func _row(y: int) -> String:
	var left: String = TWIN_RAIL[y] if y < TWIN_RAIL.size() else ".".repeat(HALF)
	var right: String = ""
	for x: int in range(HALF - 1, -1, -1):
		right += MIRROR.get(left[x], left[x])
	return left + right


# level: brillo del canal (0-5); meters: celdas encendidas (0-4); heat: color del canal al enfriarse;
# light: celda que destella en reposo (-1 ninguna); recoil: píxeles que retrocede el cañón.
func _make_cannon(level: int, meters: int, heat: Color, light: int, recoil: int) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		var row: String = _row(y)
		for x: int in SIZE:
			var key: String = row[x]
			if key == "." or y + recoil >= SIZE:
				continue
			var color: Color
			if key == "O":
				color = OUTLINE
			elif METAL.has(key):
				color = METAL[key]
			elif key == "c":
				color = CYAN_OFF
			elif key == "g":
				color = heat if heat.a > 0.0 else GOLD[level]
			elif key == "h":
				if heat.a > 0.0:
					color = heat
				else:
					color = GOLD[mini(level + 1, 5)] if level > 0 else CYAN_ON
			else:
				var cell: int = CELLS.find(key)
				if meters > cell:
					color = GOLD[3]
				else:
					color = CYAN_FLASH if light == cell else CYAN_OFF
			image.set_pixel(x, y + recoil, color)
	return image


func _atlas(id: int, sheet: String, frame: int) -> String:
	var text: String = '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("%s")\n' % [id, sheet]
	return text + "region = Rect2(%d, 0, %d, %d)\n\n" % [frame * SIZE, SIZE, SIZE]


func _frame(id: int, duration: int) -> String:
	return '{\n"duration": %d.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % [duration, id]


# default: 4 frames de reposo en bucle. fire_0: carga, disparo, naranja y marrón (vuelve a default al acabar).
func _save_cannon_frames(charge_count: int, recover_count: int) -> Error:
	var text: String = '[gd_resource type="SpriteFrames" format=3 uid="%s"]\n\n' % CANNON_FRAMES_UID
	var names: Array[String] = ["idle", "charge", "fire", "recover"]
	var counts: Array[int] = [4, charge_count, 1, recover_count]
	for i: int in names.size():
		text += '[ext_resource type="Texture2D" uid="%s" path="%srail_cannon_%s_sheet.png" id="%d"]\n' % [
			SHEET_UIDS[names[i]], DIR, names[i], i + 1]
	text += "\n"
	var id: int = 0
	var idle: PackedStringArray = []
	var fire: PackedStringArray = []
	for i: int in names.size():
		for frame: int in counts[i]:
			text += _atlas(id, str(i + 1), frame)
			match names[i]:
				"idle":
					idle.append(_frame(id, 1))
				"charge":
					fire.append(_frame(id, CHARGE_TICKS))
				"fire":
					fire.append(_frame(id, FIRE_TICKS))
				"recover":
					fire.append(_frame(id, HOT_TICKS if frame == 0 else WARM_TICKS))
			id += 1
	text += "[resource]\nanimations = [{\n"
	text += '"frames": [%s],\n' % ", ".join(idle)
	text += '"loop": true,\n"name": &"default",\n"speed": %s\n}, {\n' % IDLE_SPEED
	text += '"frames": [%s],\n' % ", ".join(fire)
	text += '"loop": false,\n"name": &"fire_0",\n"speed": %d.0\n}]\n' % TICKS_PER_SECOND
	var file: FileAccess = FileAccess.open(CANNON_FRAMES_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar %s" % CANNON_FRAMES_PATH)
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK
