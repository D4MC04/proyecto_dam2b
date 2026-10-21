extends AnimatedSprite2D
class_name Base

signal health_changed(current: int, maximum: int)
signal destroyed

const SHIELD_WEAK := preload("res://assets/sprites/base/shield_debil.png")
const IMPACT_FRAMES := preload("res://resources/sprite_frames/rocket_launcher_impact.tres")
# Escala de la explosión según el daño de la nave: 5 -> 1,25 y 40 -> 2
const IMPACT_SCALE_PER_DAMAGE := 0.0214

@export var max_health: int = 100

var health: int

var _tween: Tween
var _hit_tween: Tween

@onready var shield: Sprite2D = $Shield

func _ready() -> void:
	health = max_health
	# El escudo solo se ve mientras parpadea, para no tapar la estación
	shield.modulate.a = 0.0

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	_impact(amount)
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
	_hit_flash()

# Explosión en el punto de choque, encima de la estación.
func _impact(amount: int) -> void:
	Effect.spawn(get_parent(), IMPACT_FRAMES, global_position, 1.0 + amount * IMPACT_SCALE_PER_DAMAGE)

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

# Destello rojo del sprite de la estación (~0,2 s) al recibir daño.
func _hit_flash() -> void:
	if _hit_tween:
		_hit_tween.kill()
	modulate = Color(1, 0.2, 0.2)
	_hit_tween = create_tween()
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
