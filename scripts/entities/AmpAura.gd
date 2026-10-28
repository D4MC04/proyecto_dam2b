extends Node2D
class_name AmpAura
# Ondas del aura de un Amplificador (va como hijo suyo): cada WAVE_INTERVAL s sale de la torreta un
# anillo de ámbar en píxeles que crece hasta el radio del aura y se apaga. Al pasar por una torreta
# amplificada la hace brillar (Turret.flash_amp). Mientras un EMP apaga la torreta no salen ondas.

const WAVE_INTERVAL := 2.5
const WAVE_TIME := 1.1
# Radio con el que nace la onda (el borde del emisor).
const START_RADIUS := 10.0
# Frente de la onda y dos ecos por detrás, cada uno ECHO_GAP px más adentro y más tenue.
const FRONT_COLOR := Color("#ffe082")
const ECHO_COLORS: PackedColorArray = [Color("#ecb23c"), Color("#96641e")]
const ECHO_GAP := 2.0
const ECHO_ALPHA: PackedFloat32Array = [0.6, 0.3]
# Alcance pintado al pasar el ratón o seleccionar el Amplificador (y en la vista previa).
const FILL_COLOR := Color(0.93, 0.7, 0.24, 0.06)
const BORDER_COLOR := Color("#ecb23c")
# La primera onda sale poco después de colocarlo.
const FIRST_WAVE_DELAY := 0.4

var _turret: Turret
# Segundos de la onda en curso; < 0 = no hay onda.
var _age := -1.0
var _wait := FIRST_WAVE_DELAY
# Torretas que ya han brillado con la onda en curso.
var _flashed: Array[Turret] = []

func _ready() -> void:
	_turret = get_parent()
	# Bajo la base y el emisor del Amplificador, como la onda de la Cryo.
	show_behind_parent = true

func _process(delta: float) -> void:
	if _turret.disabled:
		if _age >= 0.0:
			_age = -1.0
			queue_redraw()
		_wait = FIRST_WAVE_DELAY
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait += WAVE_INTERVAL
		_age = 0.0
		_flashed.clear()
	if _age < 0.0:
		return
	_age += delta
	if _age >= WAVE_TIME:
		_age = -1.0
	else:
		_flash_reached()
	queue_redraw()

# Crece rápido al principio y frena al llegar al borde del aura.
func _radius() -> float:
	var t := _age / WAVE_TIME
	return lerpf(START_RADIUS, _aura_radius(), 1.0 - (1.0 - t) * (1.0 - t))

func _aura_radius() -> float:
	var circle := _turret.data.attack_range as CircleShape2D
	return circle.radius if circle else 0.0

func _flash_reached() -> void:
	var radius := _radius()
	for node in get_tree().get_nodes_in_group(&"turrets"):
		var turret := node as Turret
		if turret == null or turret == _turret or turret.amp_level == 0 or turret in _flashed:
			continue
		if turret.global_position.distance_to(global_position) <= radius:
			_flashed.append(turret)
			turret.flash_amp()

func _draw() -> void:
	if _age < 0.0:
		return
	var t := _age / WAVE_TIME
	# Se apaga más deprisa al final.
	var alpha := 1.0 - t * t
	var radius := _radius()
	_draw_ring(radius, Color(FRONT_COLOR, alpha))
	for i in ECHO_COLORS.size():
		var echo_radius := radius - ECHO_GAP * (i + 1)
		if echo_radius > START_RADIUS:
			_draw_ring(echo_radius, Color(ECHO_COLORS[i], alpha * ECHO_ALPHA[i]))

# Anillo de 1 px sin antialias, con más puntos cuanto más grande.
func _draw_ring(radius: float, color: Color) -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, maxi(24, roundi(radius)), color, 1.0, false)

## Pinta en "canvas" (dentro de su _draw) el alcance del aura en ámbar, con el estilo del alcance de
## las demás torretas. Lo usan el Amplificador al pasar el ratón o seleccionarlo y la vista previa.
static func draw_circle_aura(canvas: CanvasItem, shape: Shape2D) -> void:
	var circle := shape as CircleShape2D
	if circle == null:
		return
	canvas.draw_circle(Vector2.ZERO, circle.radius, FILL_COLOR)
	canvas.draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 96, BORDER_COLOR, 1.0, false)
