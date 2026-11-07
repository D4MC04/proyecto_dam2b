class_name RadarConsole
extends OfficeObject

# Mesa holográfica de Sectores en la consola inclinada: abre la selección de nivel. La mesa es parte
# de center_static.png; aquí se anima la pantalla (shader office_radar en `Screen`) y se pintan
# encima (`Blips`) la estación y los contactos de `sector_radar`, que destellan al pasar el barrido.
# El shader pone la niebla fuera del alcance. Con el ratón encima el barrido va más deprisa. Se
# pulsa en el contorno de la mesa, no en toda su caja.
#
# Al abrir Sectores, MainMenu acerca la oficina y llama a set_zoom(): el trapecio se endereza hasta
# un rectángulo y la pantalla pasa a enseñar la textura del radar real (set_radar_texture).

# Vueltas del barrido por segundo (en radianes), sin y con el ratón encima.
const SWEEP_SPEED: float = 1.1
const SWEEP_SPEED_HOT: float = 2.4
# Radio del disco en coordenadas del radar (x de -1,5 a 1,5 e y de -1 a 1); es `radius` del shader.
const DISK: float = 0.78
# Tiempo (en radianes de barrido) que un eco sigue encendido tras pasar el barrido.
const BLIP_FRESH: float = 1.2

## Radar de la pantalla de Sectores: de él salen los contactos y el alcance.
@export var sector_radar: SectorRadar

@onready var screen: ColorRect = $Screen
@onready var blips: Control = $Blips

var _sweep: float = 0.0
# Pantalla de la mesa (trapecio) en coordenadas de la vista, y la que se pinta ahora (con el zoom).
var _table: Dictionary
var _quad: Dictionary
var _outline: PackedVector2Array

func _ready() -> void:
	super()
	var layout: Dictionary = OfficeLayout.CENTER
	_table = layout.table_in
	_quad = _table.duplicate()
	for point: Array in layout.table_out:
		_outline.append(to_local_point(Vector2(point[0], point[1])))
	(screen.material as ShaderMaterial).set_shader_parameter(&"radius", DISK)
	_apply_quad()
	blips.draw.connect(_draw_blips)

func _process(delta: float) -> void:
	super(delta)
	_sweep = fmod(_sweep + delta * (SWEEP_SPEED_HOT if hovered else SWEEP_SPEED), TAU)
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"sweep", _sweep)
	if sector_radar:
		material.set_shader_parameter(&"range_radius", sector_radar.get_range() * DISK)
	blips.queue_redraw()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _outline)

## Centro del disco de la mesa (fila del medio), en coordenadas de la vista.
func get_disk_center() -> Vector2:
	var span: Vector2 = Vector2(lerpf(_table.tl, _table.bl, 0.5), lerpf(_table.tr, _table.br, 0.5))
	return Vector2((span.x + span.y) / 2.0, (_table.top + _table.bot) / 2.0)

## Ancho de la pantalla de la mesa en la fila del medio.
func get_disk_width() -> float:
	return lerpf(_table.tr, _table.br, 0.5) - lerpf(_table.tl, _table.bl, 0.5)

## Textura del radar real y dónde cae su disco: centro (en UV) y UV por unidad de radar.
func set_radar_texture(texture: Texture2D, center_uv: Vector2, uv_scale: Vector2) -> void:
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"radar_texture", texture)
	material.set_shader_parameter(&"radar_center_uv", center_uv)
	material.set_shader_parameter(&"radar_uv_scale", uv_scale)

## Zoom de 0 (la mesa) a 1 (pantalla enderezada en `flat`, en coordenadas de la vista, enseñando
## el radar real).
func set_zoom(amount: float, flat: Rect2) -> void:
	_quad = {
		"top": lerpf(_table.top, flat.position.y, amount),
		"bot": lerpf(_table.bot, flat.end.y - 1.0, amount),
		"tl": lerpf(_table.tl, flat.position.x, amount),
		"tr": lerpf(_table.tr, flat.end.x, amount),
		"bl": lerpf(_table.bl, flat.position.x, amount),
		"br": lerpf(_table.br, flat.end.x, amount),
	}
	_apply_quad()
	var reveal: float = smoothstep(0.15, 0.85, amount)
	(screen.material as ShaderMaterial).set_shader_parameter(&"reveal", reveal)
	blips.modulate.a = 1.0 - reveal

