extends RefCounted
class_name RunStats
## Resumen de una derrota para su pantalla. Lo construye Level.get_run_stats().

## Oleada alcanzada, desde 1; 0 si no se lanzó ninguna.
var wave_reached: int
var wave_total: int
## Clave de traducción del nombre del último enemigo que llegó a la estación (vacío si no consta).
var killer_name: String = ""

func _init(reached: int, total: int, killer: String = "") -> void:
	wave_reached = reached
	wave_total = total
	killer_name = killer
