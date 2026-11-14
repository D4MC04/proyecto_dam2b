class_name TurnEdges
extends Control

# Giro de la silla con el ratón, sin flechas: cada borde de la pantalla con una vista detrás tiene un
# brillo cian muy tenue que late; al acercar el ratón se aviva, y si se deja en los últimos EDGE_ZONE
# px durante DWELL_TIME se enciende del todo y gira. Para volver a girar hay que sacar el ratón de
# esa zona, así no se encadenan giros. Sin paneles, zoom ni salto (can_turn) no pinta nada.
# No está escalado con la oficina: pinta en píxeles de la pantalla y no recibe el ratón.

signal turn_requested(step: int)

## Zona del borde donde hay que dejar el ratón para girar.
const EDGE_ZONE: float = 12.0
## Distancia al borde a la que empieza a avivarse el brillo.
const EDGE_HINT: float = 90.0
## Segundos con el ratón en la zona hasta que gira.
const DWELL_TIME: float = 0.35
const GLOW_WIDTH: int = 56

## Devuelve true si ahora se puede girar.
var can_turn: Callable = func() -> bool: return true
var can_turn_left: bool = true
var can_turn_right: bool = true

# Por lado (0 izquierda, 1 derecha): carga del giro (0 a 1) y cercanía del ratón (0 a 1).
var _charge: Array[float] = [0.0, 0.0]
var _proximity: Array[float] = [0.0, 0.0]
var _armed: bool = true
var _active: bool = false
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_time += delta
	_active = can_turn.call()
	var mouse: Vector2 = get_local_mouse_position()
	var inside: bool = _active and Rect2(Vector2.ZERO, size).has_point(mouse)
	for side: int in 2:
		var allowed: bool = inside and (can_turn_left if side == 0 else can_turn_right)
		var dist: float = mouse.x if side == 0 else size.x - 1.0 - mouse.x
		_proximity[side] = clampf(1.0 - dist / EDGE_HINT, 0.0, 1.0) if allowed else 0.0
		if allowed and _armed and dist < EDGE_ZONE:
			_charge[side] = minf(_charge[side] + delta / DWELL_TIME, 1.0)
			if _charge[side] >= 1.0:
				_charge[side] = 0.0
				_armed = false
				turn_requested.emit(-1 if side == 0 else 1)
		else:
			_charge[side] = maxf(_charge[side] - delta / DWELL_TIME * 2.0, 0.0)
	if not inside or (mouse.x >= EDGE_ZONE and mouse.x < size.x - EDGE_ZONE):
		_armed = true
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	for side: int in 2:
		if (can_turn_left if side == 0 else can_turn_right):
			_draw_glow(side)

# Brillo que sale del borde hacia dentro, con caída cuadrática.
func _draw_glow(side: int) -> void:
	var pulse: float = 0.05 + 0.03 * sin(_time * 2.5)
	var strength: float = maxf(pulse, maxf(_proximity[side] * 0.35, _charge[side] * 0.8))
	for i: int in GLOW_WIDTH:
		var glow: Color = OfficePaint.CYAN
		glow.a = strength * pow(1.0 - float(i) / GLOW_WIDTH, 2.0)
		var x: int = i if side == 0 else int(size.x) - 1 - i
		OfficePaint.rect(self, Rect2i(x, 0, 1, int(size.y)), glow)
