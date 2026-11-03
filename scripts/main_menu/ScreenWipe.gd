extends CanvasLayer
class_name ScreenWipe

# Transición de entrada al juego desde la pantalla de inicio: un tramado de celdas que tapa la
# pantalla desde un punto con un frente cian (screen_wipe.gdshader) y, tras cambiar de escena, la
# destapa desde el centro. Vive en la raíz del árbol, no en la escena, así que sobrevive al cambio;
# al destapar se libera sola. Bloquea el ratón mientras está.

const SHADER: Shader = preload("res://resources/shaders/screen_wipe.gdshader")
const LAYER := 100

var _rect: ColorRect
var _material: ShaderMaterial

func _init() -> void:
	layer = LAYER
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_rect)

func _ready() -> void:
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Tapa la pantalla desde `origin` (píxeles lógicos) hacia fuera.
func cover(origin: Vector2, duration: float) -> void:
	_setup(origin, false)
	await _run(0.0, 1.0, duration)

## Destapa la pantalla desde `origin` hacia fuera y se libera.
func uncover(origin: Vector2, duration: float) -> void:
	_setup(origin, true)
	await _run(1.0, 0.0, duration)
	queue_free()

func _setup(origin: Vector2, reverse_order: bool) -> void:
	_material.set_shader_parameter(&"rect_size", get_viewport().get_visible_rect().size)
	_material.set_shader_parameter(&"origin", origin)
	_material.set_shader_parameter(&"reverse_order", reverse_order)

func _run(from: float, to: float, duration: float) -> void:
	_material.set_shader_parameter(&"progress", from)
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: _material.set_shader_parameter(&"progress", value),
			from, to, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
