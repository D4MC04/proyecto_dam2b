extends Node2D
class_name AmpAura
# Aura de un Amplificador (va como hijo suyo): su círculo de alcance en ámbar, con el mismo estilo
# que el alcance de las demás torretas (relleno casi transparente y borde de 1 px sin antialias),
# que palpita despacio. Mientras un EMP apaga la torreta no se ve.

const FILL_COLOR := Color(0.93, 0.7, 0.24, 0.06)
const BORDER_COLOR := Color("#ecb23c")
# Segundos de un latido y opacidad mínima en el punto más bajo.
const PULSE_TIME := 2.0
const PULSE_MIN := 0.35

var _turret: Turret
var _time := 0.0

func _ready() -> void:
	_turret = get_parent()
	# Bajo la base y el emisor del Amplificador.
	show_behind_parent = true

func _process(delta: float) -> void:
	visible = not _turret.disabled
	_time += delta
	modulate.a = lerpf(PULSE_MIN, 1.0, 0.5 + 0.5 * sin(_time * TAU / PULSE_TIME))

func _draw() -> void:
	draw_circle_aura(self, _turret.data.attack_range)

## Pinta en "canvas" (dentro de su _draw) el círculo del aura centrado en su origen. Lo usa también
## la vista previa de BuildManager.
static func draw_circle_aura(canvas: CanvasItem, shape: Shape2D) -> void:
	var circle := shape as CircleShape2D
	if circle == null:
		return
	canvas.draw_circle(Vector2.ZERO, circle.radius, FILL_COLOR)
	canvas.draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 96, BORDER_COLOR, 1.0, false)
