extends SceneTree
## Genera los sprites de la Cryo ventisca (assets/sprites/turrets/cryo_fusion/), diseño "Vórtice", y su
## animación de cañón (resources/sprite_frames/cryo_fusion_cannon.tres).
##
## Uso: godot --headless --path . -s scripts/tools/make_cryo_vortex.gd
##
## - cryo_base.png: la base de la Cryo con sus luces azules en blanco y #a6defa.
## - Cañón: núcleo de cristal, banda de hielo que se aclara con la recarga, aro de metal con 8 ranuras y
##   4 rodillos encima, remolino dentro del cristal y 14 copos que entran en espiral. El aro gira (solo
##   aspecto): a tope en reposo, en la carga y en el pulso; 200°/s en el enfriado; en la recarga sube
##   de 40°/s a 460°/s (p²). La figura se repite cada 90°: 12 frames de ángulo.
##   - cryo_cannon_idle_sheet.png: default (cargada, a tope, en bucle).
##   - cryo_cannon_charge_sheet.png, _pulse_sheet.png, _cool_sheet.png (enfriado y recarga): fire_0.
## - cryo_full_up.png: icono (base y cañón cargado).
## - cryo_wave_sheet.png: onda de 8 frames con frente blanco, eco y 6 brazos de ventisca en espiral.
##
## fire_0 va a 100 fps, cada frame dura lo que dura su estado y acaba a 1,95 s, antes del pulso
## siguiente (attack_cooldown 2,0). El frame del pulso se escribe en resources/pulse_data/cryo_fusion.tres.

const SIZE: int = 32
const WAVE_SIZE: int = 128
const WAVE_FRAMES: int = 8
const DIR: String = "res://assets/sprites/turrets/cryo_fusion/"
const BASE_SOURCE: String = "res://assets/sprites/turrets/cryo/cryo_base.png"
const CANNON_FRAMES_PATH: String = "res://resources/sprite_frames/cryo_fusion_cannon.tres"
const PULSE_DATA_PATH: String = "res://resources/pulse_data/cryo_fusion.tres"
# uid de la animación y de sus hojas (no cambian al regenerar)
const CANNON_FRAMES_UID: String = "uid://ctpduh3evf5hq"
const SHEETS: Array[String] = ["idle", "charge", "pulse", "cool"]
const SHEET_UIDS: Array[String] = ["uid://e35yx6t1hxr5", "uid://n5pbff0lujum", "uid://bslldr3ckfh4e", "uid://b16q3yg2grfpn"]

# Tiempos del ciclo, en ticks de 0,01 s
const TICKS_PER_SECOND: int = 100
const CHARGE_END: int = 21
const PULSE_END: int = 36
const COOL_END: int = 50
const CYCLE_END: int = 195
# Velocidades del aro (°/s)
const SPIN_FULL: float = 560.0
const SPIN_COOL: float = 200.0
const SPIN_RELOAD_MIN: float = 40.0
const SPIN_RELOAD_GAIN: float = 420.0
const ANGLE_STEP: float = 7.5
const ANGLE_FRAMES: int = 12
const SNOW_COUNT: int = 14

const O: Color = Color("#0c0e16")
const M0: Color = Color("#232838")
const M1: Color = Color("#3c465c")
const M2: Color = Color("#6c7a94")
const M3: Color = Color("#b4c2da")
const I0: Color = Color("#122248")
const I1: Color = Color("#245296")
const I2: Color = Color("#54a0e2")
const I3: Color = Color("#a6defa")
const I4: Color = Color("#ecfaff")
const W: Color = Color("#ffffff")
const BAND_COLORS: Array[Color] = [I1, I2, I3, I4, W]
# Rampas del núcleo según el momento del ciclo
const CORE_RAMPS: Dictionary = {
	"normal": [I1, I2, I3, I4],
	"bright": [I2, I3, I4, W],
	"flash": [I3, I4, W, W],
	"dark": [I0, I1, I1, I2],
}


