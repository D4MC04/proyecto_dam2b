class_name MaintenancePanel
extends OfficeObject

# Cuadro de mantenimiento en la pared: abre las opciones. Caja de metal con rayas de aviso arriba,
# cuatro palancas de colores, un manómetro, luces de estado, una fila de interruptores y abajo
# una placa con un engranaje grabado. Con el ratón encima el engranaje se enciende y gira, una
# palanca sube y baja y las luces parpadean más rápido.

const BOX := Rect2i(0, 0, 250, 300)
const HAZARD_BAND := Rect2i(8, 8, 234, 10)
const LEVER_AREA := Rect2i(8, 24, 234, 118)
const SWITCH_AREA := Rect2i(8, 148, 234, 52)
const GEAR_PLATE := Rect2i(8, 206, 234, 86)
const RECESS := Color("#232838")
# Palancas: x de cada ranura, color del pomo y altura del pomo (0 abajo, 1 arriba).
const LEVER_X: Array[int] = [28, 62, 96, 130]
const LEVER_COLORS: Array[Color] = [Color("#ff3c5a"), Color("#ecb23c"), Color("#40e0f0"), Color("#3cb860")]
const LEVER_LEVELS: Array[float] = [0.8, 0.35, 0.6, 0.15]
const SLOT_TOP := 36
const SLOT_HEIGHT := 92
# Manómetro.
const GAUGE_CENTER := Vector2i(200, 62)
const GAUGE_RADIUS := 22
# Luces de estado: 2 filas de 3, con su color y su periodo de parpadeo (s).
const LIGHTS_ORIGIN := Vector2i(183, 98)
const LIGHT_COLORS: Array[Color] = [
	Color("#3cb860"), Color("#3cb860"), Color("#ecb23c"), Color("#40e0f0"), Color("#3cb860"), Color("#ff3c5a"),
]
const LIGHT_PERIODS: Array[float] = [0.0, 1.7, 0.9, 0.0, 2.3, 1.3]
# Interruptores: cantidad y cuáles están arriba.
const SWITCHES := 8
const SWITCHES_UP: Array[bool] = [true, true, false, true, false, true, true, false]
const GEAR_CENTER := Vector2i(125, 249)

func _draw_object() -> void:
	OfficePaint.metal_box(self, BOX)
	for corner: Vector2i in [Vector2i(2, 2), Vector2i(245, 2), Vector2i(2, 295), Vector2i(245, 295)]:
		OfficePaint.screw(self, corner)
	OfficePaint.rect(self, HAZARD_BAND.grow(1), OfficePaint.OUTLINE)
	OfficePaint.hazard(self, HAZARD_BAND)
	_draw_levers()
	_draw_gauge()
	_draw_lights()
	_draw_switches()
	_draw_gear_plate()

func _recess(r: Rect2i) -> void:
	OfficePaint.bevel_box(self, r, RECESS, OfficePaint.OUTLINE, OfficePaint.METAL_DARK)

func _draw_levers() -> void:
	_recess(LEVER_AREA)
	for i in LEVER_X.size():
		var x := LEVER_X[i]
		OfficePaint.rect(self, Rect2i(x, SLOT_TOP, 6, SLOT_HEIGHT), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(x + 2, SLOT_TOP + 2, 2, SLOT_HEIGHT - 4), OfficePaint.WALL_DARK)
		var level := LEVER_LEVELS[i]
		if hovered and i == 1:
			level = 0.5 + sin(time * 3.0) * 0.4
		var knob_y := SLOT_TOP + int((1.0 - level) * (SLOT_HEIGHT - 12))
		var color := LEVER_COLORS[i]
		OfficePaint.bevel_box(self, Rect2i(x - 7, knob_y, 20, 12), color, color.lightened(0.45), color.darkened(0.45))
		OfficePaint.rect(self, Rect2i(x - 4, knob_y + 5, 14, 1), color.darkened(0.6))
		# Marcas de la escala a la derecha de la ranura.
		for m in 5:
			OfficePaint.rect(self, Rect2i(x + 15, SLOT_TOP + 4 + m * 20, 4 if m % 2 == 0 else 2, 1), OfficePaint.METAL_LIGHT)

