extends Resource
class_name PulseData
# Ataque en área: una onda centrada en la torreta que daña y ralentiza a los enemigos por los que pasa.

@export var damage: float
# Multiplicador de velocidad del enemigo (0.55 = va al 55 %) y segundos que dura.
@export var slow_factor: float = 1.0
@export var slow_time: float = 0.0
# Onda e impacto sin loop; la escarcha, en loop, se queda sobre el enemigo mientras dure la ralentización.
@export var wave_frames: SpriteFrames
@export var impact_frames: SpriteFrames
@export var frost_frames: SpriteFrames
# Radio del borde de la onda en cada frame: start_radius + growth * frame.
@export var start_radius: float
@export var growth: float
# Frame de la animación "fire_0" del cañón en el que nace la onda.
@export var fire_frame: int = 0
