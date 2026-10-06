extends Resource
class_name BulletData

@export var damage: float
@export var speed: float
@export var sprite_frames: SpriteFrames
@export var collision_shape: Shape2D
# Opcionales: sin configurar, la bala se comporta como siempre.
# Escala fija del sprite (entera, para no emborronar el pixel art); 0 = se ajusta a 8 px de ancho.
@export var sprite_scale: float = 0.0
# Giro extra en grados para sprites que no miran hacia la derecha.
@export var rotation_offset: float = 0.0
# Estela animada pegada a la cola de la bala.
@export var trail_frames: SpriteFrames
# Animación (sin loop) que se deja en el punto de impacto.
@export var impact_frames: SpriteFrames
