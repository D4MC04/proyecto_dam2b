extends InspectableData
class_name TowerData

# Color de la ficha de todas las torres (marco del icono y etiqueta de tipo).
const ACCENT_COLOR := Color("#40e0f0")

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
# Opcional: sonido del disparo (en el bus SFX). En el haz continuo suena mientras el haz está activo.
@export var shoot_sound: AudioStream
# Opcional: torre en la que se convierte al fusionarla con otra igual; cost es lo que se paga por la fusión.
@export var fusion: TowerData
# Opcional: frase corta que se enseña al final de la ficha.
@export_multiline var description: String

## Filas de la ficha: las comunes a todas las torres y las de su tipo de ataque.
func get_stats() -> Array[StatEntry]:
	var stats: Array[StatEntry] = [StatEntry.new("cost", "COSTE", UiFormat.money(cost))]
	var circle := attack_range as CircleShape2D
	if circle != null:
		stats.append(StatEntry.new("range", "ALCANCE", UiFormat.number(circle.radius)))
	# El haz continuo no usa el cooldown.
	if focus_beam == null:
		stats.append(StatEntry.new("cooldown", "CADENCIA", UiFormat.seconds(attack_cooldown)))
	var attack := get_attack()
	if attack != null:
		stats.append_array(attack.get_stats())
	return stats

## Datos del ataque de la torre (BulletData, PulseData, ChainData, BeamData o FocusBeamData), o null.
func get_attack() -> Resource:
	if focus_beam != null:
		return focus_beam
	if beam != null:
		return beam
	if chain != null:
		return chain
	if pulse != null:
		return pulse
	return bullet_data

## Etiqueta corta del tipo de ataque para la ficha (9 caracteres como máximo).
func get_attack_label() -> String:
	if focus_beam != null:
		return "HAZ CONT."
	if beam != null:
		return "HAZ"
	if chain != null:
		return "CADENA"
	if pulse != null:
		return "ONDA"
	if bullet_data != null:
		return "BALA"
	return ""

func get_inspect_icon() -> Texture2D:
	return icon

func get_inspect_name() -> String:
	return name

func get_inspect_tag() -> String:
	return get_attack_label()

func get_inspect_accent() -> Color:
	return ACCENT_COLOR

func get_inspect_description() -> String:
	return description
