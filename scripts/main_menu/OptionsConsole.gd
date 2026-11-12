class_name OptionsConsole
extends OfficeObject

# Módulo de opciones de la consola inclinada: al pulsarlo, MainMenu se acerca y enseña la consola de
# cerca (OptionsCloseUp), donde se tocan las opciones. El módulo (metal, pantalla hundida, tres pomos
# brillantes y las ranuras de cinco interruptores) es parte de center_static.png. Aquí se pinta lo que
# cambia, con los valores reales de Settings: la pantalla (tres vúmetros con el nivel de su bus y su
# fader al lado, con aire entre los dos, llevados al trapecio de la pantalla), la marca de cada pomo y
# las palancas, inclinadas con la consola en el trapecio de su ranura.

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
const FADER_HEIGHT: int = 8

# Opciones de cada mando, en el orden de la consola (de izquierda a derecha).
const FADERS: Array[StringName] = [&"master_volume", &"music_volume", &"sfx_volume"]
const KNOBS: Array[StringName] = [&"language", &"fullscreen", &"vsync"]
const SWITCHES: Array[StringName] = [&"show_fps", &"show_turret_range", &"show_damage_numbers", &"screen_shake",
		&"pause_on_focus_loss"]
# Vúmetros: dB que caben en la barra y lo que bajan por segundo (en fracción de la barra).
const METER_RANGE_DB: float = 48.0
const METER_FALL: float = 1.5
# Ángulo de cada posición de un pomo (en grados desde arriba): izquierda OFF / ES, derecha ON / EN.
const KNOB_ANGLE: float = 45.0

var _screen: Dictionary
var _source: Vector2i
var _meters: PackedFloat32Array = [0.0, 0.0, 0.0]

func _ready() -> void:
	super()
	_screen = OfficeLayout.CENTER.opt.screen
	_source = OfficePaint.quad_source_size(_screen)

func _process(delta: float) -> void:
	super(delta)
	for i: int in FADERS.size():
		_meters[i] = meter_level(FADERS[i], _meters[i], delta)

## Nivel del vúmetro de un volumen (0 a 1): el pico de su bus, que cae poco a poco desde `shown`.
## Con `muted` se apaga.
static func meter_level(key: StringName, shown: float, delta: float) -> float:
	if Settings.get_value(&"muted"):
		return 0.0
	var bus: int = AudioServer.get_bus_index(Settings.VOLUME_BUSES[key])
	var peak: float = clampf((AudioServer.get_bus_peak_volume_left_db(bus, 0) + METER_RANGE_DB) / METER_RANGE_DB, 0.0, 1.0)
	return maxf(peak, shown - delta * METER_FALL)

## Valores por los que pasa un pomo (izquierda a derecha).
static func knob_values(key: StringName) -> Array:
	return Array(Settings.LANGUAGES) if key == &"language" else [false, true]

## Posición actual de un pomo (índice de knob_values).
static func knob_index(key: StringName) -> int:
	return maxi(knob_values(key).find(Settings.get_value(key)), 0)

## Ángulo del pomo en radianes desde arriba (en sentido horario).
static func knob_angle(key: StringName) -> float:
	var count: int = knob_values(key).size()
	return deg_to_rad(lerpf(-KNOB_ANGLE, KNOB_ANGLE, float(knob_index(key)) / maxf(count - 1, 1.0)))

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
	for channel: int in FADERS.size():
		var x: int = x0 + channel * (CHANNEL_WIDTH + CHANNEL_GAP)
		var level: int = roundi(_meters[channel] * SEGMENTS)
		for segment: int in SEGMENTS:
			var color: Color = OfficePaint.GREEN if segment < 6 else (OfficePaint.AMBER if segment < 8 else OfficePaint.RED)
			if segment >= level:
				color = color.darkened(0.72)
			var y: int = y0 + bar_height - SEGMENT_HEIGHT - segment * (SEGMENT_HEIGHT + SEGMENT_GAP)
			_quad_rect(Rect2i(x, y, METER_WIDTH, SEGMENT_HEIGHT), color, origin)
		var fader_x: int = x + METER_WIDTH + FADER_GAP
		_quad_rect(Rect2i(fader_x + 5, y0, 3, bar_height), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(fader_x + 6, y0, 1, bar_height), OfficePaint.SCREEN_LINE, origin)
		var volume: float = Settings.get_value(FADERS[channel])
		var fader_y: int = y0 + roundi((1.0 - volume) * (bar_height - FADER_HEIGHT))
		_quad_rect(Rect2i(fader_x, fader_y, FADER_WIDTH, FADER_HEIGHT), OfficePaint.OUTLINE, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 1, FADER_WIDTH - 2, 6), OfficePaint.METAL_LIGHT, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 1, FADER_WIDTH - 2, 1), OfficePaint.METAL_SHINE, origin)
		_quad_rect(Rect2i(fader_x + 1, fader_y + 3, FADER_WIDTH - 2, 2), OfficePaint.CYAN_DARK, origin)
	# Marca de cada pomo, hacia su posición.
	var knobs: Array = OfficeLayout.CENTER.opt.knobs
	for i: int in knobs.size():
		var center: Vector2i = Vector2i(to_local_point(Vector2(knobs[i][0], knobs[i][1])))
		var tip: Vector2i = center + Vector2i((Vector2.UP * 8.0).rotated(knob_angle(KNOBS[i])).round())
		OfficePaint.line(self, center, tip, OfficePaint.OUTLINE)
		OfficePaint.line(self, center + Vector2i.RIGHT, tip + Vector2i.RIGHT, OfficePaint.OUTLINE)
	# Palancas de los interruptores, en sus ranuras inclinadas: arriba ON, abajo OFF.
	var switches: Array = OfficeLayout.CENTER.opt.switches
	for i: int in switches.size():
		var slot: Dictionary = switches[i]
		var lever_y: int = 2 if Settings.get_value(SWITCHES[i]) else 16
		OfficePaint.quad_bevel_box(self, slot, SWITCH_SLOT, Rect2i(0, lever_y, SWITCH_SLOT.x, LEVER_HEIGHT),
				OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL_DARK, origin)
		OfficePaint.quad_rect(self, slot, SWITCH_SLOT, Rect2i(2, lever_y + 5, 4, 1), OfficePaint.METAL, origin)

# Los corchetes siguen el contorno inclinado del módulo.
func hover_quad() -> PackedVector2Array:
	return to_local_quad(OfficeLayout.CENTER.opt.quad)

func _quad_rect(r: Rect2i, color: Color, origin: Vector2i) -> void:
	OfficePaint.quad_rect(self, _screen, _source, r, color, origin)
