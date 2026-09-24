extends PathFollow2D
class_name Enemy

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var data: EnemyData
var speed: float
var health: float

func setup(enemy_data: EnemyData):
	data = enemy_data
	speed = data.speed
	health = data.max_health
	anim.sprite_frames = data.sprite_frames
	anim.play("walk")

func _process(delta):
	progress += speed * delta

func take_damage(amount: float):
	health -= amount
	anim.play("hit")
	if health <= 0:
		die()

func die():
	anim.play("die")
	await anim.animation_finished
	queue_free()
