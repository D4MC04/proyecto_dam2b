extends AnimatedSprite2D
class_name Base

signal health_changed(current: int, maximum: int)
signal destroyed

const SHIELD_WEAK := preload("res://assets/sprites/base/shield_debil.png")

@export var max_health: int = 100

var health: int

var _tween: Tween

@onready var shield: Sprite2D = $Shield

func _ready() -> void:
	health = max_health
	# El escudo solo se ve mientras parpadea, para no tapar la estación
	shield.modulate.a = 0.0

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		if _tween:
			_tween.kill()
		shield.hide()
		play("explosion")
		animation_finished.connect(func() -> void: play("destruida"), CONNECT_ONE_SHOT)
		destroyed.emit()
		return
	var phase: StringName = _phase_for(float(health) / max_health)
	if phase != animation:
		play(phase)
	_flash()

# Fase de daño según la fracción de vida que queda
func _phase_for(fraction: float) -> StringName:
	if fraction > 0.75:
		return &"fase_0"
	if fraction > 0.5:
		return &"fase_1"
	if fraction > 0.25:
		return &"fase_2"
	return &"fase_3"

# Parpadea 0,5 s con el escudo débil y vuelve a ocultarlo al terminar.
func _flash() -> void:
	if _tween:
		_tween.kill()
	shield.modulate.a = 1.0
	shield.texture = SHIELD_WEAK
	_tween = create_tween().set_loops(3)
	_tween.tween_property(shield, "modulate:a", 0.2, 0.5 / 6)
	_tween.tween_property(shield, "modulate:a", 1.0, 0.5 / 6)
	_tween.finished.connect(func() -> void: shield.modulate.a = 0.0)
