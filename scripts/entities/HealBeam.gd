class_name HealBeam
extends Node2D

# Rayo de la Mender hasta la nave que cura, en pixel art (rectángulos de 1 px, sin antialiasing):
# una línea verde fina y algo transparente para que no tape el mapa, con pulsos claros que viajan de
# la Mender a la curada para que se vea hacia dónde va la vida. Usa la rampa de HealEffect.
# Lo crea y lo mueve Enemy (update_ends); se oculta cuando no hay a quién curar.

const LINE_ALPHA: float = 0.55
# Separación entre pulsos (px) y su velocidad (px/s).
const PULSE_GAP: float = 8.0
const PULSE_SPEED: float = 40.0

var _from: Vector2
var _to: Vector2
var _flow: float = 0.0

func _ready() -> void:
	# En coordenadas globales: los extremos son dos naves que pueden ir por caminos distintos.
	top_level = true
	z_index = 5
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	_flow = fmod(_flow + PULSE_SPEED * delta, PULSE_GAP)
	queue_redraw()

## Extremos del rayo en coordenadas globales: la punta de la aguja y la curada.
func update_ends(from: Vector2, to: Vector2) -> void:
	_from = from.round()
	_to = to.round()

func _draw() -> void:
	var points: Array[Vector2i] = Geometry2D.bresenham_line(Vector2i(_from), Vector2i(_to))
	for i: int in points.size():
		# Distancia al pulso más cercano por detrás: 0 en la cabeza, que es la más clara.
		var phase: float = fposmod(_flow - i, PULSE_GAP)
		var color: Color = Color(HealEffect.MID, LINE_ALPHA)
		if phase < 1.0:
			color = HealEffect.BRIGHT
		elif phase < 2.0:
			color = HealEffect.LIGHT
		draw_rect(Rect2(points[i], Vector2.ONE), color)