func _draw_gauge() -> void:
	OfficePaint.disc(self, GAUGE_CENTER, GAUGE_RADIUS + 1, OfficePaint.OUTLINE)
	OfficePaint.disc(self, GAUGE_CENTER, GAUGE_RADIUS, OfficePaint.METAL_LIGHT)
	OfficePaint.disc(self, GAUGE_CENTER, GAUGE_RADIUS - 3, Color("#0e1626"))
	# Marcas del arco, de abajo a la izquierda a abajo a la derecha.
	for m in 7:
		var angle := lerpf(PI * 0.75, PI * 2.25, m / 6.0)
		var outer := GAUGE_CENTER + Vector2i((Vector2.from_angle(angle) * (GAUGE_RADIUS - 4)).round())
		var inner := GAUGE_CENTER + Vector2i((Vector2.from_angle(angle) * (GAUGE_RADIUS - 7)).round())
		OfficePaint.line(self, inner, outer, OfficePaint.RED if m == 6 else OfficePaint.CYAN_DARK)
	var wobble := sin(time * (9.0 if hovered else 1.3)) * (0.25 if hovered else 0.08)
	var needle := PI * 1.7 + wobble
	OfficePaint.line(self, GAUGE_CENTER, GAUGE_CENTER + Vector2i((Vector2.from_angle(needle) * (GAUGE_RADIUS - 6)).round()), OfficePaint.CYAN_LIGHT)
	OfficePaint.rect(self, Rect2i(GAUGE_CENTER - Vector2i.ONE, Vector2i(3, 3)), OfficePaint.METAL_LIGHT)

func _draw_lights() -> void:
	for i in LIGHT_COLORS.size():
		@warning_ignore("integer_division")
		var at := LIGHTS_ORIGIN + Vector2i((i % 3) * 12, (i / 3) * 12)
		var period := LIGHT_PERIODS[i] * (0.4 if hovered else 1.0)
		var on := period == 0.0 or fmod(time + i * 0.37, period) < period * 0.6
		var color := LIGHT_COLORS[i]
		OfficePaint.rect(self, Rect2i(at - Vector2i.ONE, Vector2i(7, 7)), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(at, Vector2i(5, 5)), color if on else color.darkened(0.7))
		if on:
			OfficePaint.rect(self, Rect2i(at, Vector2i(2, 1)), color.lightened(0.6))

func _draw_switches() -> void:
	_recess(SWITCH_AREA)
	for i in SWITCHES:
		var x := 24 + i * 26
		var up := SWITCHES_UP[i]
		OfficePaint.rect(self, Rect2i(x + 2, 155, 4, 3), OfficePaint.GREEN if up else OfficePaint.RED_DARK)
		OfficePaint.bevel_box(self, Rect2i(x, 162, 8, 30), OfficePaint.WALL_DARK, OfficePaint.OUTLINE, OfficePaint.METAL_DARK)
		OfficePaint.bevel_box(self, Rect2i(x + 1, 165 if up else 177, 6, 12), OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL)

# Placa con rejillas a los lados y un engranaje grabado en el centro, el símbolo de ajustes.
func _draw_gear_plate() -> void:
	_recess(GEAR_PLATE)
	for side_x: int in [22, 172]:
		for row in 6:
			OfficePaint.rect(self, Rect2i(side_x, 220 + row * 10, 56, 3), OfficePaint.OUTLINE)
			OfficePaint.rect(self, Rect2i(side_x, 223 + row * 10, 56, 1), OfficePaint.METAL_DARK)
	var color := OfficePaint.CYAN if hovered else OfficePaint.METAL
	var spin := time * 1.5 if hovered else 0.0
	_draw_gear(GEAR_CENTER, color, spin)

func _draw_gear(center: Vector2i, color: Color, spin: float) -> void:
	OfficePaint.disc(self, center, 22, OfficePaint.OUTLINE)
	for t in 8:
		var angle := spin + t * TAU / 8.0
		var tooth := center + Vector2i((Vector2.from_angle(angle) * 17.0).round())
		OfficePaint.rect(self, Rect2i(tooth - Vector2i(3, 3), Vector2i(7, 7)), color)
	OfficePaint.disc(self, center, 15, color)
	OfficePaint.disc(self, center, 6, OfficePaint.OUTLINE)
	OfficePaint.disc(self, center, 5, RECESS)
