class_name OptionsCloseUp
extends Control

# Consola de opciones de cerca: el menú de opciones del menú principal. MainMenu se acerca a la consola
# de la oficina (OptionsConsole) y, al final del zoom, aparece esta, de frente y a resolución
# completa, centrada en la vista. Lo fijo es options_close.png (lo genera make_office.py, con las
# posiciones en OfficeLayout.CENTER.opt_close); aquí se pintan los mandos con los valores de Settings
# y se tocan con el ratón: faders (arrastrar o rueda), pomos (clic o rueda), palancas y el pulsador
# de silenciar (clic). La pantallita dice qué es y cuánto vale el mando que hay bajo el ratón.
# "Volver", Escape (lo lleva MainMenu) o un clic fuera de la consola emiten back_pressed.

signal back_pressed

enum Kind { FADER, KNOB, SWITCH, MUTE, BACK }

const BODY: Texture2D = preload("res://assets/sprites/office/options_close.png")
const VIEW_SIZE: Vector2i = Vector2i(960, 540)
const BIG_TEXT: int = 32
# Faders de la pantalla: segmentos del vúmetro, tamaño del tirador y separación de los canales.
const SEGMENTS: int = 14
const SEGMENT_HEIGHT: int = 8
const SEGMENT_GAP: int = 4
const METER_WIDTH: int = 40
const CAP_SIZE: Vector2i = Vector2i(40, 20)
# Hueco entre el vúmetro y el carril del fader (como en la consola pequeña).
const FADER_GAP: int = 24
const CHANNEL_WIDTH: int = METER_WIDTH + FADER_GAP + CAP_SIZE.x
const CHANNEL_GAP: int = 80
const VOLUME_STEP: float = 0.05
# Palancas: alto de la palanca dentro de su ranura.
const LEVER_HEIGHT: int = 32

# Nombre de cada opción en la pantallita (las claves de OptionsMenu).
const NAMES: Dictionary[StringName, String] = {
	&"master_volume": "OPT_MASTER",
	&"music_volume": "OPT_MUSIC",
	&"sfx_volume": "OPT_SFX",
	&"muted": "OPT_MUTE",
	&"language": "OPT_LANGUAGE",
	&"fullscreen": "OPT_FULLSCREEN",
	&"vsync": "VSync",
	&"show_fps": "OPT_SHOW_FPS",
	&"show_turret_range": "OPT_TURRET_RANGE",
	&"show_damage_numbers": "OPT_DAMAGE_NUMBERS",
	&"screen_shake": "OPT_SCREEN_SHAKE",
	&"pause_on_focus_loss": "OPT_PAUSE_ON_FOCUS_LOSS",
}

var _layout: Dictionary = OfficeLayout.CENTER.opt_close
# Esquina de la consola en la vista (centrada).
var _origin: Vector2i
var _bar_height: int = SEGMENTS * (SEGMENT_HEIGHT + SEGMENT_GAP) - SEGMENT_GAP
var _bar_top: int
var _channel_x: int
# Mandos: {kind, key, rect (en coordenadas de la consola)}.
var _controls: Array[Dictionary] = []
var _hovered: int = -1
var _dragging: int = -1
var _meters: PackedFloat32Array = [0.0, 0.0, 0.0]
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var body_size: Vector2i = Vector2i(_layout.size[0], _layout.size[1])
	@warning_ignore("integer_division")
	_origin = (VIEW_SIZE - body_size) / 2
	var screen: Rect2i = _rect(_layout.screen)
	@warning_ignore("integer_division")
	_channel_x = screen.position.x + (screen.size.x - (3 * CHANNEL_WIDTH + 2 * CHANNEL_GAP)) / 2
	@warning_ignore("integer_division")
	_bar_top = screen.position.y + (screen.size.y - _bar_height) / 2
	for i: int in OptionsConsole.FADERS.size():
		_add(Kind.FADER, OptionsConsole.FADERS[i], Rect2i(_fader_x(i) - 4, _bar_top - 10, CHANNEL_WIDTH + 8, _bar_height + 20))
	var mute: Array = _layout.mute
	var ring: int = mute[2] + 8
	_add(Kind.MUTE, &"muted", Rect2i(mute[0] - ring, mute[1] - ring, ring * 2 + 1, ring * 2 + 1))
	var r: int = _layout.knob_r
	for i: int in OptionsConsole.KNOBS.size():
		var knob: Array = _layout.knobs[i]
		_add(Kind.KNOB, OptionsConsole.KNOBS[i], Rect2i(knob[0] - r - 8, knob[1] - r - 26, r * 2 + 17, r * 2 + 30))
	var switch_size: Array = _layout.switch_size
	for i: int in OptionsConsole.SWITCHES.size():
		var slot: Array = _layout.switches[i]
		_add(Kind.SWITCH, OptionsConsole.SWITCHES[i], Rect2i(slot[0] - 4, slot[1] - 13, switch_size[0] + 8, switch_size[1] + 17))
	_add(Kind.BACK, &"", _rect(_layout.back))
	visibility_changed.connect(_release)

