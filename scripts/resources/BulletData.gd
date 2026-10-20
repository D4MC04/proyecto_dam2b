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
# Enemigos extra que atraviesa antes de desaparecer; 0 = se destruye al primer impacto.
@export var pierce: int = 0
# Radio (px) del daño en área al impactar; 0 = solo daña al enemigo golpeado.
@export var splash_radius: float = 0.0

## Filas de la ficha propias de la bala.
func get_stats() -> Array[StatEntry]:
	var stats: Array[StatEntry] = [
		StatEntry.new("damage", "DAÑO", UiFormat.number(damage)),
		StatEntry.new("speed", "VEL. BALA", UiFormat.number(speed)),
	]
	if pierce > 0:
		stats.append(StatEntry.new("pierce", "PERFORA", UiFormat.number(pierce)))
	if splash_radius > 0:
		stats.append(StatEntry.new("splash", "ÁREA", UiFormat.number(splash_radius)))
	return stats
