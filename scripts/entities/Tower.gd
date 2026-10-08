class_name Tower
extends Node2D

@export var data: TowerData
@export var bullet_scene: PackedScene

# Margen para disparar sin que el cañón esté perfectamente alineado.
const AIM_TOLERANCE := deg_to_rad(12.0)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cannon: AnimatedSprite2D = $Cannon
@onready var attack_range_area: Area2D = $RangeDetector
@onready var attack_range_shape: CollisionShape2D = $RangeDetector/CollisionShape2D
@onready var attack_timer: Timer = $Timer

var enemies_in_range: Array[Enemy] = []
var _shots := 0
var _target: Enemy = null
# Cooldown cumplido, a la espera de que el cañón termine de girar hacia el enemigo.
var _pending_shot := false
# Mira de las torretas de haz; solo se ve durante la carga.
var _sight: Line2D

func _ready() -> void:
	sprite.sprite_frames = data.sprite_frames
	cannon.sprite_frames = data.cannon
	set_process(data.cannon != null and not _is_static())
	if data.beam:
		_sight = Beam.make_sight(self)
		cannon.animation_changed.connect(_on_cannon_frame_changed)
	if _is_static() or data.beam:
		cannon.play()
		cannon.frame_changed.connect(_on_cannon_frame_changed)
		cannon.animation_finished.connect(cannon.play.bind(&"default"))
	attack_range_shape.shape = data.attack_range
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	attack_range_area.area_entered.connect(_on_area_entered)
	attack_range_area.area_exited.connect(_on_area_exited)
	attack_timer.start()
	if data.focus_beam:
		# El haz continuo no dispara por cooldown: lo lleva su propio nodo.
		attack_timer.stop()
		add_child(FocusBeam.new())

func _process(delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	# Gira poco a poco por el camino más corto; sin enemigo se queda donde está.
	if data.turn_speed > 0:
		cannon.rotation = rotate_toward(cannon.rotation, _target_angle(target), deg_to_rad(data.turn_speed) * delta)
	else:
		cannon.rotation = _target_angle(target)
	if _pending_shot and _is_aimed(target):
		_pending_shot = false
		attack_timer.start()
		_shoot(target)

# El sprite del cañón mira hacia arriba: ángulo hacia el enemigo más 90°.
func _target_angle(target: Enemy) -> float:
	return (target.global_position - global_position).angle() + PI / 2

func _is_aimed(target: Enemy) -> bool:
	return data.cannon == null or absf(angle_difference(cannon.rotation, _target_angle(target))) <= AIM_TOLERANCE

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.erase(enemy)

func _on_attack_timeout() -> void:
	var target := _get_target()
	if target == null:
		return
	if _is_static():
		cannon.play(&"fire_0")
		return
	if _is_aimed(target):
		_shoot(target)
	else:
		# El cooldown no se gasta: dispara en cuanto el cañón quede alineado.
		_pending_shot = true
		attack_timer.stop()

# Torretas de onda o de rayo: el cañón no gira ni dispara balas.
func _is_static() -> bool:
	return data.pulse != null or data.chain != null

# La onda, el rayo o el haz salen en su frame de la animación de disparo.
func _on_cannon_frame_changed() -> void:
	var firing := cannon.animation == &"fire_0"
	if _sight:
		_sight.visible = firing and cannon.frame < data.beam.fire_frame
	if not firing:
		return
	if data.pulse and cannon.frame == data.pulse.fire_frame:
		Pulse.spawn(self)
	elif data.chain and cannon.frame == data.chain.fire_frame:
		var target := _get_target()
		if target:
			Chain.spawn(self, target)
	elif data.beam and cannon.frame == data.beam.fire_frame:
		Beam.spawn(self)

func _shoot(target: Enemy) -> void:
	if data.beam:
		# Empieza la carga; el haz sale después, hacia donde apunte el cañón en ese momento.
		cannon.play(&"fire_0")
		return
	var bullet: Bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	# La boca gira con el cañón (sin cañón, su rotación es 0 y no cambia nada).
	# Con dos cañones (muzzle_offset.x != 0) los disparos alternan de lado.
	var muzzle := data.muzzle_offset * Vector2(-1 if _shots % 2 else 1, 1)
	bullet.global_position = global_position + muzzle.rotated(cannon.rotation)
	bullet.setup(data.bullet_data, target)
	if data.muzzle_flash:
		Effect.spawn(cannon, data.muzzle_flash, bullet.global_position, data.bullet_data.sprite_scale)
	var fire_anims := data.cannon.get_animation_names().size() - 1 if data.cannon else 0
	if fire_anims > 0:
		cannon.play("fire_%d" % (_shots % fire_anims))
	_shots += 1

# Mantiene el objetivo mientras siga vivo y dentro del rango.
func _get_target() -> Enemy:
	if not is_instance_valid(_target) or not enemies_in_range.has(_target):
		_target = _best_enemy()
	return _target

func _best_enemy() -> Enemy:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	var best: Enemy = null
	var best_progress: float = -INF
	for enemy in enemies_in_range:
		if enemy.progress > best_progress:
			best_progress = enemy.progress
			best = enemy
	return best

func fit_to_tile(tile_size: Vector2) -> void:
	var frame_size: Vector2 = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_size()
	sprite.scale = tile_size / frame_size
