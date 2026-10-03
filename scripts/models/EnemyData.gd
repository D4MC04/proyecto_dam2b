extends Resource
class_name EnemyData

@export var name: String
@export var hp: int
@export var speed: int
@export var reward: int
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
@export var rotate_sprite: bool = false
# Giro extra en grados para sprites que no miran hacia arriba.
@export var rotation_offset: float = 0.0
