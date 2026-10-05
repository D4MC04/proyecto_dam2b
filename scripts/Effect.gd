extends AnimatedSprite2D
class_name Effect
# Efecto de un solo uso: reproduce su animación (sin loop) y se borra solo al acabar.

static func spawn(parent: Node, frames: SpriteFrames, pos: Vector2, size: float = 1.0) -> void:
	var effect := Effect.new()
	effect.sprite_frames = frames
	effect.scale = Vector2.ONE * (size if size > 0 else 1.0)
	parent.add_child(effect)
	effect.global_position = pos
	effect.animation_finished.connect(effect.queue_free)
	effect.play()
