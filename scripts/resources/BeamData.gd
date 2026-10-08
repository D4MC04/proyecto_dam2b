extends Resource
class_name BeamData
# Disparo de riel: tras la carga, un haz recto instantáneo que atraviesa a todos los enemigos de la línea.

@export var damage: float
# Distancia máxima del centro del enemigo a la línea para que le alcance.
@export var half_width: float
# Largo del haz y de la mira desde la boca del cañón; mayor que la pantalla = la cruza entera.
@export var length: float
# Frames del haz desvaneciéndose (se repiten a lo largo de la línea), uno cada frame_time segundos.
@export var beam_textures: Array[Texture2D]
@export var frame_time: float = 0.05
# Mira que se ve desde la boca del cañón durante la carga.
@export var sight_texture: Texture2D
# Animación (sin loop) que se deja en el sitio de cada enemigo alcanzado.
@export var impact_frames: SpriteFrames
# Frame de la animación "fire_0" del cañón en el que sale el haz; los anteriores son la carga.
@export var fire_frame: int = 0
