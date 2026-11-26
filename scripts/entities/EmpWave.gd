extends Node2D
class_name EmpWave
# Explosión EMP de la Payload al morir: un anillo azul de píxeles que crece desde donde murió, apaga
# las torretas por las que pasa su borde y quita vida a las naves que pilla. Se queda donde salió.

# Borde de fuera a dentro: frente blanco, dos píxeles de azul claro y estela azul.
const RING_COLORS: Array[Color] = [Color("#e6f6ff"), Color("#78bcff"), Color("#78bcff"), Color("#2a6ae6")]
# Sale de golpe: rápido al principio y frenando al llegar al radio.
const GROW_TIME: float = 0.3
const FADE_TIME: float = 0.2
# Destello blanco al reventar la bola de carga.
const FLASH_COLOR: Color = Color("#ffffff")
const FLASH_RADIUS: float = 12.0
const FLASH_TIME: float = 0.08

var _radius: float = 0.0
var _time: float = 0.0
var _disable_time: float
var _damage: float
var _hit: Array[Turret] = []
# Naves ya dañadas (y la que explota, que no se daña a sí misma).
var _hit_enemies: Array[Enemy] = []

static func spawn(enemy: Enemy) -> void:
	var wave: EmpWave = EmpWave.new()
	wave._disable_time = enemy.data.emp_disable_time
	wave._damage = enemy.data.death_damage
	wave._hit_enemies.append(enemy)
	# Por encima de torretas y enemigos.
	wave.z_index = 1
	enemy.get_parent().add_child(wave)
	# Centro en mitad de un píxel para que el anillo caiga en la rejilla.
	wave.global_position = enemy.global_position.floor() + Vector2(0.5, 0.5)
	var tween: Tween = wave.create_tween()
	tween.tween_property(wave, "_radius", enemy.data.emp_radius, GROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(wave.queue_free)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	for turret: Turret in get_tree().get_nodes_in_group(&"turrets"):
		if not _hit.has(turret) and global_position.distance_to(turret.global_position) <= _radius:
			_hit.append(turret)
			turret.disable(_disable_time)
	if _damage <= 0.0:
		return
	# Una sola vez a cada nave, cuando le llega el borde. Si cae otra Payload, también explota.
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.hp > 0.0 and not enemy.is_queued_for_deletion() and not _hit_enemies.has(enemy) and global_position.distance_to(enemy.global_position) <= _radius:
			_hit_enemies.append(enemy)
			enemy.take_damage(_damage)

func _draw() -> void:
	if _time < FLASH_TIME:
		draw_circle(Vector2.ZERO, FLASH_RADIUS, FLASH_COLOR, true, -1.0, false)
	var radius: int = roundi(_radius)
	for i: int in RING_COLORS.size():
		_draw_ring(radius - i, RING_COLORS[i])

# Circunferencia de 1 px sin antialiasing: un octante calculado y reflejado a los otros siete.
func _draw_ring(radius: int, color: Color) -> void:
	if radius < 1:
		return
	for x: int in ceili(radius / sqrt(2.0)) + 1:
		var y: int = roundi(sqrt(radius * radius - x * x))
		for point: Vector2 in [Vector2(x, y), Vector2(y, x)]:
			for mirror: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_rect(Rect2(point * mirror - Vector2(0.5, 0.5), Vector2.ONE), color)
