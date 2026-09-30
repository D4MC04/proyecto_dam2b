class_name Tower
extends Node2D

@export var data: TowerData
@export var bullet_scene: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area: Area2D = $RangeDetector
@onready var attack_range_shape: CollisionShape2D = $RangeDetector/CollisionShape2D
@onready var attack_timer: Timer = $Timer

var enemies_in_range: Array[Enemy] = []

func _ready() -> void:
	sprite.sprite_frames = data.sprite_frames
	attack_range_shape.shape = data.attack_range
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	attack_range_area.area_entered.connect(_on_area_entered)
	attack_range_area.area_exited.connect(_on_area_exited)
	attack_timer.start()

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy:
		enemies_in_range.erase(enemy)

func _on_attack_timeout() -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	_shoot(target)

func _shoot(target: Enemy) -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(data.bullet_data, target)

func _nearest_enemy() -> Enemy:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	var nearest: Enemy = null
	var best_dist: float = INF
	for enemy in enemies_in_range:
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			nearest = enemy
	return nearest

func fit_to_tile(tile_size: Vector2) -> void:
	var frame_size: Vector2 = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_size()
	sprite.scale = tile_size / frame_size
