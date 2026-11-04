extends Resource
class_name AmpEffect
## Lo que gana una torreta cuando un Amplificador la tiene en su aura (ver Turret.amp_value).
## Cada torreta mejora su propia mecánica; `normal` es el valor con el Amplificador y `major`
## con el Amplificador mayor.

enum Kind {
	## Cañón doble: alcance × (1 + valor).
	RANGE,
	## Cañón pesado: área de explosión × (1 + valor).
	SPLASH,
	## Minigun: llega a la cadencia máxima con menos calor (el umbral se divide entre el valor).
	HEAT,
	## Cryo: la velocidad de los frenados se multiplica por (1 - valor), sin bajar de MIN_SLOW_FACTOR.
	SLOW,
	## Tesla: el rayo salta a `valor` enemigos más.
	TARGETS,
	## Rail: la carga (fire_0 hasta el fire_frame) va `valor` veces más rápida.
	CHARGE,
	## Disintegrator: el haz continuo sube de nivel `valor` veces más rápido.
	LEVEL_TIME,
	## Orbitador: las cargas giran `valor` veces más rápido.
	ORBIT_SPEED,
}

# El frenado amplificado nunca deja a un enemigo por debajo de esta parte de su velocidad.
const MIN_SLOW_FACTOR := 0.25

@export var kind: Kind
@export var normal: float
@export var major: float

## Valor del efecto con un Amplificador de nivel `level` (1 normal, 2 mayor).
func get_value(level: int) -> float:
	return major if level >= 2 else normal

## Fila de la ficha de una torreta amplificada: nombre del stat que mejora y cuánto.
func get_stat(level: int) -> StatEntry:
	var value := get_value(level)
	match kind:
		Kind.RANGE:
			return StatEntry.new("amp", "STAT_RANGE", _percent(value))
		Kind.SPLASH:
			return StatEntry.new("amp", "STAT_AREA", _percent(value))
		Kind.HEAT:
			return StatEntry.new("amp", "STAT_ACCEL", _times(value))
		Kind.SLOW:
			return StatEntry.new("amp", "STAT_SLOW", _percent(value))
		Kind.TARGETS:
			return StatEntry.new("amp", "STAT_TARGETS", "+" + UiFormat.number(value))
		Kind.CHARGE:
			return StatEntry.new("amp", "STAT_CHARGE", _times(value))
		Kind.LEVEL_TIME:
			return StatEntry.new("amp", "STAT_LEVEL_UP", _times(value))
		Kind.ORBIT_SPEED:
			return StatEntry.new("amp", "STAT_SPIN", _times(value))
	return StatEntry.new("amp", "STAT_AMP", "")

func _percent(value: float) -> String:
	return "+%d%%" % roundi(value * 100.0)

func _times(value: float) -> String:
	return "×" + UiFormat.number(value)