# Coloca `Screen` en la caja del trapecio actual y le pasa al shader los extremos.
func _apply_quad() -> void:
	var left: float = minf(_quad.tl, _quad.bl)
	var box: Rect2 = Rect2(to_local_point(Vector2(left, _quad.top)), Vector2(maxf(_quad.tr, _quad.br) - left, _quad.bot - _quad.top + 1.0))
	screen.position = box.position
	screen.size = box.size
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"rect_size", box.size)
	material.set_shader_parameter(&"top_span", Vector2(_quad.tl - left, _quad.tr - left))
	material.set_shader_parameter(&"bottom_span", Vector2(_quad.bl - left, _quad.br - left))

# Estación en el centro (cruz cian) y un eco por contacto visible, del color de su estado.
func _draw_blips() -> void:
	var center: Vector2i = _radar_to_local(Vector2.ZERO)
	OfficePaint.rect(blips, Rect2i(center.x - 3, center.y, 7, 1), OfficePaint.CYAN)
	OfficePaint.rect(blips, Rect2i(center.x, center.y - 2, 1, 5), OfficePaint.CYAN)
	OfficePaint.rect(blips, Rect2i(center.x - 1, center.y - 1, 3, 3), OfficePaint.CYAN_LIGHT)
	if sector_radar == null:
		return
	for contact: SectorRadar.Contact in sector_radar.get_visible_contacts():
		var bearing: float = deg_to_rad(contact.bearing)
		_draw_blip(Vector2(sin(bearing), -cos(bearing)) * contact.distance * DISK, _blip_colors(contact))

# Colores (oscuro, normal y claro) del eco según el estado, como en SectorRadar.
func _blip_colors(contact: SectorRadar.Contact) -> Array[Color]:
	if contact.index == sector_radar.selected_index:
		var blue: Color = SectorRadar.SELECTED_COLOR
		return [blue.darkened(0.4), blue, blue.lightened(0.5)]
	match contact.state:
		SectorRadar.ContactState.COMPLETED:
			return [OfficePaint.GREEN_DARK, OfficePaint.GREEN, OfficePaint.GREEN_LIGHT]
		SectorRadar.ContactState.UNKNOWN:
			return [OfficePaint.RED_DARK, OfficePaint.RED, OfficePaint.RED_LIGHT]
	return [OfficePaint.AMBER_DARK, OfficePaint.AMBER, OfficePaint.AMBER_LIGHT]

# Eco: cruz; los recién barridos, más claros y con una columna de luz encima.
func _draw_blip(blip: Vector2, colors: Array[Color]) -> void:
	var since: float = fposmod(_sweep - atan2(blip.y, blip.x), TAU)
	var at: Vector2i = _radar_to_local(blip)
	var fresh: bool = since < BLIP_FRESH
	OfficePaint.rect(blips, Rect2i(at.x - 2, at.y - 1, 5, 3), OfficePaint.OUTLINE)
	OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - 2, 3, 5), OfficePaint.OUTLINE)
	OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - 1, 3, 3), colors[1] if fresh else colors[0])
	if since < 0.4:
		OfficePaint.rect(blips, Rect2i(at.x, at.y - 1, 1, 1), colors[2])
	if fresh:
		var height: int = 9 + roundi(sin(time * 3.0 + blip.x * 5.0))
		OfficePaint.rect(blips, Rect2i(at.x, at.y - height, 1, height - 2), Color(colors[1], 0.45))
		OfficePaint.rect(blips, Rect2i(at.x - 2, at.y - height - 3, 5, 1), colors[1])
		OfficePaint.rect(blips, Rect2i(at.x - 1, at.y - height - 2, 3, 1), colors[1])
		OfficePaint.rect(blips, Rect2i(at.x, at.y - height - 1, 1, 1), colors[2])

# Punto del radar en coordenadas locales, siguiendo el trapecio de la pantalla.
func _radar_to_local(point: Vector2) -> Vector2i:
	var v: float = point.y / 2.0 + 0.5
	var u: float = point.x / 3.0 + 0.5
	var span: Vector2 = OfficePaint.quad_span(_quad, roundi(v * (_quad.bot - _quad.top)))
	var view_point: Vector2 = Vector2(lerpf(span.x, span.y, u), lerpf(_quad.top, _quad.bot, v))
	return Vector2i(to_local_point(view_point).round())