## Rectángulo de la consola en la vista (para que MainMenu sepa adónde acercarse).
func get_body_rect() -> Rect2:
	return Rect2(_origin, Vector2(_layout.size[0], _layout.size[1]))

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for i: int in OptionsConsole.FADERS.size():
		_meters[i] = OptionsConsole.meter_level(OptionsConsole.FADERS[i], _meters[i], delta)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_hovered(-1)

# --- Ratón ---------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var mouse: InputEventMouse = event as InputEventMouse
	if mouse == null:
		return
	accept_event()
	var point: Vector2i = Vector2i(mouse.position) - _origin
	if event is InputEventMouseMotion:
		if _dragging >= 0:
			_drag_fader(_dragging, point.y)
		else:
			_set_hovered(_control_at(point))
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		_dragging = -1
		return
	if not click.pressed:
		return
	var index: int = _control_at(point)
	if index < 0:
		if click.button_index == MOUSE_BUTTON_LEFT and not Rect2i(Vector2i.ZERO, Vector2i(get_body_rect().size)).has_point(point):
			back_pressed.emit()
		return
	var control: Dictionary = _controls[index]
	var key: StringName = control.key
	var wheel: int = 1 if click.button_index == MOUSE_BUTTON_WHEEL_UP else (-1 if click.button_index == MOUSE_BUTTON_WHEEL_DOWN else 0)
	if wheel != 0:
		if control.kind == Kind.FADER:
			_set_setting(key, clampf(snappedf(Settings.get_value(key) + wheel * VOLUME_STEP, VOLUME_STEP), 0.0, 1.0))
		elif control.kind == Kind.KNOB:
			var values: Array = OptionsConsole.knob_values(key)
			_set_setting(key, values[clampi(OptionsConsole.knob_index(key) + wheel, 0, values.size() - 1)])
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	match control.kind:
		Kind.FADER:
			_dragging = index
			_drag_fader(index, point.y)
		Kind.KNOB:
			var values: Array = OptionsConsole.knob_values(key)
			_set_setting(key, values[(OptionsConsole.knob_index(key) + 1) % values.size()])
		Kind.SWITCH, Kind.MUTE:
			_set_setting(key, not Settings.get_value(key))
		Kind.BACK:
			back_pressed.emit()

# El tirador sigue al ratón (en pasos de VOLUME_STEP).
func _drag_fader(index: int, y: int) -> void:
	var travel: float = _bar_height - CAP_SIZE.y
	var value: float = 1.0 - clampf((y - _bar_top - CAP_SIZE.y / 2.0) / travel, 0.0, 1.0)
	_set_setting(_controls[index].key, snappedf(value, VOLUME_STEP))

func _set_setting(key: StringName, value: Variant) -> void:
	if Settings.get_value(key) != value:
		Settings.set_value(key, value)

func _control_at(point: Vector2i) -> int:
	for i: int in _controls.size():
		if _controls[i].rect.has_point(point):
			return i
	return -1

func _set_hovered(index: int) -> void:
	_hovered = index
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if index >= 0 else Control.CURSOR_ARROW

func _release() -> void:
	_dragging = -1
	_set_hovered(-1)

func _add(kind: Kind, key: StringName, rect: Rect2i) -> void:
	_controls.append({"kind": kind, "key": key, "rect": rect})

