class_name Enemy
extends Area2D

@export var max_health: float = -1.0
@export var flash_duration: float = 0.15

var current_health: float

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash(Color.RED)
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

func _flash(color: Color) -> void:
	var tween := create_tween()
	sprite.modulate = color
	tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)
