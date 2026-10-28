extends Node2D
class_name Orbit
# Órbita de una torreta (va como hijo suyo): mueve los proyectiles que genera el emisor. Cada uno sale
# en espiral desde el centro hasta el radio medio del anillo de alcance y gira con los demás; al tocar
# a un enemigo explota en área. Los nuevos se colocan en el hueco más grande entre los que ya giran.

# Radio desde el que sale el proyectil (borde del emisor).
const START_RADIUS := 6.0

var _turret: Turret
var _data: OrbitData
# Ángulo común de la órbita; cada proyectil va a su desfase (meta "offset") respecto a él.
var _phase := 0.0

func _ready() -> void:
	_turret = get_parent()
	_data = _turret.data.orbit
	# Por encima de torretas y enemigos.
	z_index = 1

## Con max_orbs en órbita el emisor no genera más.
func is_full() -> bool:
	return get_child_count() >= _data.max_orbs

## Radio de la órbita: el centro del anillo entre min_range y el alcance.
func orbit_radius() -> float:
	return (_turret.data.min_range + _max_range()) / 2.0

## Distancia a la que un proyectil choca: medio ancho del anillo.
func hit_radius() -> float:
	return (_max_range() - _turret.data.min_range) / 2.0

func _max_range() -> float:
	var circle := _turret.attack_range_shape.shape as CircleShape2D
	return circle.radius if circle else 0.0

## Lanza un proyectil desde el centro hacia el hueco más grande de la órbita.
func spawn_orb() -> void:
	var orb := AnimatedSprite2D.new()
	orb.sprite_frames = _data.orb_frames
	orb.set_meta(&"offset", _free_offset())
	orb.set_meta(&"deploy", 0.0)
	add_child(orb)
	orb.play()
	_place(orb)

# Desfase en medio del hueco más grande entre los proyectiles que ya giran.
func _free_offset() -> float:
	var offsets: Array[float] = []
	for orb: Node in get_children():
		offsets.append(fposmod(orb.get_meta(&"offset"), TAU))
	if offsets.is_empty():
		# El primero sale hacia arriba.
		return -PI / 2.0 - _phase
	offsets.sort()
	var best_start := offsets[-1]
	var best_gap := offsets[0] + TAU - offsets[-1]
	for i in range(1, offsets.size()):
		var gap := offsets[i] - offsets[i - 1]
		if gap > best_gap:
			best_gap = gap
			best_start = offsets[i - 1]
	return best_start + best_gap / 2.0

func _process(delta: float) -> void:
	# Apagada por un EMP, las cargas se quedan quietas y no chocan.
	if _turret.disabled:
		return
	# Amplificada gira más rápido.
	var speed := _data.orbit_speed * _turret.amp_value(AmpEffect.Kind.ORBIT_SPEED, 1.0)
	_phase = fmod(_phase + deg_to_rad(speed) * delta, TAU)
	for orb: AnimatedSprite2D in get_children():
		if orb.is_queued_for_deletion():
			continue
		var deploy: float = minf(orb.get_meta(&"deploy") + delta / _data.deploy_time, 1.0)
		orb.set_meta(&"deploy", deploy)
		_place(orb)
		if deploy >= 1.0:
			_check_hit(orb)

# Sale frenando: de START_RADIUS al radio de la órbita mientras gira con los demás.
func _place(orb: AnimatedSprite2D) -> void:
	var deploy: float = orb.get_meta(&"deploy")
	var radius := lerpf(START_RADIUS, orbit_radius(), ease(deploy, 0.4))
	orb.position = Vector2.from_angle(_phase + orb.get_meta(&"offset")) * radius

# Explota al tocar a un enemigo (aunque esté camuflado: no apunta, choca).
func _check_hit(orb: AnimatedSprite2D) -> void:
	var reach := hit_radius()
	for enemy in _turret.enemies_in_range:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(orb.global_position) <= reach:
			_explode(orb)
			return

func _explode(orb: AnimatedSprite2D) -> void:
	var center := orb.global_position
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.global_position.distance_to(center) <= _data.splash_radius:
			enemy.take_damage(_data.damage, _turret)
	if _data.impact_frames:
		Effect.spawn(_turret.get_parent(), _data.impact_frames, center, _data.impact_scale)
	orb.queue_free()
