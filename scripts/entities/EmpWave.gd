extends Node2D
class_name EmpWave
# Pulso EMP de la Saboteadora: un anillo azul de píxeles que crece desde la nave y apaga
# las torres por las que pasa su borde. Se queda donde salió, no sigue a la nave.

# Borde de fuera a dentro: frente blanco, dos píxeles de azul claro y estela azul.
const RING_COLORS: Array[Color] = [Color("#e6f6ff"), Color("#78bcff"), Color("#78bcff"), Color("#2a6ae6")]
# Sale de golpe: rápido al principio y frenando al llegar al radio.
const GROW_TIME := 0.3
const FADE_TIME := 0.2
# Destello blanco al reventar la bola de carga.
const FLASH_COLOR := Color("#ffffff")
const FLASH_RADIUS := 12.0
const FLASH_TIME := 0.08

var _radius := 0.0
var _time := 0.0
var _disable_time: float
var _hit: Array[Tower] = []

## Le pone a la nave un temporizador que cada `emp_interval` segundos empieza a cargar un pulso
## (EmpCharge), que sale al acabar la carga.
static func attach(enemy: Enemy) -> void:
	var timer := Timer.new()
	timer.wait_time = enemy.data.emp_interval
	timer.autostart = true
	timer.timeout.connect(EmpCharge.start.bind(enemy))
	enemy.add_child(timer)

static func spawn(enemy: Enemy) -> void:
	var wave := EmpWave.new()
	wave._disable_time = enemy.data.emp_disable_time
	# Por encima de torres y enemigos.
	wave.z_index = 1
	enemy.get_parent().add_child(wave)
	# Centro en mitad de un píxel para que el anillo caiga en la rejilla.
	wave.global_position = enemy.global_position.floor() + Vector2(0.5, 0.5)
	var tween := wave.create_tween()
	tween.tween_property(wave, "_radius", enemy.data.emp_radius, GROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(wave.queue_free)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	for tower: Tower in get_tree().get_nodes_in_group(&"towers"):
		if not _hit.has(tower) and global_position.distance_to(tower.global_position) <= _radius:
			_hit.append(tower)
			tower.disable(_disable_time)

func _draw() -> void:
	if _time < FLASH_TIME:
		draw_circle(Vector2.ZERO, FLASH_RADIUS, FLASH_COLOR, true, -1.0, false)
	var radius := roundi(_radius)
	for i: int in RING_COLORS.size():
		_draw_ring(radius - i, RING_COLORS[i])

# Circunferencia de 1 px sin antialiasing: un octante calculado y reflejado a los otros siete.
func _draw_ring(radius: int, color: Color) -> void:
	if radius < 1:
		return
	for x: int in ceili(radius / sqrt(2.0)) + 1:
		var y := roundi(sqrt(radius * radius - x * x))
		for point: Vector2 in [Vector2(x, y), Vector2(y, x)]:
			for mirror: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_rect(Rect2(point * mirror - Vector2(0.5, 0.5), Vector2.ONE), color)
