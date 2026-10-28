extends InspectableData
class_name TurretData

# Color de la ficha de todas las torretas (marco del icono y etiqueta de tipo).
const ACCENT_COLOR := Color("#40e0f0")

@export var name: String
@export var cost: int
@export var attack_cooldown: float
@export var icon: Texture2D
@export var sprite_frames: SpriteFrames
@export var attack_range: Shape2D
# Opcional: radio mínimo (px). Con más de 0 el alcance es un anillo entre este radio y el de attack_range:
# no elige objetivos más cerca y el rango se dibuja como anillo.
@export var min_range: float = 0.0
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
# Opcional: el emisor no gira ni apunta; en cada cooldown genera un proyectil que gira alrededor de la
# torreta, en el anillo de alcance, y explota al chocar con un enemigo. "fire_0" es la animación de generarlo.
@export var orbit: OrbitData
# Opcional (torretas de bala): sobrecalentamiento. Cada disparo seguido calienta la torreta y acorta el
# cooldown desde attack_cooldown hasta overheat_min_cooldown; al llegar a overheat_shots disparos se para
# overheat_time segundos y vuelve a la cadencia base. Sin objetivo se enfría del todo en overheat_cool_time s.
# Con overheat_shots = 0 (por defecto) no hay sobrecalentamiento.
@export var overheat_shots: int = 0
@export var overheat_min_cooldown: float = 0.0
@export var overheat_time: float = 0.0
@export var overheat_cool_time: float = 3.0
# Opcional (torretas de bala): tubos rotativos. El cañón reproduce en bucle su animación "spin" a una
# velocidad que sigue a la cadencia, y los tubos tienen que girar spin_up_time s antes de disparar.
# Sin objetivo, sobrecalentada o apagada por un EMP frena y tiene que volver a arrancar.
# Con spin_up_time = 0 (por defecto) no hay giro.
@export var spin_up_time: float = 0.0
# Opcional: sonido del disparo (en el bus SFX). En el haz continuo suena mientras el haz está activo.
@export var shoot_sound: AudioStream
# Opcional: sonido de carga de las torretas con animación fire_0; suena hasta el fire_frame.
@export var charge_sound: AudioStream
# Opcional: torreta en la que se convierte al fusionarla con otra igual; cost es lo que se paga por la fusión.
@export var fusion: TurretData
# Lo que gana la torreta dentro del aura de un Amplificador (cada torreta mejora su propia mecánica).
# Toda torreta que ataca debe tenerlo; las fusionadas usan el mismo que su base.
@export var amp_effect: AmpEffect
# Si es mayor que 0 la torreta es un Amplificador de ese nivel (1 normal, 2 mayor): no ataca y
# amplifica a las torretas que tengan el centro dentro de attack_range (su aura).
@export var amplifier_level: int = 0
# Opcional: frase corta que se enseña al final de la ficha.
@export_multiline var description: String

## Filas de la ficha: las comunes a todas las torretas y las de su tipo de ataque.
func get_stats() -> Array[StatEntry]:
	var stats: Array[StatEntry] = [StatEntry.new("cost", "COSTE", UiFormat.money(cost))]
	if is_amplifier():
		# Sin ataque ni cadencia: solo el radio del aura (lo que gana cada torreta sale en su ficha).
		var aura := attack_range as CircleShape2D
		if aura != null:
			stats.append(StatEntry.new("range", "AURA", UiFormat.number(aura.radius)))
		return stats
	var circle := attack_range as CircleShape2D
	if circle != null:
		var reach := UiFormat.number(circle.radius)
		if min_range > 0.0:
			reach = UiFormat.number(min_range) + "-" + reach
		stats.append(StatEntry.new("range", "ALCANCE", reach))
	# El haz continuo no usa el cooldown.
	if focus_beam == null:
		stats.append(StatEntry.new("cooldown", "CADENCIA", UiFormat.seconds(attack_cooldown)))
	if overheat_shots > 0:
		stats.append(StatEntry.new("cooldown", "CAD. MÁX", UiFormat.seconds(overheat_min_cooldown)))
		stats.append(StatEntry.new("targets", "AGUANTE", str(overheat_shots)))
		stats.append(StatEntry.new("duration", "PARADA", UiFormat.seconds(overheat_time)))
	var attack := get_attack()
	if attack != null:
		stats.append_array(attack.get_stats())
	return stats

## Datos del ataque de la torreta (BulletData, PulseData, ChainData, BeamData, FocusBeamData u
## OrbitData), o null.
func get_attack() -> Resource:
	if orbit != null:
		return orbit
	if focus_beam != null:
		return focus_beam
	if beam != null:
		return beam
	if chain != null:
		return chain
	if pulse != null:
		return pulse
	return bullet_data

## Torreta de apoyo: no ataca y amplifica a sus vecinas.
func is_amplifier() -> bool:
	return amplifier_level > 0

## Etiqueta corta del tipo de ataque para la ficha (9 caracteres como máximo).
func get_attack_label() -> String:
	if is_amplifier():
		return "APOYO"
	if orbit != null:
		return "ÓRBITA"
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
