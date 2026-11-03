class_name RadarConsole
extends OfficeObject

# Monitor de radar sobre el escritorio: abre la selección de sector. Un barrido gira por la
# pantalla y enciende los ecos rojos de las naves enemigas al pasar; a la derecha, los sectores
# desbloqueados y unas barras de señal. Con el ratón encima el barrido va más rápido.

# Carcasa del monitor y pantalla (en coordenadas locales).
const HOUSING := Rect2i(0, 0, 176, 122)
const SCREEN_RECT := Rect2i(5, 5, 166, 110)
const NECK := Rect2i(78, 122, 20, 12)
const FOOT := Rect2i(52, 133, 72, 9)
# Radar: centro, radio y radios de los anillos interiores.
const RADAR_CENTER := Vector2i(62, 60)
const RADAR_RADIUS := 48
const INNER_RINGS: Array[int] = [32, 16]
const RADAR_BG := Color("#0e1626")
# Vueltas por segundo del barrido, normal y con el ratón encima.
const SWEEP_SPEED := 0.3
const SWEEP_SPEED_HOVER := 0.8
# Estela del barrido: separación entre líneas (rad) y colores, de la más cercana a la más lejana.
const TRAIL_STEP := 0.07
const TRAIL_COLORS: Array[Color] = [Color("#1c7496"), Color("#1c7496"), Color("#14304a"), Color("#14304a")]
# Ecos de naves: [distancia al centro, ángulo]. Brillan al pasar el barrido y se apagan después.
const BLIPS: Array[Vector2] = [
	Vector2(38, 0.6), Vector2(24, 2.1), Vector2(42, 2.9), Vector2(30, 4.4), Vector2(14, 5.5),
]
const BLIP_FLASH := 0.5
const BLIP_FADE := 3.2
# Lectura de la derecha.
const READOUT_X := 120
const BAR_COUNT := 5

var _sweep := 0.0
var _sectors_text := ""

func _ready() -> void:
	super()
	var total: int = GameData.levels.size()
	_sectors_text = "%02d/%02d" % [mini(GameState.current_level, total), total]

func _process(delta: float) -> void:
	_sweep = fposmod(_sweep + delta * TAU * (SWEEP_SPEED_HOVER if hovered else SWEEP_SPEED), TAU)
	super(delta)

func _draw_object() -> void:
	OfficePaint.metal_box(self, NECK)
	OfficePaint.metal_box(self, FOOT)
	OfficePaint.metal_box(self, HOUSING)
	OfficePaint.screen(self, SCREEN_RECT)
	_draw_radar()
	_draw_readout()
	# Luces de la carcasa, abajo a la derecha.
	var lights: Array[Color] = [OfficePaint.CYAN, OfficePaint.AMBER, OfficePaint.GREEN]
	for i in lights.size():
		var on := hovered or i != 1 or fmod(time, 1.2) < 0.6
		OfficePaint.rect(self, Rect2i(146 + i * 8, 117, 3, 2), lights[i] if on else OfficePaint.METAL_DARK)
	# Rejilla de altavoz abajo a la izquierda.
	for i in 8:
		OfficePaint.rect(self, Rect2i(10 + i * 3, 117, 1, 2), OfficePaint.METAL_DARK)

func _draw_radar() -> void:
	OfficePaint.disc(self, RADAR_CENTER, RADAR_RADIUS, RADAR_BG)
	for radius in INNER_RINGS:
		OfficePaint.ring(self, RADAR_CENTER, radius, OfficePaint.SCREEN_LINE)
	OfficePaint.rect(self, Rect2i(RADAR_CENTER.x - RADAR_RADIUS, RADAR_CENTER.y, RADAR_RADIUS * 2 + 1, 1), OfficePaint.SCREEN_LINE)
	OfficePaint.rect(self, Rect2i(RADAR_CENTER.x, RADAR_CENTER.y - RADAR_RADIUS, 1, RADAR_RADIUS * 2 + 1), OfficePaint.SCREEN_LINE)
	for i in range(TRAIL_COLORS.size() - 1, -1, -1):
		_draw_spoke(_sweep - TRAIL_STEP * (i + 1), TRAIL_COLORS[i])
	for blip in BLIPS:
		_draw_blip(blip)
	_draw_spoke(_sweep, OfficePaint.CYAN_LIGHT)
	OfficePaint.ring(self, RADAR_CENTER, RADAR_RADIUS, OfficePaint.CYAN_DARK)
	OfficePaint.rect(self, Rect2i(RADAR_CENTER - Vector2i.ONE, Vector2i(2, 2)), OfficePaint.CYAN)

func _draw_spoke(angle: float, color: Color) -> void:
	var tip := RADAR_CENTER + Vector2i((Vector2.from_angle(angle) * (RADAR_RADIUS - 1)).round())
	OfficePaint.line(self, RADAR_CENTER, tip, color)

# Eco de nave: destello al pasar el barrido, rojo después y oscuro al final.
func _draw_blip(blip: Vector2) -> void:
	var since := fposmod(_sweep - blip.y, TAU) / (TAU * (SWEEP_SPEED_HOVER if hovered else SWEEP_SPEED))
	var at := RADAR_CENTER + Vector2i((Vector2.from_angle(blip.y) * blip.x).round())
	if since < BLIP_FLASH:
		OfficePaint.rect(self, Rect2i(at - Vector2i.ONE, Vector2i(3, 3)), OfficePaint.RED)
		OfficePaint.rect(self, Rect2i(at, Vector2i.ONE), OfficePaint.RED_LIGHT)
	elif since < BLIP_FADE:
		OfficePaint.rect(self, Rect2i(at, Vector2i(2, 2)), OfficePaint.RED)
	else:
		OfficePaint.rect(self, Rect2i(at, Vector2i(2, 2)), OfficePaint.RED_DARK)

# Sectores desbloqueados y barras de señal.
func _draw_readout() -> void:
	OfficePaint.text(self, Vector2i(READOUT_X, 10), "SECT", OfficePaint.CYAN_DARK)
	OfficePaint.text(self, Vector2i(READOUT_X, 23), _sectors_text, OfficePaint.CYAN)
	OfficePaint.rect(self, Rect2i(READOUT_X, 40, 44, 1), OfficePaint.SCREEN_LINE)
	OfficePaint.text(self, Vector2i(READOUT_X, 46), "SEÑAL", OfficePaint.CYAN_DARK)
	for i in BAR_COUNT:
		var height := 6 + int((sin(time * (5.0 if hovered else 2.0) + i * 1.7) * 0.5 + 0.5) * 24.0)
		var bar := Rect2i(READOUT_X + 2 + i * 9, 104 - height, 6, height)
		OfficePaint.rect(self, bar, OfficePaint.CYAN_DARK)
		OfficePaint.rect(self, Rect2i(bar.position, Vector2i(6, 1)), OfficePaint.CYAN)
