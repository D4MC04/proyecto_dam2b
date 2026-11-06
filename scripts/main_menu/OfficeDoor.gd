class_name OfficeDoor
extends OfficeObject

# Puerta de la oficina: sale del juego. El marco, empotrado en la pared, es parte de left_static.png;
# las hojas, la luz del pasillo y las luces encendidas son PNG de assets/sprites/office/ en los hijos
# (todos del tamaño de la vista, colocados en su origen). `Plane` recorta las hojas y el pasillo con
# la forma del hueco (clip_children), así que al apartarse no pisan el marco.
#
# Con el ratón encima solo se entreabre (cada hoja se aparta `slide` px): por la rendija en zigzag se
# ve la luz del pasillo y una luz tenue cae en el suelo, tan ancha como la rendija; se encienden la
# luz del marco y la pantallita del panel de acceso. Cerrada, la junta brilla y por las franjas de
# luz de las hojas sube y baja un pulso. Al pulsarla se entreabre igual y emite `opened`.

signal opened

# Segundos que tarda en entreabrirse o cerrarse.
const OPEN_TIME: float = 0.35
const SPILL_LEVEL: float = 6.0
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const PULSE_HEIGHT: int = 24

@onready var plane: TextureRect = $Plane
@onready var leaf_left: TextureRect = $Plane/LeafLeft
@onready var leaf_right: TextureRect = $Plane/LeafRight
@onready var seam: TextureRect = $Seam
@onready var frame_glow: TextureRect = $FrameGlow
@onready var access_light: TextureRect = $AccessLight
@onready var lights: Control = $Lights

var _open: float = 0.0
var _leaving: bool = false
var _opened: bool = false
var _door: Dictionary

func _ready() -> void:
	super()
	_door = OfficeLayout.LEFT.door
	for child: Control in [plane, seam, frame_glow, access_light, lights]:
		child.position = -position
	lights.draw.connect(_draw_lights)

func _process(delta: float) -> void:
	super(delta)
	var target: float = 1.0 if (_leaving or hovered) else 0.0
	_open = move_toward(_open, target, delta / OPEN_TIME)
	var slide: int = roundi(_open * float(_door.slide))
	leaf_left.position.x = -slide
	leaf_right.position.x = slide
	seam.visible = slide == 0
	var lit: bool = hovered or _open > 0.0
	frame_glow.visible = lit
	access_light.visible = lit
	lights.queue_redraw()
	# Al salir se queda entreabierta: `opened` se emite una sola vez.
	if _leaving and not _opened and _open >= 1.0:
		_opened = true
		opened.emit()

## Entreabre la puerta; al acabar emite `opened`.
func open_fully() -> void:
	_leaving = true

# Encima de todo, en coordenadas de la vista: luz del suelo, pulso de las franjas y barra de estado.
func _draw_lights() -> void:
	var slide: int = roundi(_open * float(_door.slide))
	if slide > 0:
		_draw_spill(slide)
	else:
		var k: float = 0.5 + sin(time * 2.0) * 0.5
		for strip: Array in _door.strips:
			var r: Rect2i = Rect2i(strip[0], strip[1], strip[2], strip[3])
			OfficePaint.rect(lights, r, OfficePaint.CYAN_DARK)
			var y: int = r.position.y + roundi(k * (r.size.y - PULSE_HEIGHT))
			OfficePaint.rect(lights, Rect2i(r.position.x, y, r.size.x, PULSE_HEIGHT), OfficePaint.CYAN)
			OfficePaint.rect(lights, Rect2i(r.position.x + 1, y + 8, r.size.x - 2, 8), OfficePaint.CYAN_LIGHT)
	# Barra de estado de encima de la puerta: un tramo de luz la recorre (verde con la puerta activa).
	var bar: Array = _door.bar
	var lit: bool = hovered or _open > 0.0
	OfficePaint.rect(lights, Rect2i(bar[0], bar[1], bar[2], bar[3]), OfficePaint.GREEN_DARK if lit else OfficePaint.SCREEN_LINE)
	var run: int = int(fmod(time * (120.0 if lit else 40.0), bar[2] + 24.0)) - 24
	var a: int = maxi(0, run)
	var b: int = mini(bar[2], run + 24)
	if b > a:
		OfficePaint.rect(lights, Rect2i(bar[0] + a, bar[1], b - a, bar[3]), OfficePaint.GREEN if lit else OfficePaint.CYAN_DARK)

# Luz tenue en el suelo: sale de la rendija hacia el jugador y se apaga al alejarse, en tramado.
func _draw_spill(slide: int) -> void:
	var floor_y: int = _door.floor
	var seam_x: int = _door.seam_x
	var vanish: Vector2 = Vector2(480, 300)
	var k: float = (540.0 - vanish.y) / (floor_y - vanish.y)
	var near_left: float = vanish.x + (seam_x - slide - vanish.x) * k
	var near_right: float = vanish.x + (seam_x + 1 + slide - vanish.x) * k
	for y: int in range(floor_y, 540):
		var t: float = float(y - floor_y) / (540 - floor_y)
		var x0: int = roundi(lerpf(seam_x - slide, near_left, t))
		var x1: int = roundi(lerpf(seam_x + 1 + slide, near_right, t))
		var level: float = (1.0 - t) * SPILL_LEVEL * _open
		for x: int in range(x0, x1):
			if BAYER[(y & 3) * 4 + (x & 3)] < level:
				OfficePaint.rect(lights, Rect2i(x, y, 1, 1), OfficePaint.SCREEN_LINE)
