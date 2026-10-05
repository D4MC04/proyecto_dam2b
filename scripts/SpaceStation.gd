extends Sprite2D

const SHIELD := preload("res://assets/sprites/base/shield.png")
const SHIELD_WEAK := preload("res://assets/sprites/base/shield_debil.png")

@onready var shield: Sprite2D = $Shield

var _tween: Tween

# Parpadea 0,5 s con el escudo débil; con stay_weak se queda débil al terminar.
func hit(stay_weak: bool) -> void:
	if _tween:
		_tween.kill()
	shield.modulate.a = 1.0
	shield.texture = SHIELD_WEAK
	_tween = create_tween().set_loops(3)
	_tween.tween_property(shield, "modulate:a", 0.2, 0.5 / 6)
	_tween.tween_property(shield, "modulate:a", 1.0, 0.5 / 6)
	if not stay_weak:
		_tween.finished.connect(func(): shield.texture = SHIELD)