# --- Dibujo --------------------------------------------------------------------------------

func _draw() -> void:
	draw_set_transform(Vector2(_origin))
	draw_texture(BODY, Vector2.ZERO)
	_draw_screen()
	_draw_mute()
	_draw_knobs()
	_draw_switches()
	_draw_lcd()
	var back: Rect2i = _rect(_layout.back)
	@warning_ignore("integer_division")
	OfficePaint.text_centered(self, back.get_center().x, back.position.y + (back.size.y - OfficePaint.TEXT_HEIGHT * 2) / 2,
			tr("BTN_BACK").to_upper(), OfficePaint.OUTLINE, BIG_TEXT)
	if _hovered >= 0:
		OfficePaint.brackets(self, _controls[_hovered].rect, OfficePaint.CYAN_LIGHT)

# Pantalla de arriba: líneas de barrido y tres canales (vúmetro con el nivel de su bus y fader).
@warning_ignore("integer_division")
func _draw_screen() -> void:
	var screen: Rect2i = _rect(_layout.screen)
	for y: int in range(screen.position.y + 1, screen.end.y, 2):
		OfficePaint.rect(self, Rect2i(screen.position.x, y, screen.size.x, 1), OfficePaint.SCREEN_DARK)
	for channel: int in OptionsConsole.FADERS.size():
		var x: int = _fader_x(channel)
		var level: int = roundi(_meters[channel] * SEGMENTS)
		for segment: int in SEGMENTS:
			var color: Color = OfficePaint.GREEN if segment < 9 else (OfficePaint.AMBER if segment < 12 else OfficePaint.RED)
			if segment >= level:
				color = color.darkened(0.72)
			var y: int = _bar_top + _bar_height - SEGMENT_HEIGHT - segment * (SEGMENT_HEIGHT + SEGMENT_GAP)
			OfficePaint.rect(self, Rect2i(x, y, METER_WIDTH, SEGMENT_HEIGHT), color)
		# Carril con marcas cada 10 %.
		var track_x: int = x + METER_WIDTH + FADER_GAP + CAP_SIZE.x / 2
		for step: int in 11:
			var mark_y: int = _bar_top + CAP_SIZE.y / 2 + roundi(step / 10.0 * (_bar_height - CAP_SIZE.y))
			OfficePaint.rect(self, Rect2i(track_x - 12, mark_y, 24, 1), OfficePaint.SCREEN_LINE)
		OfficePaint.rect(self, Rect2i(track_x - 3, _bar_top, 7, _bar_height), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(track_x - 1, _bar_top, 3, _bar_height), OfficePaint.SCREEN_LINE)
		var volume: float = Settings.get_value(OptionsConsole.FADERS[channel])
		var cap: Rect2i = Rect2i(Vector2i(x + METER_WIDTH + FADER_GAP, _bar_top + roundi((1.0 - volume) * (_bar_height - CAP_SIZE.y))), CAP_SIZE)
		OfficePaint.bevel_box(self, cap, OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL_DARK)
		OfficePaint.rect(self, Rect2i(cap.position.x + 3, cap.position.y + 9, cap.size.x - 6, 2), OfficePaint.CYAN_DARK)

# Pulsador de silenciar: rojo encendido con `muted`, apagado si no.
func _draw_mute() -> void:
	var mute: Array = _layout.mute
	var center: Vector2i = Vector2i(mute[0], mute[1])
	var radius: int = mute[2]
	var on: bool = Settings.get_value(&"muted")
	OfficePaint.disc(self, center, radius, OfficePaint.OUTLINE)
	if on:
		OfficePaint.ring(self, center, radius - 2, OfficePaint.RED_LIGHT)
	OfficePaint.disc(self, center, radius - 3, OfficePaint.RED if on else OfficePaint.RED_DARK.darkened(0.6))
	OfficePaint.disc(self, center + Vector2i(-8, -8), 8, OfficePaint.RED_LIGHT if on else OfficePaint.RED_DARK.darkened(0.3))
	OfficePaint.disc(self, center + Vector2i(-10, -10), 3, Color.WHITE if on else OfficePaint.RED_DARK)

