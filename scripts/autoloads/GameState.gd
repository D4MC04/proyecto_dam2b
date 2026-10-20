extends Node

# Autoload: progreso del jugador. Se carga al arrancar y se guarda al desbloquear un nivel.
const PATH := "user://progress.cfg"
const SECTION := "progress"

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1

func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		# El archivo lo puede editar cualquiera: solo se acepta un entero >= 1.
		var value: Variant = file.get_value(SECTION, "current_level", 1)
		if typeof(value) == TYPE_INT and value >= 1:
			current_level = value

# i es el índice (desde 0) del nivel en GameData.levels.
func is_unlocked(i: int) -> bool:
	return i < current_level

func is_completed(i: int) -> bool:
	return i < current_level - 1

# Se llama al ganar el nivel número `number` (desde 1): si era el más alto desbloqueado, abre el siguiente.
func complete_level(number: int) -> void:
	if number != current_level or number >= GameData.levels.size():
		return
	current_level += 1
	var file := ConfigFile.new()
	file.set_value(SECTION, "current_level", current_level)
	if file.save(PATH) != OK:
		push_warning("GameState: no se pudo guardar " + PATH)