func _initialize() -> void:
	var error: Error = OK
	var base: Image = _make_base()
	error = maxi(error, _save(base, DIR + "cryo_base.png"))
	# Estados tick a tick de fire_0, agrupados: [[clave, ticks], ...]. Clave: [hoja, ángulo, núcleo, banda, luz].
	var states: Array = _cycle_states()
	var keys_by_sheet: Array = [[], [], [], []]
	for i: int in ANGLE_FRAMES:
		keys_by_sheet[0].append([0, i, "normal", 3, true])
	for state: Array in states:
		var key: Array = state[0]
		if not keys_by_sheet[key[0]].has(key):
			keys_by_sheet[key[0]].append(key)
	for s: int in SHEETS.size():
		var images: Array[Image] = []
		for key: Array in keys_by_sheet[s]:
			images.append(_make_cannon(key))
		error = maxi(error, _save(_sheet(images), DIR + "cryo_cannon_%s_sheet.png" % SHEETS[s]))
		if s == 0:
			var icon: Image = base.duplicate()
			icon.blend_rect(images[0], Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
			error = maxi(error, _save(icon, DIR + "cryo_full_up.png"))
	var fire_frame: int = 0
	var tick: int = 0
	for i: int in states.size():
		if tick == CHARGE_END:
			fire_frame = i
		tick += states[i][1]
	error = maxi(error, _save_cannon_frames(states, keys_by_sheet))
	error = maxi(error, _save_fire_frame(fire_frame))
	var waves: Array[Image] = []
	for f: int in WAVE_FRAMES:
		waves.append(_make_wave(f))
	error = maxi(error, _save(_sheet(waves), DIR + "cryo_wave_sheet.png"))
	quit(error)


func _save(image: Image, path: String) -> Error:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("No se pudo guardar %s" % path)
	return error


func _save_text(path: String, text: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar %s" % path)
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK


func _sheet(frames: Array[Image]) -> Image:
	var width: int = frames[0].get_width()
	var sheet: Image = Image.create(width * frames.size(), frames[0].get_height(), false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * width, 0))
	return sheet


# Mezcla un color con transparencia encima de lo que haya.
func _blend(image: Image, x: int, y: int, color: Color, alpha: float) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height() or alpha <= 0.0:
		return
	var top: Color = color
	top.a = minf(alpha, 1.0)
	image.set_pixel(x, y, image.get_pixel(x, y).blend(top))


# Ángulo en grados, en sentido horario desde arriba.
func _angle_cw(dx: float, dy: float) -> float:
	return fposmod(rad_to_deg(atan2(dx, -dy)), 360.0)


func _make_base() -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(BASE_SOURCE))
	image.convert(Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var c: Color = image.get_pixel(x, y)
			if c.a > 0.0 and c.b8 > c.r8 + 40:
				image.set_pixel(x, y, W if c.b8 > 200 else I3)
	return image


func _spin_speed(tick: int) -> float:
	if tick < PULSE_END:
		return SPIN_FULL
	if tick < COOL_END:
		return SPIN_COOL
	var p: float = _reload_progress(tick)
	return SPIN_RELOAD_MIN + SPIN_RELOAD_GAIN * p * p


func _reload_progress(tick: int) -> float:
	return clampf(float(tick - COOL_END) / (CYCLE_END - COOL_END), 0.0, 1.0)


func _cycle_states() -> Array:
	var angles: Array[float] = [0.0]
	for tick: int in range(1, CYCLE_END):
		angles.append(angles[-1] + _spin_speed(tick - 1) / TICKS_PER_SECOND)
	# Empieza girado para acabar en el ángulo 0, el primer frame de default.
	var offset: float = -(angles[-1] + _spin_speed(CYCLE_END - 1) / TICKS_PER_SECOND)
	var states: Array = []
	for tick: int in CYCLE_END:
		var angle: int = posmod(roundi((angles[tick] + offset) / ANGLE_STEP), ANGLE_FRAMES)
		var key: Array
		if tick < CHARGE_END:
			key = [1, angle, "bright", 3, true]
		elif tick < PULSE_END:
			key = [2, angle, "flash", 4, true]
		elif tick < COOL_END:
			key = [3, angle, "dark", 0, true]
		else:
			var p: float = _reload_progress(tick)
			var band: int = 0 if p < 0.3 else 1 if p < 0.6 else 2 if p < 0.9 else 3
			key = [3, angle, "normal", band, p > 0.5]
		if not states.is_empty() and states[-1][0] == key:
			states[-1][1] += 1
		else:
			states.append([key, 1])
	return states


# Píxeles con su distancia al centro entre r0 y r1: [x, y, d, dx, dy].
func _ring_pixels(r0: float, r1: float) -> Array:
	var pixels: Array = []
	for y: int in SIZE:
		for x: int in SIZE:
			var dx: float = x + 0.5 - SIZE / 2.0
			var dy: float = y + 0.5 - SIZE / 2.0
			var d: float = Vector2(dx, dy).length()
			if d >= r0 and d < r1:
				pixels.append([x, y, d, dx, dy])
	return pixels


func _make_cannon(key: Array) -> Image:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var ang: float = key[1] * ANGLE_STEP
	var mode: String = key[2]
	var center: float = SIZE / 2.0
	for px: Array in _ring_pixels(12.5, 13.5) + _ring_pixels(8.5, 9.5):
		image.set_pixel(px[0], px[1], O)
	# Aro de metal con 8 ranuras oscuras que giran con él
	for px: Array in _ring_pixels(9.5, 12.5):
		var color: Color = _metal(-(px[3] + px[4]) / (1.4142 * px[2]))
		var a: float = _angle_cw(px[3], px[4])
		for i: int in 8:
			var da: float = fposmod(a - ang - 45.0 * i + 180.0, 360.0) - 180.0
			if absf(px[2] * deg_to_rad(da)) < 0.8:
				color = M0
		image.set_pixel(px[0], px[1], color)
	for px: Array in _ring_pixels(7.5, 8.5):
		image.set_pixel(px[0], px[1], BAND_COLORS[key[3]])
	_draw_core(image, 6.5, mode)
	# Remolino dentro del cristal (dos brazos, se repite cada 90° de giro del aro)
	if mode != "flash":
		for px: Array in _ring_pixels(2.0, 5.5):
			if absf(fposmod(_angle_cw(px[3], px[4]) - ang * 2.0 - px[2] * 40.0, 180.0) - 90.0) < 9.0:
				_blend(image, px[0], px[1], W if mode == "normal" else I3, 0.55)
	# 4 rodillos sobre el aro
	for i: int in 4:
		var a: float = deg_to_rad(ang + 90.0 * i)
		var roller: Vector2 = Vector2(center + 11.0 * sin(a), center - 11.0 * cos(a))
		for y: int in SIZE:
			for x: int in SIZE:
				var offset: Vector2 = Vector2(x + 0.5, y + 0.5) - roller
				var d: float = offset.length()
				if d >= 3.3:
					continue
				var color: Color = O
				if d < 1.2:
					color = I4 if key[4] else I3
				elif d < 2.4:
					color = M3 if offset.x + offset.y < -1.0 else M2
				image.set_pixel(x, y, color)
	# Nieve que entra en espiral. Avanza con el giro del aro (más rápida cuanto más gira) y a cada 90°
	# cada copo ocupa el sitio de otro, para que la figura se repita.
	for i: int in SNOW_COUNT:
		var phase: float = fposmod(float(i) / SNOW_COUNT + ang / 90.0 * 5.0 / SNOW_COUNT, 1.0)
		var radius: float = 16.0 - phase * 7.0
		var a: float = deg_to_rad(ang * 5.0 * 360.0 / SNOW_COUNT / 90.0 + i * 360.0 / SNOW_COUNT + phase * 160.0)
		_blend(image, floori(center + radius * sin(a)), floori(center - radius * cos(a)), I4, 0.85 * sin(phase * PI))
	return image


func _metal(light: float) -> Color:
	return M3 if light > 0.6 else M2 if light > -0.15 else M1 if light > -0.75 else M0


# Cristal redondo con contorno, luz arriba a la izquierda y aristas de talla.
func _draw_core(image: Image, r: float, mode: String) -> void:
	var ramp: Array = CORE_RAMPS[mode]
	for px: Array in _ring_pixels(0.0, r + 1.0):
		var d: float = px[2]
		var dx: float = px[3]
		var dy: float = px[4]
		if d >= r:
			image.set_pixel(px[0], px[1], O)
			continue
		var s: float = 0.55 * (-(dx + dy) / (1.4142 * r)) + 0.45 * (1.0 - d / r)
		var i: int = 3 if s > 0.5 else 2 if s > 0.22 else 1 if s > -0.12 else 0
		if absf(dx - dy) < 0.8 and dx > 0.0:
			i = maxi(0, i - 1)
		if absf(dx + dy) < 0.8 and dx > 0.0 and dy < 0.0:
			i = maxi(0, i - 1)
		image.set_pixel(px[0], px[1], ramp[i])
	if mode != "dark":
		var sx: int = int(SIZE / 2.0 - r * 0.5)
		image.set_pixel(sx, sx, W)
		image.set_pixel(sx + 1, sx, I4 if mode == "normal" else W)


# Onda: frente blanco y eco de 1 px, y detrás 6 brazos de ventisca que giran y se desvanecen. Las
# medidas de los brazos van en píxeles de pantalla (la onda se dibuja a wave_scale 1,5).
func _make_wave(f: int) -> Image:
	var image: Image = Image.create(WAVE_SIZE, WAVE_SIZE, false, Image.FORMAT_RGBA8)
	var r: float = 15.5 + 7.2 * f
	var alpha: float = 1.0 - maxf(0.0, f - 3.0) / 5.0
	var rot: float = f * 25.0
	var center: float = WAVE_SIZE / 2.0
	for y: int in WAVE_SIZE:
		for x: int in WAVE_SIZE:
			var dx: float = x + 0.5 - center
			var dy: float = y + 0.5 - center
			var d: float = Vector2(dx, dy).length()
			if d >= r or d < 5.3:
				continue
			var ang: float = _angle_cw(dx, dy)
			if d >= r - 1.0:
				# Al final el frente se rompe
				if f >= 6 and int(ang / 8.0) % 3 == 0:
					continue
				_blend(image, x, y, W, alpha)
			elif d >= r - 2.0:
				_blend(image, x, y, I3, alpha * 0.6)
			var depth: float = (r - d) * 1.5
			if depth < 22.0:
				var s: float = fposmod(ang - rot + depth * 3.2, 60.0)
				if s < 7.0:
					_blend(image, x, y, W if s < 3.0 else I3, alpha * (1.0 - depth / 26.0))
	return image


func _save_cannon_frames(states: Array, keys_by_sheet: Array) -> Error:
	var text: String = '[gd_resource type="SpriteFrames" format=3 uid="%s"]\n\n' % CANNON_FRAMES_UID
	for s: int in SHEETS.size():
		text += '[ext_resource type="Texture2D" uid="%s" path="%scryo_cannon_%s_sheet.png" id="%d"]\n' % [
				SHEET_UIDS[s], DIR, SHEETS[s], s + 1]
	text += "\n"
	# Id de cada AtlasTexture por clave
	var ids: Dictionary = {}
	for s: int in SHEETS.size():
		for i: int in keys_by_sheet[s].size():
			ids[keys_by_sheet[s][i]] = ids.size()
			text += '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("%d")\n' % [ids.size() - 1, s + 1]
			text += "region = Rect2(%d, 0, %d, %d)\n\n" % [i * SIZE, SIZE, SIZE]
	var idle: PackedStringArray = []
	for key: Array in keys_by_sheet[0]:
		idle.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % ids[key])
	var fire: PackedStringArray = []
	for state: Array in states:
		fire.append('{\n"duration": %d.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % [state[1], ids[state[0]]])
	text += "[resource]\nanimations = [{\n"
	text += '"frames": [%s],\n' % ", ".join(idle)
	text += '"loop": true,\n"name": &"default",\n"speed": %s\n}, {\n' % str(SPIN_FULL / ANGLE_STEP)
	text += '"frames": [%s],\n' % ", ".join(fire)
	text += '"loop": false,\n"name": &"fire_0",\n"speed": %d.0\n}]\n' % TICKS_PER_SECOND
	return _save_text(CANNON_FRAMES_PATH, text)


func _save_fire_frame(fire_frame: int) -> Error:
	var text: String = FileAccess.get_file_as_string(PULSE_DATA_PATH)
	var regex: RegEx = RegEx.create_from_string("fire_frame = \\d+")
	return _save_text(PULSE_DATA_PATH, regex.sub(text, "fire_frame = %d" % fire_frame))
