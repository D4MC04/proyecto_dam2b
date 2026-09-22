class_name Tower
extends Node2D

@export var damage: float = -1.0
@export var attack_cooldown: float = -1.0
@export var range_radius: float = -1.0
@export var flash_duration: float = 0.15

var enemies_in_range: Array[Enemy] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var range_area: Area2D = $RangeDetector
@onready var range_shape: CollisionShape2D = $RangeDetector/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	(range_shape.shape as CircleShape2D).radius = range_radius
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		enemies_in_range.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area is Enemy:
		enemies_in_range.erase(area)

func _on_attack_timeout() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	if enemies_in_range.is_empty():
		return
	var target: Enemy = enemies_in_range[0]
	target.take_damage(damage)
	_flash(Color.GREEN)

func _flash(color: Color) -> void:
	var tween := create_tween()
	sprite.modulate = color
	tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)