# Marca de cada pomo hacia su posición y el nombre de las dos posiciones (la elegida, encendida).
func _draw_knobs() -> void:
	var r: int = _layout.knob_r
	for i: int in OptionsConsole.KNOBS.size():
		var key: StringName = OptionsConsole.KNOBS[i]
		var center: Vector2i = Vector2i(_layout.knobs[i][0], _layout.knobs[i][1])
		var angle: float = OptionsConsole.knob_angle(key)
		var tip: Vector2i = center + Vector2i((Vector2.UP * (r - 5)).rotated(angle).round())
		var from: Vector2i = center + Vector2i((Vector2.UP * 6.0).rotated(angle).round())
		for offset: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
			OfficePaint.line(self, from + offset, tip + offset, OfficePaint.OUTLINE)
		var values: Array = OptionsConsole.knob_values(key)
		for v: int in values.size():
			var side: float = deg_to_rad(lerpf(-OptionsConsole.KNOB_ANGLE, OptionsConsole.KNOB_ANGLE, float(v) / maxf(values.size() - 1, 1.0)))
			var at: Vector2i = center + Vector2i((Vector2.UP * (r + 20)).rotated(side).round())
			var color: Color = OfficePaint.CYAN_LIGHT if v == OptionsConsole.knob_index(key) else OfficePaint.METAL
			OfficePaint.text_centered(self, at.x, at.y - 7, _value_text(values[v]), color)

# Palancas: arriba ON (con su piloto verde), abajo OFF.
func _draw_switches() -> void:
	var size_: Vector2i = Vector2i(_layout.switch_size[0], _layout.switch_size[1])
	for i: int in OptionsConsole.SWITCHES.size():
		var slot: Vector2i = Vector2i(_layout.switches[i][0], _layout.switches[i][1])
		var on: bool = Settings.get_value(OptionsConsole.SWITCHES[i])
		OfficePaint.rect(self, Rect2i(slot.x + 4, slot.y - 10, size_.x - 8, 4), OfficePaint.GREEN_LIGHT if on else OfficePaint.GREEN_DARK.darkened(0.5))
		var lever: Rect2i = Rect2i(slot.x, slot.y + (4 if on else size_.y - LEVER_HEIGHT - 2), size_.x, LEVER_HEIGHT)
		OfficePaint.bevel_box(self, lever, OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL_DARK)
		for grip: int in 3:
			OfficePaint.rect(self, Rect2i(lever.position.x + 4, lever.position.y + 10 + grip * 5, size_.x - 8, 1), OfficePaint.METAL)

# Pantallita: nombre y valor del mando bajo el ratón; si no, el título con un cursor.
func _draw_lcd() -> void:
	var lcd: Rect2i = _rect(_layout.lcd)
	for y: int in range(lcd.position.y + 1, lcd.end.y, 2):
		OfficePaint.rect(self, Rect2i(lcd.position.x, y, lcd.size.x, 1), OfficePaint.SCREEN_DARK)
	var text: String = tr("OPT_TITLE")
	if _hovered >= 0:
		var key: StringName = _controls[_hovered].key
		text = tr("BTN_BACK") if key == &"" else "%s %s" % [tr(NAMES[key]), _value_text(Settings.get_value(key))]
	elif fmod(_time, 1.0) < 0.5:
		text += "_"
	@warning_ignore("integer_division")
	OfficePaint.text(self, Vector2i(lcd.position.x + 10, lcd.position.y + (lcd.size.y - OfficePaint.TEXT_HEIGHT * 2) / 2),
			text.to_upper(), OfficePaint.CYAN, BIG_TEXT)

# Valor de una opción como se lee en la consola: porcentaje, ON / OFF o el código del idioma.
func _value_text(value: Variant) -> String:
	if value is bool:
		return "ON" if value else "OFF"
	if value is float:
		return "%d%%" % roundi(value * 100.0)
	return String(value).to_upper()

func _fader_x(channel: int) -> int:
	return _channel_x + channel * (CHANNEL_WIDTH + CHANNEL_GAP)

func _rect(values: Array) -> Rect2i:
	return Rect2i(values[0], values[1], values[2], values[3])
