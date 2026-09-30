extends PathFollow2D
class_name Enemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var data: EnemyData
var speed: float
var hp: float
var _last_position: Vector2

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

func _update_animation():
	var direction := global_position - _last_position
	_last_position = global_position
	if direction.length() < 0.01:
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("right" if direction.x > 0 else "left")
	else:
		sprite.play("down" if direction.y > 0 else "up")

func take_damage(amount: float):
	hp -= amount
	if hp <= 0:
		die()

func die():
	queue_free()
