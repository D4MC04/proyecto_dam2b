extends Sprite2D
class_name Base

signal health_changed(current: int, maximum: int)
signal destroyed

const SHIELD := preload("res://assets/sprites/base/shield.png")
const SHIELD_WEAK := preload("res://assets/sprites/base/shield_debil.png")
const WEAK_THRESHOLD := 0.5  # fracción de vida por debajo de la cual el escudo queda débil

@export var max_health: int = 100

var health: int

var _tween: Tween

@onready var shield: Sprite2D = $Shield

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		shield.hide()
		destroyed.emit()
		return
	_flash(float(health) / max_health <= WEAK_THRESHOLD)

# Parpadea 0,5 s con el escudo débil; con stay_weak se queda débil al terminar.
func _flash(stay_weak: bool) -> void:
	if _tween:
		_tween.kill()
	shield.modulate.a = 1.0
	shield.texture = SHIELD_WEAK
	_tween = create_tween().set_loops(3)
	_tween.tween_property(shield, "modulate:a", 0.2, 0.5 / 6)
	_tween.tween_property(shield, "modulate:a", 1.0, 0.5 / 6)
	if not stay_weak:
		_tween.finished.connect(func(): shield.texture = SHIELD)
