class_name RadarConsole
extends OfficeObject

# Mesa holográfica de Sectores en la consola inclinada: abre la selección de nivel. La mesa es parte
# de center_static.png; aquí se anima la pantalla (shader office_radar en `Screen`) y se pintan
# encima los ecos rojos (`Blips`), que destellan al pasar el barrido. Con el ratón encima el barrido
# va más deprisa. Se pulsa en el contorno de la mesa, no en toda su caja.

# Vueltas del barrido por segundo (en radianes), sin y con el ratón encima.
const SWEEP_SPEED: float = 1.1
const SWEEP_SPEED_HOT: float = 2.4
# Ecos, en coordenadas del radar (x de -1,5 a 1,5 e y de -1 a 1).
const BLIPS: Array[Vector2] = [
	Vector2(0.46, 0.3), Vector2(-0.5, -0.22), Vector2(0.14, -0.56),
	Vector2(-0.2, 0.44), Vector2(0.64, -0.16), Vector2(-0.68, 0.24),
]
# Tiempo (en radianes de barrido) que un eco sigue encendido tras pasar el barrido.
const BLIP_FRESH: float = 1.2

@onready var screen: ColorRect = $Screen
@onready var blips: Control = $Blips

var _sweep: float = 0.0
# Pantalla del radar (trapecio) y contorno de la mesa, en coordenadas locales.
var _quad: Dictionary
var _outline: PackedVector2Array

func _ready() -> void:
	super()
	var layout: Dictionary = OfficeLayout.CENTER
	_quad = layout.table_in
	for point: Array in layout.table_out:
		_outline.append(to_local_point(Vector2(point[0], point[1])))
	var left: int = mini(_quad.tl, _quad.bl)
	var box: Rect2 = Rect2(to_local_point(Vector2(left, _quad.top)), Vector2(maxi(_quad.tr, _quad.br) - left, _quad.bot - _quad.top + 1))
	screen.position = box.position
	screen.size = box.size
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"rect_size", box.size)
	material.set_shader_parameter(&"top_span", Vector2(_quad.tl - left, _quad.tr - left))
	material.set_shader_parameter(&"bottom_span", Vector2(_quad.bl - left, _quad.br - left))
	blips.draw.connect(_draw_blips)

func _process(delta: float) -> void:
	super(delta)
	_sweep = fmod(_sweep + delta * (SWEEP_SPEED_HOT if hovered else SWEEP_SPEED), TAU)
	(screen.material as ShaderMaterial).set_shader_parameter(&"sweep", _sweep)
	blips.queue_redraw()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _outline)

# Los corchetes siguen el contorno inclinado de la mesa.
func hover_quad() -> PackedVector2Array:
	return _outline

# Ecos: cruz roja; los recién barridos, más claros y con una columna de luz encima.
func _draw_blips() -> void:
	for blip: Vector2 in BLIPS:
		var since: float = fposmod(_sweep - atan2(blip.y, blip.x), TAU)
		var at: Vector2i = _radar_to_local(blip)
		var fresh: bool = since < BLIP_FRESH
		OfficePaint.rect(blips, Rect2i(at.x - 2, at.y - 1, 5, 3), OfficePaint.OUTLINE)
		OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - 2, 3, 5), OfficePaint.OUTLINE)
		OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - 1, 3, 3), OfficePaint.RED if fresh else OfficePaint.RED_DARK)
		if since < 0.4:
			OfficePaint.rect(blips, Rect2i(at.x, at.y - 1, 1, 1), OfficePaint.RED_LIGHT)
		if fresh:
			var height: int = 9 + roundi(sin(time * 3.0 + blip.x * 5.0))
			OfficePaint.rect(blips, Rect2i(at.x, at.y - height, 1, height - 2), Color(OfficePaint.RED, 0.45))
			OfficePaint.rect(blips, Rect2i(at.x - 2, at.y - height - 3, 5, 1), OfficePaint.RED)
			OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - height - 2, 3, 1), OfficePaint.RED)
			OfficePaint.rect(blips, Rect2i(at.x, at.y - height - 1, 1, 1), OfficePaint.RED_LIGHT)

# Punto del radar en coordenadas locales, siguiendo el trapecio de la pantalla.
func _radar_to_local(point: Vector2) -> Vector2i:
	var v: float = point.y / 2.0 + 0.5
	var u: float = point.x / 3.0 + 0.5
	var span: Vector2 = OfficePaint.quad_span(_quad, roundi(v * (_quad.bot - _quad.top)))
	var view_point: Vector2 = Vector2(lerpf(span.x, span.y, u), lerpf(_quad.top, _quad.bot, v))
	return Vector2i(to_local_point(view_point).round())
