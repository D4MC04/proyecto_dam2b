extends Node2D
class_name EmpCharge
# Carga del pulso EMP de la Saboteadora, para que se vea venir: durante CHARGE_TIME crece en el
# núcleo una bola de energía inestable (late cada vez más rápido, vibra, cambia de tamaño a
# tirones y chispea) que suelta rayos en zigzag cada vez más largos y frecuentes, y las bobinas
# se iluminan por pasos. Al final la nave tiembla y frena; luego la bola revienta y sale el
# pulso (EmpWave). Todo en píxeles sin antialiasing.
# Va como hijo del sprite, así gira con él y las luces caen sobre las piezas del dibujo.

const CHARGE_TIME := 1.0
# Rampa azul de la Saboteadora, de apagada a blanca (ver make_saboteadora.gd).
const GLOW_STEPS: Array[Color] = [Color("#16307a"), Color("#2a6ae6"), Color("#78bcff"), Color("#e6f6ff")]
# Píxeles del sprite (32x32, centrado) que se iluminan: anillos de las bobinas.
const COIL_RINGS: Array[Rect2] = [
	Rect2(-15, -2, 3, 1), Rect2(-15, 1, 3, 1), Rect2(-15, 4, 3, 1),
	Rect2(12, -2, 3, 1), Rect2(12, 1, 3, 1), Rect2(12, 4, 3, 1),
]
# Radio de la bola (px): de un punto de 2x2 a unos 13 px de ancho, más que el núcleo.
const BALL_FROM := 1.0
const BALL_TO := 6.5
# Latido: cuánto crece y encoge el radio y a qué velocidad (rad/s) al empezar y al acabar.
const PULSE_SIZE := 1.0
const PULSE_SPEED_FROM := 12.0
const PULSE_SPEED_TO := 60.0
# Píxeles que chispean sobre la bola: blanco, morado y rojizo.
const FLICKER_COLORS: Array[Color] = [Color("#ffffff"), Color("#aa78ff"), Color("#f0323c")]
const FLICKER_MAX := 4
# Rayos en zigzag: cuántos como mucho a la vez y su largo (px) al empezar y al acabar.
const BOLT_MAX := 4
const BOLT_LENGTH_FROM := 3
const BOLT_LENGTH_TO := 12
const BOLT_COLORS: Array[Color] = [Color("#78bcff"), Color("#e6f6ff")]
# Último tramo de la carga: la nave tiembla 1 px y va a esta fracción de su velocidad.
const BRACE_TIME := 0.3
const BRACE_SPEED := 0.25

var _enemy: Enemy
var _time := 0.0
var _phase := 0.0

static func start(enemy: Enemy) -> void:
	var charge := EmpCharge.new()
	charge._enemy = enemy
	# El offset del sprite no mueve a sus hijos: se copia para caer sobre el dibujo.
	charge.position = enemy.sprite.offset
	enemy.sprite.add_child(charge)

func _process(delta: float) -> void:
	_time += delta
	var t := minf(_time / CHARGE_TIME, 1.0)
	_phase += delta * lerpf(PULSE_SPEED_FROM, PULSE_SPEED_TO, t)
	if _time >= CHARGE_TIME:
		_release()
		return
	if _time >= CHARGE_TIME - BRACE_TIME:
		_enemy.speed = _enemy.data.speed * BRACE_SPEED
		_enemy.sprite.position = Vector2(randi_range(-1, 1), randi_range(-1, 1))
	queue_redraw()

func _release() -> void:
	_enemy.speed = _enemy.data.speed
	_enemy.sprite.position = Vector2.ZERO
	_enemy.flash()
	EmpWave.spawn(_enemy)
	queue_free()

func _draw() -> void:
	var t := _time / CHARGE_TIME
	var step := mini(int(t * GLOW_STEPS.size()), GLOW_STEPS.size() - 1)
	for rect: Rect2 in COIL_RINGS:
		draw_rect(rect, GLOW_STEPS[step])
	# A tirones: el radio va a medios píxeles y a veces salta uno de golpe.
	var radius := lerpf(BALL_FROM, BALL_TO, t) + PULSE_SIZE * sin(_phase) * t
	if randf() < t * 0.3:
		radius += [-1.0, 1.0].pick_random()
	radius = snappedf(radius, 0.5)
	# Vibra 1 px, más a menudo cuanto más cargada.
	var center := Vector2.ZERO
	if randf() < t:
		center = Vector2(randi_range(-1, 1), randi_range(-1, 1))
	_draw_disc(center, radius, GLOW_STEPS[maxi(step, 1)])
	_draw_disc(center, radius - 1.0, GLOW_STEPS[mini(step + 1, GLOW_STEPS.size() - 1)])
	_draw_disc(center, radius - 2.5, Color.WHITE)
	for i: int in randi_range(0, roundi(FLICKER_MAX * t)):
		var pixel := center + Vector2.from_angle(randf() * TAU) * randf_range(0.0, radius)
		draw_rect(Rect2(pixel.floor(), Vector2.ONE), FLICKER_COLORS.pick_random())
	for i: int in BOLT_MAX:
		if randf() < t:
			_draw_bolt(center, radius, roundi(lerpf(BOLT_LENGTH_FROM, BOLT_LENGTH_TO, t * randf_range(0.6, 1.0))))

# Círculo relleno de píxeles enteros con el centro en una esquina de píxel (el centro del sprite).
func _draw_disc(center: Vector2, radius: float, color: Color) -> void:
	var size := ceili(radius)
	for y: int in range(-size, size):
		for x: int in range(-size, size):
			if Vector2(x + 0.5, y + 0.5).length() <= radius:
				draw_rect(Rect2(center + Vector2(x, y), Vector2.ONE), color)

# Rayo de 1 px que sale del borde de la bola hacia fuera, torciéndose 1 px a cada lado.
func _draw_bolt(center: Vector2, radius: float, length: int) -> void:
	var direction := Vector2.from_angle(randf() * TAU)
	var side := direction.orthogonal()
	var color: Color = BOLT_COLORS.pick_random()
	var bend := 0.0
	for step: int in length:
		bend = clampf(bend + randi_range(-1, 1), -1.0, 1.0)
		var pixel := center + direction * (radius + step) + side * bend
		draw_rect(Rect2(pixel.floor(), Vector2.ONE), color)
