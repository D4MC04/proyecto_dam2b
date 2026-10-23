extends RefCounted
class_name RunStats
## Resumen de una partida para las pantallas de fin de nivel. Lo construye Level.get_run_stats().

## Oleada alcanzada, desde 1; 0 si no se lanzó ninguna.
var wave_reached: int
var wave_total: int
var enemies_destroyed: int
var money_spent: int
## Torreta con más bajas (vacío si ninguna ha matado).
var top_turret_name := ""
var top_turret_kills := 0

func _init(reached: int, total: int, destroyed: int, spent: int) -> void:
	wave_reached = reached
	wave_total = total
	enemies_destroyed = destroyed
	money_spent = spent
