extends Node2D
class_name EmpCharge
# Latido de la Payload, para que se vea que es una bomba a punto de reventar: el núcleo de la
# ventanilla late cada vez más rápido y más fuerte según avanza por el camino (`progress_ratio`), y la
# espoleta del morro se enciende con cada latido. Al final del camino la bola de energía se sale de
# la ventanilla, vibra, cambia de tamaño a tirones, chispea y suelta rayos en zigzag. No cambia la
# velocidad de la nave. Al morir, la nave suelta la explosión (EmpWave). Todo en píxeles sin antialiasing.
# Va como hijo del sprite, así gira con él y las luces caen sobre las piezas del dibujo.

# Rampa azul de la Payload, de apagada a blanca (ver make_saboteadora.gd).
const GLOW_STEPS: Array[Color] = [Color("#16307a"), Color("#2a6ae6"), Color("#78bcff"), Color("#e6f6ff")]
# Centro de la ventanilla y píxeles de la luz de la espoleta, en el sprite (32x32, centrado).
const CORE_CENTER: Vector2 = Vector2(0, -5)
const FUSE_LIGHT: Rect2 = Rect2(-1, -15, 2, 1)
const FUSE_GLOW: Rect2 = Rect2(-1, -16, 2, 1)
const FUSE_COLORS: Array[Color] = [Color("#f0323c"), Color("#ff8c5a")]
# Radio de la bola en el pico del latido (px): dentro de la ventanilla al salir, se sale al llegar.
const BALL_FROM: float = 2.5
const BALL_TO: float = 6.5
# Latido: velocidad (rad/s) al salir y al llegar. A 4 rad/s late cada 1,6 s; a 40, unas 6 veces por segundo.
const BEAT_SPEED_FROM: float = 4.0
const BEAT_SPEED_TO: float = 40.0
# Por encima de esta fuerza del latido se enciende la espoleta.
const FUSE_THRESHOLD: float = 0.5
# Píxeles que chispean sobre la bola: blanco, morado y rojizo.
const FLICKER_COLORS: Array[Color] = [Color("#ffffff"), Color("#aa78ff"), Color("#f0323c")]
const FLICKER_MAX: int = 4
# Rayos en zigzag: cuántos como mucho a la vez y su largo (px) al salir y al llegar.
const BOLT_MAX: int = 4
const BOLT_LENGTH_FROM: int = 3
const BOLT_LENGTH_TO: int = 12
const BOLT_COLORS: Array[Color] = [Color("#78bcff"), Color("#e6f6ff")]
# La inestabilidad (tirones, vibración, chispas y rayos) empieza a partir de este avance.
const UNSTABLE_FROM: float = 0.4

var _enemy: Enemy
var _phase: float = 0.0

static func start(enemy: Enemy) -> void:
	var charge: EmpCharge = EmpCharge.new()
	charge._enemy = enemy
	# El offset del sprite no mueve a sus hijos: se copia para caer sobre el dibujo.
	charge.position = enemy.sprite.offset
	enemy.sprite.add_child(charge)

func _process(delta: float) -> void:
	_phase += delta * lerpf(BEAT_SPEED_FROM, BEAT_SPEED_TO, _progress())
	queue_redraw()

# Avance por el camino, de 0 (sale) a 1 (llega).
func _progress() -> float:
	return clampf(_enemy.progress_ratio, 0.0, 1.0)

func _draw() -> void:
	var t: float = _progress()
	# Latido seco: sube de golpe y cae despacio (0 en reposo, 1 en el pico).
	var beat: float = pow(0.5 + 0.5 * sin(_phase), 3.0)
	if beat >= FUSE_THRESHOLD:
		draw_rect(FUSE_LIGHT, FUSE_COLORS[1])
		if t > UNSTABLE_FROM:
			draw_rect(FUSE_GLOW, FUSE_COLORS[0])
	# Inestable solo en la segunda mitad del camino, cada vez más.
	var unstable: float = clampf((t - UNSTABLE_FROM) / (1.0 - UNSTABLE_FROM), 0.0, 1.0)
	var radius: float = lerpf(1.0, lerpf(BALL_FROM, BALL_TO, t), beat)
	# A tirones: el radio va a medios píxeles y a veces salta uno de golpe.
	if randf() < unstable * 0.3:
		radius += [-1.0, 1.0].pick_random()
	radius = snappedf(radius, 0.5)
	if radius < 1.5:
		return
	# Vibra 1 px, más a menudo cuanto más cerca.
	var center: Vector2 = CORE_CENTER
	if randf() < unstable * beat:
		center += Vector2(randi_range(-1, 1), randi_range(-1, 1))
	var step: int = mini(int(beat * GLOW_STEPS.size()), GLOW_STEPS.size() - 1)
	_draw_disc(center, radius, GLOW_STEPS[maxi(step - 1, 0)])
	_draw_disc(center, radius - 1.0, GLOW_STEPS[step])
	_draw_disc(center, radius - 2.5, Color.WHITE)
	var strength: float = unstable * beat
	for i: int in randi_range(0, roundi(FLICKER_MAX * strength)):
		var pixel: Vector2 = center + Vector2.from_angle(randf() * TAU) * randf_range(0.0, radius)
		draw_rect(Rect2(pixel.floor(), Vector2.ONE), FLICKER_COLORS.pick_random())
	for i: int in BOLT_MAX:
		if randf() < strength:
			_draw_bolt(center, radius, roundi(lerpf(BOLT_LENGTH_FROM, BOLT_LENGTH_TO, strength * randf_range(0.6, 1.0))))

# Círculo relleno de píxeles enteros con el centro en una esquina de píxel.
func _draw_disc(center: Vector2, radius: float, color: Color) -> void:
	var size: int = ceili(radius)
	for y: int in range(-size, size):
		for x: int in range(-size, size):
			if Vector2(x + 0.5, y + 0.5).length() <= radius:
				draw_rect(Rect2(center + Vector2(x, y), Vector2.ONE), color)

# Rayo de 1 px que sale del borde de la bola hacia fuera, torciéndose 1 px a cada lado.
func _draw_bolt(center: Vector2, radius: float, length: int) -> void:
	var direction: Vector2 = Vector2.from_angle(randf() * TAU)
	var side: Vector2 = direction.orthogonal()
	var color: Color = BOLT_COLORS.pick_random()
	var bend: float = 0.0
	for step: int in length:
		bend = clampf(bend + randi_range(-1, 1), -1.0, 1.0)
		var pixel: Vector2 = center + direction * (radius + step) + side * bend
		draw_rect(Rect2(pixel.floor(), Vector2.ONE), color)
