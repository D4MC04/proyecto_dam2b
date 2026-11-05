extends Control
class_name SectorRadar

# Radar de la selección de nivel: la estación en el centro y un contacto por nivel de
# GameData.levels, colocado según LevelData.radar_distance y radar_bearing. Un barrido gira y
# enciende cada contacto al pasar. El alcance llega hasta el último nivel desbloqueado; fuera, niebla
# con ruido. Clic en un contacto = seleccionarlo; doble clic = lanzarlo.
#
# Todo se pinta en _draw, cada parte en su función (_draw_background, _draw_sweep, _draw_fog...),
# para que otros modos (p. ej. el radar corrupto del jefe) puedan cambiar o añadir partes.

signal sector_selected(index: int)
signal sector_launched(index: int)

# UNKNOWN = el sector del jefe final (SEC-10), que aún no tiene nivel: se ve siempre, pero no se juega.
enum ContactState { LOCKED, PENDING, COMPLETED, UNKNOWN }

## Sectores totales de la campaña: si GameData.levels tiene menos, el último (el del jefe) sale
## como contacto UNKNOWN de prueba, arriba en el centro, cuando se ha ganado el último nivel.
const TOTAL_SECTORS := 10
const BOSS_DISTANCE := 0.72
const BOSS_BEARING := 0.0
const BOSS_COLOR := Color("#e65a4f")
const BOSS_MARK_SIZE := 32

## Radio del radar en km (los textos de los anillos y la distancia de la ficha).
const RADIUS_KM := 4000
const RING_COUNT := 4
# Hueco entre el borde del control y el borde del radar.
const EDGE_MARGIN := 4.0
# Alcance: margen tras el último contacto visible, y tope.
const RANGE_MARGIN := 0.04
const RANGE_NEXT_MARGIN := 0.02
const RANGE_MAX := 0.9

const SHIP_DIR := "res://assets/sprites/enemies/radar/"
# Nombre del sprite por LevelData.RadarShip (los genera scripts/tools/make_radar_ships.gd).
const SHIP_FILES: Array[String] = ["raider", "fang", "crusher", "specter"]
const SHIP_SCALE := 2
const LABEL_SIZE := 16
# Distancia de la línea base del rótulo "SEC-0N" al centro del contacto.
const LABEL_OFFSET := 20.0
# Radio del área de clic de cada contacto.
const HIT_RADIUS := 16.0

const SWEEP_SPEED := 1.6
const TRAIL_STEPS := 36
const TRAIL_STEP_ANGLE := 0.0279253 # 1,6° en radianes
const TRAIL_ALPHA := 0.22
# Brillo de un contacto: se apaga en GLOW_FADE s desde que pasa el barrido, hasta un mínimo.
const GLOW_FADE := 2.6
const GLOW_MIN := 0.45
const GLOW_MIN_CURRENT := 0.75

const NOISE_DOTS := 120
const NOISE_ALPHA := 0.18
const FOG_SEGMENTS := 96

const DASH := 6.0
const RANGE_DASH_SPEED := 20.0
const ROUTE_DASH := 5.0
const ROUTE_DASH_SPEED := 25.0
# La ruta empieza tras la estación y acaba antes del icono.
const ROUTE_START := 9.0
const ROUTE_END := 16.0

# Salto al seleccionar, flotación posterior y onda circular.
const JUMP_TIME := 0.35
const JUMP_HEIGHT := 6.0
const FLOAT_PERIOD := 1.6
const FLOAT_HEIGHT := 2.0
const RIPPLE_TIME := 1.4
const RIPPLE_FROM := 8.0
const RIPPLE_TO := 30.0

# Parpadeo de los ojos: ciclo en s y tramos (fracción del ciclo, alfa) como en el boceto.
const BLINK_PERIOD := 3.5
const BLINK_KEYS: Array[Vector2] = [
	Vector2(0.0, 1.0), Vector2(0.90, 1.0), Vector2(0.93, 0.1), Vector2(0.96, 1.0),
	Vector2(0.98, 0.3), Vector2(1.0, 1.0),
]
# Desfase del parpadeo entre contactos, para que no parpadeen todos a la vez.
const BLINK_PHASE_STEP := 0.37

