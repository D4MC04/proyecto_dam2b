extends Resource
class_name EnemyData

@export var hp: float = 0.0
@export var speed: float = 0.0
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
@export var rotate_sprite: bool = false
# Giro extra en grados para sprites que no miran hacia arriba.
@export var rotation_offset: float = 0.0
