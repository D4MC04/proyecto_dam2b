extends Node2D
class_name HeatGlow
# Calor del Láser (ver Tower._update_overheat), todo en píxeles sin antialiasing: un halo
# naranja que crece con el calor y chispas de metal al rojo que saltan cada vez más.
# Sobrecalentada, el halo palpita y salen muchas más chispas.

const GLOW_COLOR := Color(1.0, 0.45, 0.15)
const GLOW_MIN_RADIUS := 4.0
const GLOW_MAX_RADIUS := 14.0
const GLOW_MAX_ALPHA := 0.35
const PULSE_SPEED := 12.0
# Chispas por segundo con el calor al máximo y extra al sobrecalentarse.
const SPARKS_PER_SECOND := 30.0
const OVERHEAT_SPARKS_PER_SECOND := 60.0
const MAX_SPARKS := 60
const SPARK_SPEED_MIN := 15.0
const SPARK_SPEED_MAX := 40.0
const SPARK_LIFE := 0.5
# De recién salida a apagándose: amarillo, naranja, rojo.
const SPARK_COLORS: Array[Color] = [Color("#fff1a0"), Color("#ffa040"), Color("#e0402a")]

## Calor de 0 a 1 y si está sobrecalentada; los pone la torre cada frame.
var heat := 0.0
var overheated := false

var _time := 0.0
var _spawn_debt := 0.0
# Cada chispa: [posición, velocidad, vida que le queda].
var _sparks: Array[Array] = []

func _ready() -> void:
	z_index = 1

func _process(delta: float) -> void:
	_time += delta
	var rate := heat * heat * SPARKS_PER_SECOND + (OVERHEAT_SPARKS_PER_SECOND if overheated else 0.0)
	_spawn_debt += rate * delta
	while _spawn_debt >= 1.0 and _sparks.size() < MAX_SPARKS:
		_spawn_debt -= 1.0
		var dir := Vector2.from_angle(randf() * TAU)
		_sparks.append([Vector2.ZERO, dir * randf_range(SPARK_SPEED_MIN, SPARK_SPEED_MAX), SPARK_LIFE])
	_spawn_debt = minf(_spawn_debt, 1.0)
	for spark: Array in _sparks:
		spark[0] += spark[1] * delta
		spark[2] -= delta
	_sparks = _sparks.filter(func(spark: Array) -> bool: return spark[2] > 0.0)
	visible = heat > 0.0 or overheated or not _sparks.is_empty()
	queue_redraw()

func _draw() -> void:
	var glow := heat
	if overheated:
		glow = 0.8 + 0.2 * sin(_time * PULSE_SPEED)
	if glow > 0.0:
		var radius := lerpf(GLOW_MIN_RADIUS, GLOW_MAX_RADIUS, glow)
		draw_circle(Vector2.ZERO, radius, Color(GLOW_COLOR, GLOW_MAX_ALPHA * glow * 0.5))
		draw_circle(Vector2.ZERO, radius * 0.6, Color(GLOW_COLOR, GLOW_MAX_ALPHA * glow))
	for spark: Array in _sparks:
		var age: float = 1.0 - spark[2] / SPARK_LIFE
		var color: Color = SPARK_COLORS[mini(int(age * SPARK_COLORS.size()), SPARK_COLORS.size() - 1)]
		draw_rect(Rect2((spark[0] as Vector2).round(), Vector2.ONE), color)