const DISK_INNER_COLOR := Color("#122440")
const DISK_OUTER_COLOR := Color("#060b14")
const DISK_BANDS := 6
const GRID_COLOR := Color("#1c4a60")
const BORDER_COLOR := Color("#1c7496")
const ACCENT_COLOR := Color("#40e0f0")
const SWEEP_LINE_COLOR := Color("#befaff")
const FOG_COLOR := Color(0.01, 0.03, 0.05, 0.85)
const NOISE_COLOR := Color("#96c8d2")
const STATION_HOLE_COLOR := Color("#060b14")
const PENDING_COLOR := Color("#ecb23c")
const COMPLETED_COLOR := Color("#3cb860")
const SELECTED_COLOR := Color("#54a0e2")
const EYE_COLOR := Color("#f0323c")

# Un contacto por nivel (data = null en el sector del jefe sin nivel).
class Contact:
	var index: int
	var data: LevelData
	var distance: float
	var bearing: float
	var state: SectorRadar.ContactState
	var hull: Texture2D
	var eyes: Texture2D
	# Último momento (en _time) en que pasó el barrido.
	var hit_time: float = -100.0

var selected_index := -1
var _contacts: Array[Contact] = []
var _hover_index := -1
var _time := 0.0
var _sweep := 0.0
var _range := RANGE_MAX
var _select_time := -100.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	visibility_changed.connect(func() -> void: set_process(is_visible_in_tree()))
	set_process(is_visible_in_tree())
	refresh()

func _process(delta: float) -> void:
	var previous_sweep := _sweep
	_time += delta
	_sweep = fmod(_time * SWEEP_SPEED, TAU)
	for contact: Contact in _contacts:
		if _sweep_crossed(previous_sweep, _sweep, deg_to_rad(contact.bearing)):
			contact.hit_time = _time
	queue_redraw()

## Vuelve a leer los niveles y el progreso. Mantiene la selección si sigue visible; si no, elige
## el primer nivel sin completar (o el último visible).
func refresh() -> void:
	_contacts.clear()
	var last_visible := -1
	for i: int in GameData.levels.size():
		var contact := Contact.new()
		contact.index = i
		contact.data = GameData.levels[i]
		contact.distance = contact.data.radar_distance
		contact.bearing = contact.data.radar_bearing
		contact.state = get_level_state(i)
		contact.hull = _load_texture(SHIP_DIR + "radar_%s.png" % SHIP_FILES[contact.data.radar_ship])
		contact.eyes = _load_texture(SHIP_DIR + "radar_%s_eyes.png" % SHIP_FILES[contact.data.radar_ship])
		_contacts.append(contact)
		if contact.state != ContactState.LOCKED:
			last_visible = i
	_range = _compute_range(last_visible)
	# El jefe solo aparece al ganar el último nivel que hay; entonces el radar llega a su tope.
	if GameData.levels.size() < TOTAL_SECTORS and last_visible >= 0 and _contacts[last_visible].index == GameData.levels.size() - 1 and _contacts[last_visible].state == ContactState.COMPLETED:
		_range = RANGE_MAX
		var boss := Contact.new()
		boss.index = TOTAL_SECTORS - 1
		boss.distance = BOSS_DISTANCE
		boss.bearing = BOSS_BEARING
		boss.state = ContactState.UNKNOWN
		_contacts.append(boss)
	if last_visible < 0:
		selected_index = -1
	elif selected_index < 0 or selected_index >= _contacts.size() or (selected_index > last_visible and _contacts[selected_index].state != ContactState.UNKNOWN):
		select(_default_selection(last_visible))
	queue_redraw()

func select(index: int) -> void:
	if index < 0 or index >= _contacts.size() or _contacts[index].state == ContactState.LOCKED:
		return
	if index != selected_index:
		_select_time = _time
	selected_index = index
	sector_selected.emit(index)

## Estado del nivel `index` (desde 0) según GameState. El radar solo enseña hasta el progreso real
## (current_level), aunque is_unlocked() deje jugar todos los niveles mientras se prueba.
func get_level_state(index: int) -> ContactState:
	if index >= GameData.levels.size():
		return ContactState.UNKNOWN
	if not GameState.is_unlocked(index) or index >= GameState.current_level:
		return ContactState.LOCKED
	if GameState.get_level_stars(index + 1) > 0 or index + 1 < GameState.current_level:
		return ContactState.COMPLETED
	return ContactState.PENDING

## Distancia en km de un nivel, redondeada a decenas.
static func get_distance_km(data: LevelData) -> int:
	return roundi(data.radar_distance * RADIUS_KM / 10.0) * 10

## Número con separador de miles según el idioma (NUMBER_THOUSANDS_SEP): 4000 -> "4.000".
static func format_thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(-3)
	groups.insert(0, digits)
	var separator := String(TranslationServer.translate("NUMBER_THOUSANDS_SEP"))
	return ("-" if value < 0 else "") + separator.join(groups)

