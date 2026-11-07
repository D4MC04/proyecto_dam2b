class_name RadarConsole
extends OfficeObject

# Mesa holográfica de Sectores en la consola inclinada: abre la selección de nivel. La mesa es parte
# de center_static.png; su pantalla (shader office_radar en `Screen`) enseña la pantalla de Sectores
# de verdad (la textura de RadarViewport, que le pasa MainMenu), chafada en el trapecio. Se pulsa en
# el contorno de la mesa, no en toda su caja.
#
# Al abrir Sectores, MainMenu acerca la oficina y llama a set_zoom(): el trapecio se endereza hasta
# quedar encima de la pantalla de Sectores.

@onready var screen: ColorRect = $Screen

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
	_apply_quad()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _outline)

## Centro de la pantalla de la mesa (fila del medio), en coordenadas de la vista.
func get_screen_center() -> Vector2:
	var span: Vector2 = Vector2(lerpf(_table.tl, _table.bl, 0.5), lerpf(_table.tr, _table.br, 0.5))
	return Vector2((span.x + span.y) / 2.0, (_table.top + _table.bot) / 2.0)

## Ancho de la pantalla de la mesa en la fila del medio.
func get_screen_width() -> float:
	return lerpf(_table.tr, _table.br, 0.5) - lerpf(_table.tl, _table.bl, 0.5)

## Lo que enseña la pantalla (la pantalla de Sectores) y qué parte (en UV).
func set_screen_texture(texture: Texture2D, crop: Rect2) -> void:
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"screen_texture", texture)
	material.set_shader_parameter(&"crop", Vector4(crop.position.x, crop.position.y, crop.size.x, crop.size.y))

## Zoom de 0 (la mesa) a 1 (pantalla enderezada en `flat`, en coordenadas de la vista).
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
