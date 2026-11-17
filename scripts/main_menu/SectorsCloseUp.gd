class_name SectorsCloseUp
extends Control

# Mesa del radar de cerca: MainMenu se acerca a la mesa de la oficina (RadarConsole) y, al final del
# zoom, aparece esta encima con un fundido, de frente y nítida, como la consola de opciones de cerca.
# Se dibuja como la mesa de center_static.png (gen_center.py › build_table) a PIXEL px por píxel: el
# mismo bisel de metal, los proyectores ámbar de las esquinas y los pilotos cian de arriba. Dentro,
# `Screen` (shader office_radar, sin trapecio) pinta la cuadrícula de la pantalla y encima la textura
# de RadarViewport, así que mientras la pantalla de Sectores sigue ahí (durante el fundido) ya se ve
# en su sitio; al acabar, MainMenu pone la pantalla de Sectores encima, igual.

# Tamaño en píxeles del menú de cada píxel de la mesa: el de la mesa de la oficina al final del zoom
# (más alto que ancho, porque la vista se inclina hacia la mesa), para que su bisel coincida con este.
const PIXEL: Vector2i = Vector2i(2, 3)
# Bisel de la mesa desde fuera hacia la pantalla: (luz arriba e izquierda, sombra abajo y derecha).
const PROFILE: Array[Array] = [
	[OfficePaint.OUTLINE, OfficePaint.OUTLINE],
	[OfficePaint.OUTLINE, OfficePaint.OUTLINE],
	[OfficePaint.METAL_SHINE, OfficePaint.METAL],
	[OfficePaint.METAL_LIGHT, OfficePaint.METAL_DARK],
	[OfficePaint.METAL, OfficePaint.METAL],
	[OfficePaint.METAL, OfficePaint.METAL],
	[OfficePaint.METAL_LIGHT, OfficePaint.METAL],
	[OfficePaint.METAL, OfficePaint.METAL],
	[OfficePaint.METAL, OfficePaint.METAL],
	[OfficePaint.METAL_DARK, OfficePaint.METAL_DARK],
	[OfficePaint.METAL_DARK, OfficePaint.METAL_DARK],
	[OfficePaint.WALL_LIGHT, OfficePaint.WALL_LIGHT],
	[OfficePaint.OUTLINE, OfficePaint.OUTLINE],
	[OfficePaint.OUTLINE, OfficePaint.OUTLINE],
]
# Proyector de las esquinas (12x8 píxeles de la mesa), como EMIT en gen_center.py.
const PROJECTOR: Array[String] = [
	"oooooooooooo",
	"ommmmmmmmmmo",
	"omhaaaaaahso",
	"omaccccccaso",
	"omacbbbbcaso",
	"omaccccccaso",
	"omssssssssso",
	"oooooooooooo",
]
const PROJECTOR_COLORS: Dictionary[String, Color] = {
	"o": OfficePaint.OUTLINE, "m": OfficePaint.METAL_LIGHT, "h": OfficePaint.METAL_SHINE,
	"a": OfficePaint.AMBER_DARK, "c": OfficePaint.AMBER, "b": OfficePaint.AMBER_LIGHT, "s": OfficePaint.METAL_DARK,
}
# Pilotos de arriba (en píxeles de la mesa): tamaño, separación, hueco a los lados y fila.
const LED_SIZE: Vector2i = Vector2i(8, 2)
const LED_STEP: int = 22
const LED_SIDE: int = 30
const LED_ROW: int = 4

@onready var screen: ColorRect = $Screen