## Sectores asegurados (completados), para el subtítulo.
func get_secured_count() -> int:
	var count := 0
	for contact: Contact in _contacts:
		if contact.state == ContactState.COMPLETED:
			count += 1
	return count

## Alcance actual del radar en km, redondeado a centenas.
func get_range_km() -> int:
	return roundi(_range * RADIUS_KM / 100.0) * 100

static func get_sector_code(index: int) -> String:
	return String(TranslationServer.translate("RADAR_SECTOR_CODE")) % (index + 1)

func _load_texture(path: String) -> Texture2D:
	# Los sprites los genera un script aparte: si aún no existen, el contacto se pinta como un cuadro.
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# El alcance llega justo al último contacto visible, sin enseñar el siguiente.
func _compute_range(last_visible: int) -> float:
	if last_visible < 0:
		return RANGE_MARGIN
	var distance := _contacts[last_visible].distance
	if last_visible + 1 >= _contacts.size():
		return minf(distance + RANGE_MARGIN, RANGE_MAX)
	var next_distance := _contacts[last_visible + 1].distance
	return minf(distance + RANGE_MARGIN, (distance + next_distance) / 2.0 + RANGE_NEXT_MARGIN)

func _default_selection(last_visible: int) -> int:
	for contact: Contact in _contacts:
		if contact.state == ContactState.PENDING:
			return contact.index
	return last_visible

# El barrido ha pasado por `angle` entre los dos frames (con la vuelta de TAU a 0).
func _sweep_crossed(from: float, to: float, angle: float) -> bool:
	if to >= from:
		return angle > from and angle <= to
	return angle > from or angle <= to

func _get_center() -> Vector2:
	return (size / 2.0).round()

func _get_radius() -> float:
	return floorf(minf(size.x, size.y) / 2.0) - EDGE_MARGIN

# Rumbo en grados (0 = arriba, sentido horario) a dirección en pantalla.
func _direction(bearing: float) -> Vector2:
	return Vector2(sin(bearing), -cos(bearing))

func _contact_position(contact: Contact) -> Vector2:
	var offset := _direction(deg_to_rad(contact.bearing)) * contact.distance * _get_radius()
	return (_get_center() + offset).round()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hover(_contact_at((event as InputEventMouseMotion).position))
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT or not button.pressed:
			return
		var index := _contact_at(button.position)
		if index < 0:
			return
		select(index)
		if button.double_click and _contacts[index].state != ContactState.UNKNOWN:
			sector_launched.emit(index)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_hover(-1)

func _set_hover(index: int) -> void:
	_hover_index = index
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if index >= 0 else CURSOR_ARROW

func _contact_at(point: Vector2) -> int:
	var best := -1
	var best_distance := HIT_RADIUS
	for contact: Contact in _contacts:
		if contact.state == ContactState.LOCKED:
			continue
		var distance := point.distance_to(_contact_position(contact))
		if distance < best_distance:
			best = contact.index
			best_distance = distance
	return best

func _draw() -> void:
	var center := _get_center()
	var radius := _get_radius()
	var range_radius := roundf(_range * radius)
	_draw_background(center, radius)
	_draw_grid(center, radius)
	_draw_sweep(center, radius)
	_draw_fog(center, radius, range_radius)
	_draw_ring_labels(center, radius, range_radius)
	_draw_dashed_circle(center, range_radius, ACCENT_COLOR, _time * RANGE_DASH_SPEED)
	_draw_route(center)
	draw_arc(center, radius, 0.0, TAU, 128, ACCENT_COLOR, 2.0)
	_draw_station(center)
	_draw_contacts()

# Disco en bandas concéntricas, más claro en el centro.
func _draw_background(center: Vector2, radius: float) -> void:
	for band: int in DISK_BANDS:
		var weight := float(band) / float(DISK_BANDS - 1)
		draw_circle(center, radius * (1.0 - float(band) / float(DISK_BANDS)), DISK_OUTER_COLOR.lerp(DISK_INNER_COLOR, weight))

# Anillos, radios cada 30° y marcas del borde cada 5° (más largas cada 30°).
func _draw_grid(center: Vector2, radius: float) -> void:
	for ring: int in range(1, RING_COUNT + 1):
		draw_arc(center, roundf(radius * ring / RING_COUNT), 0.0, TAU, 96, GRID_COLOR, 1.0)
	for degrees: int in range(0, 360, 5):
		var direction := _direction(deg_to_rad(degrees))
		if degrees % 30 == 0:
			draw_line(center, center + direction * radius, GRID_COLOR, 1.0)
		var tick := 9.0 if degrees % 30 == 0 else 4.0
		draw_line(center + direction * (radius - tick), center + direction * radius, BORDER_COLOR, 1.0)

