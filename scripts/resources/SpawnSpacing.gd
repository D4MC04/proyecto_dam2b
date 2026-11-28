class_name SpawnSpacing
extends Resource
## Separación entre dos naves seguidas de un grupo según la velocidad de la nave: con la misma
## velocidad, la misma separación. Un único recurso: res://resources/spawn_spacing.tres.

## Segundos que se usan para una velocidad que no está en la tabla (y se avisa).
const DEFAULT_SPACING: float = 0.5

## Velocidad de la nave (EnemyData.speed, px/s) -> segundos entre dos naves del grupo.
@export var spacing_by_speed: Dictionary[int, float] = {}

## Velocidades ya avisadas, para no repetir el aviso en cada oleada.
static var _warned: Dictionary[int, bool] = {}


## Separación de una nave de esa velocidad.
func get_spacing(speed: int) -> float:
	if spacing_by_speed.has(speed):
		return spacing_by_speed[speed]
	if not _warned.has(speed):
		_warned[speed] = true
		push_warning("SpawnSpacing: la velocidad %d no está en spawn_spacing.tres; se usan %.1f s." % [speed, DEFAULT_SPACING])
	return DEFAULT_SPACING
