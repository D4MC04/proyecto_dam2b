class_name OptionsConsole
extends OfficeObject

# Módulo de opciones de la consola inclinada: abre el menú de opciones. El módulo (metal, pantalla
# hundida, tres pomos brillantes y las ranuras de cuatro interruptores) es parte de
# center_static.png. Aquí se pinta la pantalla, que solo enseña el volumen: tres vúmetros con su
# fader, centrados y llevados al trapecio de la pantalla; y las palancas de los interruptores. Con el
# ratón encima los vúmetros bailan más deprisa.

const SEGMENTS := 10
const SEGMENT_HEIGHT := 4
const SEGMENT_GAP := 2
const CHANNEL_WIDTH := 28
const CHANNEL_GAP := 24
# Interruptor bajado (el tercero); los demás, subidos.
const DOWN_SWITCH := 2

var _screen: Dictionary
var _source: Vector2i

func _ready() -> void:
	super()
	_screen = OfficeLayout.CENTER.opt.screen
	_source = OfficePaint.quad_source_size(_screen)

func _draw_object() -> void:
	var origin := Vector2i(-position)
	var w := _source.x
	var h := _source.y
	for y in range(1, h, 2):
		_quad_rect(Rect2i(0, y, w, 1), OfficePaint.SCREEN_DARK, origin)
	var bar_height := SEGMENTS * (SEGMENT_HEIGHT + SEGMENT_GAP) - SEGMENT_GAP
	@warning_ignore("integer_division")
	var x0 := (w - (3 * CHANNEL_WIDTH + 2 * CHANNEL_GAP)) / 2
	@warning_ignore("integer_division")
	var y0 := (h - bar_height) / 2
	var speed := 9.0 if hovered else 7.0
	for channel in 3:
		var x := x0 + channel * (CHANNEL_WIDTH + CHANNEL_GAP)
		var level := 4 + roundi((sin(time * speed + channel * 2.0) * 0.5 + 0.5) * 6.0 + sin(time * 13.0 + channel) * 1.5)
		for segment in SEGMENTS:
			var color := OfficePaint.GREEN if segment < 6 else (OfficePaint.AMBER if segment < 8 else OfficePaint.RED)
			if segment >= level:
				color = color.darkened(0.72)
			var y := y0 + bar_height - SEGMENT_HEIGHT - segment * (SEGMENT_HEIGHT + SEGMENT_GAP)
			_quad_rect(Rect2i(x, y, 12, SEGMENT_HEIGHT), color, origin)
		_quad_rect(Rect2i(x + 19, y0, 3, bar_height), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(x + 20, y0, 1, bar_height), OfficePaint.SCREEN_LINE, origin)
		var fader_y := y0 + roundi((0.5 + sin(time * 0.9 + channel * 1.7) * 0.35) * (bar_height - 8))
		_quad_rect(Rect2i(x + 14, fader_y, 13, 8), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(x + 15, fader_y + 1, 11, 6), OfficePaint.METAL_LIGHT, origin)
		_quad_rect(Rect2i(x + 15, fader_y + 1, 11, 1), OfficePaint.METAL_SHINE, origin)
		_quad_rect(Rect2i(x + 15, fader_y + 3, 11, 2), OfficePaint.CYAN_DARK, origin)
	# Palancas de los interruptores, en sus ranuras.
	var switches: Array = OfficeLayout.CENTER.opt.switches
	for i in switches.size():
		var slot := Vector2i(to_local_point(Vector2(switches[i][0], switches[i][1])))
		var lever_y := slot.y + (16 if i == DOWN_SWITCH else 2)
		OfficePaint.bevel_box(self, Rect2i(slot.x, lever_y, 8, 12), OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL_DARK)
		OfficePaint.rect(self, Rect2i(slot.x + 2, lever_y + 5, 4, 1), OfficePaint.METAL)

func _quad_rect(r: Rect2i, color: Color, origin: Vector2i) -> void:
	OfficePaint.quad_rect(self, _screen, _source, r, color, origin)
