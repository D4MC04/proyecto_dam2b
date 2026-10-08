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
# Velocidad de giro del cañón en grados por segundo; 0 = apunta al instante.
@export var turn_speed: float = 0.0
# Opcional: con esto la torreta no dispara balas ni gira el cañón; lanza una onda en área en cada cooldown.
# El cañón anima "default" (reposo en loop) y "fire_0" (carga, pulso y enfriamiento, sin loop).
@export var pulse: PulseData
# Opcional: igual que pulse (cañón fijo, mismas animaciones), pero lanza un rayo en cadena al objetivo.
@export var chain: ChainData
# Opcional: el cañón gira y apunta como siempre, pero en vez de una bala reproduce "fire_0"
# (carga, disparo y recuperación) y lanza un haz que atraviesa a los enemigos de la línea.
@export var beam: BeamData
# Opcional: el cañón gira y apunta como siempre, pero en vez de balas mantiene un haz continuo
# sobre el objetivo que sube de nivel con el tiempo. No usa attack_cooldown.
@export var focus_beam: FocusBeamData
