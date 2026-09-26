extends PathFollow2D
class_name Enemy

@onready var anim: AnimatedSprite2D = $Sprite

var data: EnemyData
var speed: float
var hp: float
var _last_position: Vector2

func setup(enemy_data: EnemyData):
	data = enemy_data
	speed = data.speed
	hp = data.hp
	anim.sprite_frames = data.sprite_frames
	$HurtBox/CollisionShape2D.shape = data.collision_shape
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
		anim.play("right" if direction.x > 0 else "left")
	else:
		anim.play("down" if direction.y > 0 else "up")

func take_damage(amount: float):
	hp -= amount
	if anim.sprite_frames.has_animation("hit"):
		anim.play("hit")
	if hp <= 0:
		die()

func die():
	set_process(false)
	$HurtBox.set_deferred("monitorable", false)
	if anim.sprite_frames.has_animation("die"):
		anim.play("die")
		await anim.animation_finished
	queue_free()