# Barrido: cuñas que se desvanecen detrás de la línea.
func _draw_sweep(center: Vector2, radius: float) -> void:
	for step: int in TRAIL_STEPS:
		var color := ACCENT_COLOR
		color.a = TRAIL_ALPHA * (1.0 - float(step) / TRAIL_STEPS)
		var end_angle := _sweep - step * TRAIL_STEP_ANGLE
		var start_angle := end_angle - TRAIL_STEP_ANGLE
		draw_colored_polygon(PackedVector2Array([
			center, center + _direction(start_angle) * radius, center + _direction(end_angle) * radius,
		]), color)
	draw_line(center, center + _direction(_sweep) * radius, SWEEP_LINE_COLOR, 2.0)

# Niebla fuera del alcance (corona de trapecios) con puntos de ruido nuevos en cada frame.
func _draw_fog(center: Vector2, radius: float, range_radius: float) -> void:
	if range_radius >= radius:
		return
	for segment: int in FOG_SEGMENTS:
		var a := _direction(TAU * segment / FOG_SEGMENTS)
		var b := _direction(TAU * (segment + 1) / FOG_SEGMENTS)
		draw_colored_polygon(PackedVector2Array([
			center + a * range_radius, center + a * (radius + 1.0),
			center + b * (radius + 1.0), center + b * range_radius,
		]), FOG_COLOR)
	for _dot: int in NOISE_DOTS:
		var point := center + _direction(_rng.randf() * TAU) * _rng.randf_range(range_radius, radius - 2.0)
		var color := NOISE_COLOR
		color.a = _rng.randf() * NOISE_ALPHA
		draw_rect(Rect2(point.floor(), Vector2(2, 2)), color)

# Textos de km de cada anillo: a la derecha, justo encima del eje (ningún contacto va ahí).
@warning_ignore("integer_division")
func _draw_ring_labels(center: Vector2, radius: float, range_radius: float) -> void:
	var font := get_theme_default_font()
	for ring: int in range(1, RING_COUNT + 1):
		var ring_radius := roundf(radius * ring / RING_COUNT)
		# Fuera del alcance no se ve nada, tampoco los km.
		if ring_radius > range_radius + 2.0:
			continue
		var color := ACCENT_COLOR
		color.a = 0.6
		var text := format_thousands(RADIUS_KM * ring / RING_COUNT)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		draw_string(font, Vector2(center.x + ring_radius - 4.0 - width, center.y - 4.0), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, color)

# Ruta discontinua animada desde la estación hasta el contacto seleccionado.
func _draw_route(center: Vector2) -> void:
	if selected_index < 0:
		return
	var target := _contact_position(_contacts[selected_index])
	var direction := center.direction_to(target)
	var color := SELECTED_COLOR
	color.a = 0.9
	_draw_dashed_line(center + direction * ROUTE_START, target - direction * ROUTE_END, color, ROUTE_DASH, _time * ROUTE_DASH_SPEED)

# La estación: cruz y cuadro con un hueco en el centro.
func _draw_station(center: Vector2) -> void:
	draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), ACCENT_COLOR)
	draw_rect(Rect2(center - Vector2(7, 1), Vector2(14, 2)), ACCENT_COLOR)
	draw_rect(Rect2(center - Vector2(1, 7), Vector2(2, 14)), ACCENT_COLOR)
	draw_rect(Rect2(center - Vector2(1, 1), Vector2(2, 2)), STATION_HOLE_COLOR)

func _draw_contacts() -> void:
	var font := get_theme_default_font()
	var current := _default_selection(-1)
	for contact: Contact in _contacts:
		if contact.state == ContactState.LOCKED:
			continue
		var contact_point := _contact_position(contact)
		var is_selected := contact.index == selected_index
		if contact.state == ContactState.UNKNOWN:
			_draw_unknown(contact, contact_point, is_selected, font)
			continue
		var color := COMPLETED_COLOR if contact.state == ContactState.COMPLETED else PENDING_COLOR
		var alpha := maxf(GLOW_MIN_CURRENT if contact.index == current else GLOW_MIN, 1.0 - (_time - contact.hit_time) / GLOW_FADE)
		if is_selected or contact.index == _hover_index:
			color = SELECTED_COLOR
			alpha = 1.0
		color.a = alpha
		var icon_point := contact_point
		if is_selected:
			icon_point.y -= _selected_lift()
			_draw_ripple(contact_point, color)
		_draw_ship(contact, icon_point, color)
		var code := get_sector_code(contact.index)
		var width := font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		draw_string(font, Vector2(roundf(contact_point.x - width / 2.0), contact_point.y + LABEL_OFFSET), code,
				HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, color)

