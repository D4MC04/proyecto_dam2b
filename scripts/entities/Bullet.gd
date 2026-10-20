extends Area2D
class_name Bullet

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var data: BulletData
var target: Enemy
var direction: Vector2
# Enemigos ya golpeados (con perforación no se daña dos veces al mismo).
var _hit: Array[Enemy] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func setup(bullet_data: BulletData, new_target: Enemy) -> void:
	data = bullet_data
	target = new_target
	sprite.sprite_frames = data.sprite_frames
	collision_shape.shape = data.collision_shape
	sprite.play()
	if data.sprite_scale > 0:
		# Solo el sprite: la colisión no crece con el efecto visual.
		sprite.scale = Vector2.ONE * data.sprite_scale
	else:
		var frame_width := sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_width()
		scale = Vector2.ONE * (8.0 / frame_width)
	sprite.rotation_degrees = data.rotation_offset
	if data.trail_frames:
		_add_trail()
	_aim()

# Estela pegada a la cola de la bala; como hija del sprite hereda su giro y su escala.
func _add_trail() -> void:
	var trail := AnimatedSprite2D.new()
	trail.sprite_frames = data.trail_frames
	trail.show_behind_parent = true
	var back := Vector2.LEFT.rotated(-sprite.rotation)
	var sizes := sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_size() \
			+ data.trail_frames.get_frame_texture(&"default", 0).get_size()
	trail.position = back * absf(back.dot(sizes)) / 2
	sprite.add_child(trail)
	trail.play()

func _aim() -> void:
	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		_aim()
	global_position += direction * data.speed * delta

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy and not _hit.has(enemy):
		_hit.append(enemy)
		if data.splash_radius > 0:
			# Daño en área: todos los enemigos cerca del impacto, incluido el golpeado.
			for node in get_tree().get_nodes_in_group(&"enemies"):
				var other := node as Enemy
				if other != null and other.global_position.distance_to(global_position) <= data.splash_radius:
					other.take_damage(data.damage)
		else:
			enemy.take_damage(data.damage)
		if data.impact_frames:
			Effect.spawn(get_parent(), data.impact_frames, global_position, data.sprite_scale)
		if _hit.size() > data.pierce:
			queue_free()
		else:
			# Atraviesa: deja de perseguir al objetivo y sigue recta.
			target = null
