extends PathFollow2D
class_name Enemy

signal died(reward: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var data: EnemyData
var speed: float
var hp: float
var _last_position: Vector2

signal reached_end

func setup(enemy_data: EnemyData):
	data = enemy_data
	speed = data.speed
	hp = data.hp
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	_last_position = global_position

func _process(delta):
	progress += speed * delta
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

func die():
	died.emit(data.reward)
	queue_free()
