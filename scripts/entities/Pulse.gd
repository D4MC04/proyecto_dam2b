extends AnimatedSprite2D
class_name Pulse
# Onda de un solo uso centrada en la torreta: cuando su borde pasa por un enemigo, lo daña y lo ralentiza.

var _tower: Tower
var _data: PulseData
var _last_radius := 0.0

static func spawn(tower: Tower) -> void:
	var pulse := Pulse.new()
	pulse._tower = tower
	pulse._data = tower.data.pulse
	pulse.sprite_frames = pulse._data.wave_frames
	tower.add_child(pulse)
	# Por debajo de la base y del cañón.
	tower.move_child(pulse, 0)
	pulse.frame_changed.connect(pulse._hit_ring)
	pulse.animation_finished.connect(pulse.queue_free)
	pulse.play()
	pulse._hit_ring()

# Alcanza a los enemigos que quedan entre el borde anterior y el actual.
func _hit_ring() -> void:
	var radius := _data.start_radius + _data.growth * frame
	for enemy in _tower.enemies_in_range.duplicate():
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= _last_radius or distance > radius:
			continue
		enemy.take_damage(_data.damage)
		if enemy.hp > 0:
			if _data.impact_frames:
				Effect.spawn(enemy, _data.impact_frames, enemy.global_position, enemy.effect_scale())
			enemy.slow(_data.slow_factor, _data.slow_time, _data.frost_frames)
	_last_radius = radius
