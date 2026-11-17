class_name RadarConsole
extends OfficeObject

# Mesa holográfica de Sectores en la consola inclinada: abre la selección de nivel. La mesa es parte
# de center_static.png; su pantalla (shader office_radar en `Screen`) enseña la pantalla de Sectores
# de verdad (la textura de RadarViewport, que le pasa MainMenu), chafada en el trapecio. Se pulsa en
# el contorno de la mesa, no en toda su caja.
#
# Al abrir Sectores, MainMenu acerca la oficina tal cual hacia la pantalla (get_screen_rect()) y al final
# aparece encima la mesa de cerca (SectorsCloseUp).

@onready var screen: ColorRect = $Screen

# Pantalla de la mesa (trapecio) en coordenadas de la vista.
var _table: Dictionary
var _outline: PackedVector2Array

func _ready() -> void:
	super()
	var layout: Dictionary = OfficeLayout.CENTER
	_table = layout.table_in
	for point: Array in layout.table_out:
		_outline.append(to_local_point(Vector2(point[0], point[1])))
	_apply_quad()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _outline)

# Los corchetes siguen el contorno inclinado de la mesa.
func hover_quad() -> PackedVector2Array:
	return _outline

## Pantalla de la mesa en coordenadas de la vista: de arriba abajo y, a lo ancho, lo que ocupa su fila
## del medio (el trapecio es más estrecho arriba). MainMenu se acerca a ella.
func get_screen_rect() -> Rect2:
	var left: float = lerpf(_table.tl, _table.bl, 0.5)
	var right: float = lerpf(_table.tr, _table.br, 0.5)
	return Rect2(left, _table.top, right - left, _table.bot - _table.top + 1.0)

## Lo que enseña la pantalla (la pantalla de Sectores): qué parte (en UV).
func set_screen_texture(texture: Texture2D, crop: Rect2) -> void:
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"screen_texture", texture)
	material.set_shader_parameter(&"crop", Vector4(crop.position.x, crop.position.y, crop.size.x, crop.size.y))

# Coloca `Screen` en la caja del trapecio y le pasa al shader los extremos.
func _apply_quad() -> void:
	var left: float = minf(_table.tl, _table.bl)
	var box: Rect2 = Rect2(to_local_point(Vector2(left, _table.top)), Vector2(maxf(_table.tr, _table.br) - left, _table.bot - _table.top + 1.0))
	screen.position = box.position
	screen.size = box.size
	var material: ShaderMaterial = screen.material as ShaderMaterial
	material.set_shader_parameter(&"rect_size", box.size)
	material.set_shader_parameter(&"top_span", Vector2(_table.tl - left, _table.tr - left))
	material.set_shader_parameter(&"bottom_span", Vector2(_table.bl - left, _table.br - left))
