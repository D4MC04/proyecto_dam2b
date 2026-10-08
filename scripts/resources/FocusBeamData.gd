extends Resource
class_name FocusBeamData
# Haz continuo: mientras el cañón apunta al objetivo le hace daño sin parar, y sube de nivel
# cuanto más tiempo lleva sobre el mismo enemigo. Los arrays "por nivel" tienen un elemento por nivel.

# Daño por segundo de cada nivel; su tamaño es el número de niveles.
@export var damage_per_second: Array[float]
# Segundos sobre el mismo enemigo para subir un nivel; al cambiar de enemigo vuelve al primero.
@export var level_time: float
# Texturas del haz (se repiten a lo largo de la línea): beam_frames seguidas por cada nivel.
@export var beam_textures: Array[Texture2D]
@export var beam_frames: int = 4
@export var frame_time: float = 0.05
# Por nivel, en loop: impacto sobre el enemigo y brillo en la boca del cañón.
@export var impact_frames: Array[SpriteFrames]
@export var muzzle_frames: Array[SpriteFrames]
# Color hacia el que se tiñe el enemigo mientras recibe el haz, y cuánto (0-1) en cada nivel.
@export var tint: Color = Color.WHITE
@export var tint_amount: Array[float]
# Animación (sin loop) que queda en el sitio cuando el haz mata al enemigo.
@export var death_frames: SpriteFrames