# Pantalla (dentro del bisel) y mesa entera, en píxeles del menú.
var _screen_rect: Rect2i
var _body: Rect2i

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Coloca la pantalla de la mesa en `rect` (en píxeles del menú; el bisel va por fuera) y le pasa la
## textura que enseña: `texture` es la vista entera (`view_size`), de la que se ve la parte de `rect`.
func set_screen(rect: Rect2, texture: Texture2D, view_size: Vector2) -> void:
	_screen_rect = Rect2i(rect.position.round(), rect.size.round())
	_body = _screen_rect.grow_individual(PROFILE.size() * PIXEL.x, PROFILE.size() * PIXEL.y,
			PROFILE.size() * PIXEL.x, PROFILE.size() * PIXEL.y)
	screen.position = Vector2(_screen_rect.position)
	screen.size = Vector2(_screen_rect.size)
	var material: ShaderMaterial = screen.material as ShaderMaterial
	var size: Vector2 = Vector2(_screen_rect.size)
	material.set_shader_parameter(&"rect_size", size)
	material.set_shader_parameter(&"top_span", Vector2(0.0, size.x))
	material.set_shader_parameter(&"bottom_span", Vector2(0.0, size.x))
	material.set_shader_parameter(&"screen_texture", texture)
	material.set_shader_parameter(&"crop", Vector4(rect.position.x / view_size.x, rect.position.y / view_size.y,
			rect.size.x / view_size.x, rect.size.y / view_size.y))
	queue_redraw()

func _draw() -> void:
	for i: int in PROFILE.size():
		var ring: Rect2i = _body.grow_individual(-i * PIXEL.x, -i * PIXEL.y, -i * PIXEL.x, -i * PIXEL.y)
		var light: Color = PROFILE[i][0]
		var shadow: Color = PROFILE[i][1]
		OfficePaint.rect(self, Rect2i(ring.position.x, ring.end.y - PIXEL.y, ring.size.x, PIXEL.y), shadow)
		OfficePaint.rect(self, Rect2i(ring.end.x - PIXEL.x, ring.position.y, PIXEL.x, ring.size.y), shadow)
		OfficePaint.rect(self, Rect2i(ring.position.x, ring.position.y, ring.size.x - PIXEL.x, PIXEL.y), light)
		OfficePaint.rect(self, Rect2i(ring.position.x, ring.position.y, PIXEL.x, ring.size.y - PIXEL.y), light)
	var projector_size: Vector2i = Vector2i(PROJECTOR[0].length(), PROJECTOR.size()) * PIXEL
	for corner: Vector2i in [
			_body.position + PIXEL,
			Vector2i(_body.end.x - PIXEL.x - projector_size.x, _body.position.y + PIXEL.y),
			Vector2i(_body.position.x + PIXEL.x, _body.end.y - PIXEL.y - projector_size.y),
			_body.end - PIXEL - projector_size]:
		_draw_projector(corner)
	_draw_leds()

func _draw_projector(at: Vector2i) -> void:
	for y: int in PROJECTOR.size():
		for x: int in PROJECTOR[y].length():
			OfficePaint.rect(self, Rect2i(at + Vector2i(x, y) * PIXEL, PIXEL), PROJECTOR_COLORS[PROJECTOR[y][x]])

# Fila de pilotos cian encendidos en el bisel de arriba, centrada entre los proyectores.
@warning_ignore("integer_division")
func _draw_leds() -> void:
	var width: int = _body.size.x / PIXEL.x - 2 * LED_SIDE
	if width < LED_SIZE.x:
		return
	var count: int = (width - LED_SIZE.x) / LED_STEP + 1
	var first: int = _body.position.x + (_body.size.x - ((count - 1) * LED_STEP + LED_SIZE.x) * PIXEL.x) / 2
	var y: int = _body.position.y + LED_ROW * PIXEL.y
	for i: int in count:
		var led: Rect2i = Rect2i(Vector2i(first + i * LED_STEP * PIXEL.x, y), LED_SIZE * PIXEL)
		OfficePaint.rect(self, led.grow_individual(PIXEL.x, PIXEL.y, PIXEL.x, PIXEL.y), OfficePaint.OUTLINE)
		OfficePaint.rect(self, led, OfficePaint.CYAN)
