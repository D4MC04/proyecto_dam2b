extends Resource
class_name ChainData
# Ataque en cadena: un rayo instantáneo que va de la torreta al objetivo y salta a los enemigos cercanos.

@export var damage: float
# Enemigos alcanzados en total, contando el primero.
@export var max_targets: int = 3
# Distancia máxima de cada salto, medida desde el último enemigo alcanzado.
@export var jump_range: float
# Variantes del rayo (se repiten a lo largo de la línea); se alternan durante bolt_time segundos.
@export var bolt_textures: Array[Texture2D]
@export var bolt_time: float = 0.15
# Animación (sin loop) sobre cada enemigo alcanzado.
@export var impact_frames: SpriteFrames
# Frame de la animación "fire_0" del cañón en el que sale el rayo.
@export var fire_frame: int = 0
