class_name OptionsConsole
extends OfficeObject

# Módulo de opciones de la consola inclinada: abre el menú de opciones. El módulo (metal, pantalla
# hundida, tres pomos brillantes y las ranuras de cuatro interruptores) es parte de
# center_static.png. Aquí se pinta la pantalla, que solo enseña el volumen: tres vúmetros con su
# fader al lado (con aire entre los dos), centrados y llevados al trapecio de la pantalla; y las
# palancas de los interruptores, inclinadas con la consola en el trapecio de su ranura. Con el ratón
# encima los vúmetros bailan más deprisa.

const SEGMENTS: int = 10
const SEGMENT_HEIGHT: int = 4
const SEGMENT_GAP: int = 2
const METER_WIDTH: int = 12
# Hueco entre el vúmetro y el fader, y ancho del fader.
const FADER_GAP: int = 7
const FADER_WIDTH: int = 13
const CHANNEL_WIDTH: int = METER_WIDTH + FADER_GAP + FADER_WIDTH
const CHANNEL_GAP: int = 20
# Ranura de un interruptor pintada de frente (el trapecio de OfficeLayout la inclina) y su palanca.
const SWITCH_SLOT: Vector2i = Vector2i(8, 30)
const LEVER_HEIGHT: int = 12
# Interruptor bajado (el tercero); los demás, subidos.
const DOWN_SWITCH: int = 2

var _screen: Dictionary
var _source: Vector2i

func _ready() -> void:
	super()
	_screen = OfficeLayout.CENTER.opt.screen
	_source = OfficePaint.quad_source_size(_screen)

func _draw_object() -> void:
	var origin: Vector2i = Vector2i(-position)
	var w: int = _source.x
	var h: int = _source.y
	for y: int in range(1, h, 2):
		_quad_rect(Rect2i(0, y, w, 1), OfficePaint.SCREEN_DARK, origin)
	var bar_height: int = SEGMENTS * (SEGMENT_HEIGHT + SEGMENT_GAP) - SEGMENT_GAP
	@warning_ignore("integer_division")
	var x0: int = (w - (3 * CHANNEL_WIDTH + 2 * CHANNEL_GAP)) / 2
	@warning_ignore("integer_division")
	var y0: int = (h - bar_height) / 2
	var speed: float = 9.0 if hovered else 7.0
	for channel: int in 3:
		var x: int = x0 + channel * (CHANNEL_WIDTH + CHANNEL_GAP)
		var level: int = 4 + roundi((sin(time * speed + channel * 2.0) * 0.5 + 0.5) * 6.0 + sin(time * 13.0 + channel) * 1.5)
		for segment: int in SEGMENTS:
			var color: Color = OfficePaint.GREEN if segment < 6 else (OfficePaint.AMBER if segment < 8 else OfficePaint.RED)
			if segment >= level:
				color = color.darkened(0.72)
			var y: int = y0 + bar_height - SEGMENT_HEIGHT - segment * (SEGMENT_HEIGHT + SEGMENT_GAP)
			_quad_rect(Rect2i(x, y, METER_WIDTH, SEGMENT_HEIGHT), color, origin)
		var fader_x: int = x + METER_WIDTH + FADER_GAP
		_quad_rect(Rect2i(fader_x + 5, y0, 3, bar_height), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(fader_x + 6, y0, 1, bar_height), OfficePaint.SCREEN_LINE, origin)
		var fader_y: int = y0 + roundi((0.5 + sin(time * 0.9 + channel * 1.7) * 0.35) * (bar_height - 8))
		_quad_rect(Rect2i(fader_x, fader_y, FADER_WIDTH, 8), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 1, FADER_WIDTH - 2, 6), OfficePaint.METAL_LIGHT, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 1, FADER_WIDTH - 2, 1), OfficePaint.METAL_SHINE, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 3, FADER_WIDTH - 2, 2), OfficePaint.CYAN_DARK, origin)
	# Palancas de los interruptores, en sus ranuras inclinadas.
	var switches: Array = OfficeLayout.CENTER.opt.switches
	for i: int in switches.size():
		var slot: Dictionary = switches[i]
		var lever_y: int = 16 if i == DOWN_SWITCH else 2
		OfficePaint.quad_bevel_box(self, slot, SWITCH_SLOT, Rect2i(0, lever_y, SWITCH_SLOT.x, LEVER_HEIGHT),
				OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL_DARK, origin)
		OfficePaint.quad_rect(self, slot, SWITCH_SLOT, Rect2i(2, lever_y + 5, 4, 1), OfficePaint.METAL, origin)

# Los corchetes siguen el contorno inclinado del módulo.
func hover_quad() -> PackedVector2Array:
	return to_local_quad(OfficeLayout.CENTER.opt.quad)

func _quad_rect(r: Rect2i, color: Color, origin: Vector2i) -> void:
	OfficePaint.quad_rect(self, _screen, _source, r, color, origin)