# Sector del jefe sin nivel: un "?" rojo que late, con su rótulo (el modo corrupto es otro ticket).
func _draw_unknown(contact: Contact, point: Vector2, is_selected: bool, font: Font) -> void:
	var color := BOSS_COLOR
	color.a = 0.55 + 0.45 * absf(sin(_time * 2.0))
	if is_selected or contact.index == _hover_index:
		color.a = 1.0
	if is_selected:
		_draw_ripple(point, color)
	var mark_width := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_MARK_SIZE).x
	draw_string(font, Vector2(roundf(point.x - mark_width / 2.0), point.y + 8.0), "?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_MARK_SIZE, color)
	var code := get_sector_code(contact.index)
	var width := font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	draw_string(font, Vector2(roundf(point.x - width / 2.0), point.y + LABEL_OFFSET), code,
			HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, color)

func _draw_ship(contact: Contact, point: Vector2, color: Color) -> void:
	if contact.hull == null:
		draw_rect(Rect2(point - Vector2(5, 4), Vector2(10, 8)), color)
		return
	var ship_size := contact.hull.get_size() * SHIP_SCALE
	var rect := Rect2((point - ship_size / 2.0).round(), ship_size)
	draw_texture_rect(contact.hull, rect, false, color)
	if contact.eyes != null:
		var eye_color := EYE_COLOR
		eye_color.a = color.a * _eye_alpha(_time / BLINK_PERIOD + contact.index * BLINK_PHASE_STEP)
		draw_texture_rect(contact.eyes, rect, false, eye_color)

# Altura del icono seleccionado: un salto al elegirlo y luego flota arriba y abajo.
func _selected_lift() -> float:
	var elapsed := _time - _select_time
	if elapsed < JUMP_TIME:
		return roundf(JUMP_HEIGHT * sin(PI * elapsed / JUMP_TIME))
	var phase := (elapsed - JUMP_TIME) / FLOAT_PERIOD
	return roundf(FLOAT_HEIGHT * (0.5 - 0.5 * cos(TAU * phase)))

# Onda circular que sale del contacto seleccionado y se desvanece.
func _draw_ripple(point: Vector2, color: Color) -> void:
	var progress := fmod(maxf(_time - _select_time, 0.0), RIPPLE_TIME) / RIPPLE_TIME
	var ripple_color := color
	ripple_color.a = 0.9 * (1.0 - progress)
	draw_arc(point, roundf(lerpf(RIPPLE_FROM, RIPPLE_TO, progress)), 0.0, TAU, 48, ripple_color, 1.0)

# Alfa de los ojos en la fracción `cycle` del parpadeo (se repite cada 1.0).
func _eye_alpha(cycle: float) -> float:
	var phase := fposmod(cycle, 1.0)
	for key: int in range(1, BLINK_KEYS.size()):
		var to := BLINK_KEYS[key]
		if phase <= to.x:
			var from := BLINK_KEYS[key - 1]
			return lerpf(from.y, to.y, inverse_lerp(from.x, to.x, phase))
	return 1.0

# Círculo discontinuo; `offset` (px) desplaza los trazos a lo largo del borde.
func _draw_dashed_circle(center: Vector2, radius: float, color: Color, offset: float) -> void:
	if radius <= 0.0:
		return
	var period := DASH * 2.0
	var count := maxi(roundi(TAU * radius / period), 1)
	var step := TAU / count
	var shift := fposmod(offset, period) / period * step
	for dash: int in count:
		var start := dash * step + shift
		draw_arc(center, radius, start, start + step / 2.0, 4, color, 1.0)

# Línea discontinua; `offset` (px) hace avanzar los trazos de `from` hacia `to`.
func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, dash: float, offset: float) -> void:
	var length := from.distance_to(to)
	if length <= 0.0:
		return
	var direction := from.direction_to(to)
	var period := dash * 2.0
	var start := fposmod(offset, period) - period
	while start < length:
		var dash_from := maxf(start, 0.0)
		var dash_to := minf(start + dash, length)
		if dash_to > dash_from:
			draw_line(from + direction * dash_from, from + direction * dash_to, color, 2.0)
		start += period
