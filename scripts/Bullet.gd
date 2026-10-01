extends Area2D
class_name Bullet

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var data: BulletData
var target: Enemy
var direction: Vector2

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func setup(bullet_data: BulletData, new_target: Enemy) -> void:
	data = bullet_data
	target = new_target
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	sprite.play()
	var frame_width := sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_width()
	scale = Vector2.ONE * (8.0 / frame_width)
	_aim()

func _aim() -> void:
	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		_aim()
	global_position += direction * data.speed * delta

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemy.take_damage(data.damage)
		queue_free()
