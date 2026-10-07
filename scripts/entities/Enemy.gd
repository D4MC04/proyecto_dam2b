extends PathFollow2D
class_name Enemy

signal died(reward: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var data: EnemyData
var speed: float
var hp: float
var _last_position: Vector2

# Los efectos que se pintan encima del enemigo son de 32 px; se escalan a su tamaño.
const EFFECT_SIZE := 32.0
const SLOW_FLASH := Color(3, 3, 3)
const SLOW_FLASH_TIME := 0.1
const SLOW_TINT := Color(0.65, 0.85, 1.0)

# Multiplicador de velocidad mientras está ralentizado.
var _slow := 1.0
var _slow_tween: Tween
var _frost: AnimatedSprite2D

signal reached_end

func setup(enemy_data: EnemyData):
	data = enemy_data
	speed = data.speed
	hp = data.hp
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	_last_position = global_position

func _process(delta):
	progress += speed * _slow * delta
	_update_animation()
	if progress_ratio >= 1.0:
		set_process(false)
		reached_end.emit()
		queue_free()

func _update_animation():
	var direction := global_position - _last_position
	_last_position = global_position
	if direction.length() < 0.01:
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("right" if direction.x > 0 else "left")
	else:
		sprite.play("down" if direction.y > 0 else "up")
	if data.rotate_sprite:
		# El sprite base mira hacia arriba; se gira en pasos de 90°.
		sprite.rotation = snappedf(direction.angle() + PI / 2, PI / 2) + deg_to_rad(data.rotation_offset)

func take_damage(amount: float):
	hp -= amount
	if hp <= 0:
		die()

# Ralentiza durante `duration` segundos con un destello y la escarcha encima.
# Si ya estaba ralentizado se renueva la duración, no se acumula.
func slow(factor: float, duration: float, frost_frames: SpriteFrames = null) -> void:
	_slow = factor
	if _frost == null and frost_frames:
		_frost = AnimatedSprite2D.new()
		_frost.sprite_frames = frost_frames
		_frost.scale = Vector2.ONE * effect_scale()
		add_child(_frost)
		_frost.play()
	if _slow_tween:
		_slow_tween.kill()
	_slow_tween = create_tween()
	_slow_tween.tween_property(sprite, "modulate", SLOW_TINT, SLOW_FLASH_TIME).from(SLOW_FLASH)
	_slow_tween.tween_interval(duration)
	_slow_tween.tween_callback(_end_slow)

func _end_slow() -> void:
	_slow = 1.0
	sprite.modulate = Color.WHITE
	if _frost:
		_frost.queue_free()
		_frost = null

func effect_scale() -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return 1.0
	var frame_size := texture.get_size() * sprite.scale
	return maxf(frame_size.x, frame_size.y) / EFFECT_SIZE

func die():
	died.emit(data.reward)
	queue_free()
