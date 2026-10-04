extends Resource
class_name TowerData

@export var name: String
@export var cost: int
@export var attack_cooldown: float
@export var icon: Texture2D
@export var sprite_frames: SpriteFrames
@export var attack_range: Shape2D
@export var bullet_data: BulletData
# Opcionales: destello (sin loop) al disparar y posición de la boca del cañón respecto al centro.
@export var muzzle_flash: SpriteFrames
@export var muzzle_offset: Vector2
# Opcional: cañón (mirando hacia arriba) que gira hacia el enemigo sobre la base fija de sprite_frames.
# "default" es el reposo; las animaciones "fire_0", "fire_1"... (sin loop) se alternan en cada disparo.
@export var cannon: SpriteFrames
