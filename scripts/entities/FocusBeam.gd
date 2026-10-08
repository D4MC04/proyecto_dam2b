extends Node2D
class_name FocusBeam
# Haz continuo de una torreta (va como hijo suyo): mientras el cañón apunta al objetivo lo daña
# cada frame, y sube de nivel cuanto más tiempo lleva sobre el mismo enemigo.
# El cañón anima "default" en reposo y "fire_0", "fire_1"... (en loop), una por nivel.

var _tower: Tower
var _data: FocusBeamData
var _locked: Enemy
var _lock_time := 0.0
var _time := 0.0
# Nivel actual; -1 = sin disparar.
var _level := -1
var _line := Line2D.new()
var _muzzle := AnimatedSprite2D.new()
var _impact := AnimatedSprite2D.new()

func _ready() -> void:
	_tower = get_parent()
	_data = _tower.data.focus_beam
	# Por encima de torretas y enemigos.
	z_index = 1
	_line.points = [Vector2.ZERO, Vector2.ZERO]
	Beam._set_texture(_line, _data.beam_textures[0])
	add_child(_line)
	add_child(_muzzle)
	# El impacto va sobre el enemigo, no sobre la torreta.
	_impact.top_level = true
	_impact.z_index = 1
	add_child(_impact)
	_show(false)
	_tower.cannon.play(&"default")

func _process(delta: float) -> void:
	var target := _tower._get_target()
	if target != _locked:
		_untint()
		_locked = target
		_lock_time = 0.0
	var firing := target != null and _tower._is_aimed(target)
	_show(firing)
	if not firing:
		# Sin alineación se corta el haz, pero el nivel se conserva mientras el objetivo sea el mismo.
		_untint()
		_set_level(-1)
		return
	_set_level(mini(int(_lock_time / _data.level_time), _data.damage_per_second.size() - 1))
	_lock_time += delta
	_time += delta
	var from := _tower.data.muzzle_offset.rotated(_tower.cannon.rotation)
	_muzzle.position = from
	_line.set_point_position(0, from)
	_line.set_point_position(1, to_local(target.global_position))
	_line.texture = _data.beam_textures[_level * _data.beam_frames + int(_time / _data.frame_time) % _data.beam_frames]
	_line.width = _line.texture.get_height()
	_impact.global_position = target.global_position
	_impact.scale = Vector2.ONE * target.effect_scale()
	target.sprite.modulate = target._rest_color().lerp(_data.tint, _data.tint_amount[_level])
	target.take_damage(_data.damage_per_second[_level] * delta)
	if target.hp <= 0:
		if _data.death_frames:
			Effect.spawn(_tower.get_parent(), _data.death_frames, target.global_position, target.effect_scale())
		_locked = null

func _show(firing: bool) -> void:
	visible = firing
	_impact.visible = firing

func _untint() -> void:
	if is_instance_valid(_locked):
		_locked.sprite.modulate = _locked._rest_color()

func _set_level(level: int) -> void:
	if level == _level:
		return
	_level = level
	if level < 0:
		_tower.cannon.play(&"default")
		return
	_tower.cannon.play("fire_%d" % level)
	_impact.sprite_frames = _data.impact_frames[level]
	_impact.play()
	_muzzle.sprite_frames = _data.muzzle_frames[level]
	_muzzle.play()
